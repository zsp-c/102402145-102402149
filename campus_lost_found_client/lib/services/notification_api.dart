import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/item_model.dart';
import 'api_service.dart';

/// 消息模块接口客户端，对应 apifox_openapi.json 的「消息模块」六个接口：
///
/// | 方法 | 路径 | 说明 |
/// | POST   | /claims                | 发送认领联系 |
/// | GET    | /claims                | 认领消息列表（我收到的 + 我发出的） |
/// | GET    | /claims/unread-count   | 未读消息数 |
/// | PUT    | /claims/{claimId}/read | 标记单条已读 |
/// | PUT    | /claims/read-all       | 全部标记已读 |
/// | GET    | /claims/stream         | SSE 实时消息推送 |
///
/// 为什么单独一个文件、不并入 ApiService：这两个文件分属两人维护，
/// 消息模块的接口全部收在这里，合并代码时不会互相冲突；
/// 复用的只有 ApiConfig / ApiResponse / PageResult 这几个公共类型。
///
/// 接入页面时的用法（以消息页为例）：
/// ```dart
/// final me = AppData.currentUser.value.userId;
/// final resp = await NotificationApi.fetchNotifications(currentUserId: me);
/// final stream = NotificationStream(
///   currentUserId: me,
///   onMessage: (n) => setState(() => _items.insert(0, n)),
/// );
/// stream.connect();   // 页面 dispose 时调 stream.cancel()
/// ```
class NotificationApi {
  const NotificationApi._();

  /// 与 ApiService 保持一致的请求头：token 走 `token` 头，对齐后端配置。
  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (ApiConfig.token.isNotEmpty) {
      headers['token'] = ApiConfig.token;
    }
    return headers;
  }

  /// 统一响应解析，行为与 ApiService 对齐（空响应 / 非 JSON 都给可读的报错）。
  static ApiResponse<T> _parse<T>(String body, T Function(dynamic)? dataParser) {
    if (body.isEmpty) {
      throw Exception('服务器返回了空响应，请确认后端服务已启动');
    }
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw Exception('响应格式异常：$body');
      }
      return ApiResponse<T>.fromJson(json, dataParser);
    } on FormatException {
      throw Exception('服务器返回了非 JSON 响应，请确认后端服务正常运行');
    }
  }

  /// `POST /claims` —— 发送认领联系。
  ///
  /// 只传物品 id 和附言：接收者由后端按 item.userId 推导，发送者从 JWT 取，
  /// 前端传谁都不作数，避免伪造收件人。
  /// 成功返回刚发出的那条消息（结构同列表接口）。
  static Future<ApiResponse<NotificationModel>> sendClaim({
    required int itemId,
    required int currentUserId,
    String? content,
  }) async {
    final body = <String, dynamic>{'itemId': itemId};
    if (content != null && content.trim().isNotEmpty) {
      body['claimContent'] = content.trim();
    }
    final resp = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/claims'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _parse<NotificationModel>(
      resp.body,
      (d) => notificationFromJson(d as Map<String, dynamic>, currentUserId: currentUserId),
    );
  }

  /// `GET /claims` —— 认领消息列表，按时间倒序分页。
  static Future<ApiResponse<PageResult<NotificationModel>>> fetchNotifications({
    required int currentUserId,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/claims').replace(queryParameters: {
      'pageNum': pageNum.toString(),
      'pageSize': pageSize.toString(),
    });
    final resp = await http.get(uri, headers: _headers(json: false));
    return _parse<PageResult<NotificationModel>>(
      resp.body,
      (d) => PageResult.fromJson(
        d as Map<String, dynamic>,
        (m) => notificationFromJson(m, currentUserId: currentUserId),
      ),
    );
  }

  /// `GET /claims/unread-count` —— 未读消息数，供首页 / 消息页红点使用。
  static Future<ApiResponse<int>> fetchUnreadCount() async {
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/claims/unread-count'),
      headers: _headers(json: false),
    );
    return _parse<int>(resp.body, (d) => (d as num?)?.toInt() ?? 0);
  }

  /// `PUT /claims/{claimId}/read` —— 标记单条已读（只有收件人有权操作）。
  static Future<ApiResponse<void>> markRead(int claimId) async {
    final resp = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/claims/$claimId/read'),
      headers: _headers(),
      body: jsonEncode({}),
    );
    return _parse<void>(resp.body, null);
  }

  /// `PUT /claims/read-all` —— 把收到的消息全部标记已读。
  static Future<ApiResponse<void>> markAllRead() async {
    final resp = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/claims/read-all'),
      headers: _headers(),
      body: jsonEncode({}),
    );
    return _parse<void>(resp.body, null);
  }

  /// `DELETE /claims/read` —— 删除当前用户所有已读消息（收到的已读 + 发出的全部）。
  /// 返回删除的条数。
  static Future<ApiResponse<int>> deleteRead() async {
    final resp = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/claims/read'),
      headers: _headers(json: false),
    );
    return _parse<int>(resp.body, (d) => (d as num?)?.toInt() ?? 0);
  }

  /// `DELETE /claims/{claimId}` —— 删除单条消息。
  static Future<ApiResponse<void>> deleteOne(int claimId) async {
    final resp = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/claims/$claimId'),
      headers: _headers(json: false),
    );
    return _parse<void>(resp.body, null);
  }
}

/// SSE 实时消息连接。
///
/// 用 `package:http` 的流式响应自己解事件流，而不是引入额外的 sse 包：
/// 后端 SSE 要带 `token` 请求头（走 JWT 拦截器），浏览器原生 EventSource
/// 不支持自定义 header，所以这里用能控制 header 的 http.Client。
///
/// 断线自动重连：默认 3 秒后重试，直到 [cancel] 被调用。
/// 消息本身已入库，重连只是恢复「实时性」，不承担「不丢消息」的职责。
class NotificationStream {
  NotificationStream({
    required this.currentUserId,
    required this.onMessage,
    this.onConnected,
    this.onError,
    this.retryDelay = const Duration(seconds: 3),
  });

  /// 当前登录用户 id，用来判断消息方向（IN/OUT）。
  final int currentUserId;

  /// 收到一条新消息时回调。
  final void Function(NotificationModel message) onMessage;

  /// 连接建立时回调，可用于顺手拉一次未读数校准。
  final void Function()? onConnected;

  /// 出错或断线时回调（不影响自动重连）。
  final void Function(Object error)? onError;

  /// 重连间隔。
  final Duration retryDelay;

  http.Client? _client;
  StreamSubscription<String>? _lines;
  Timer? _retryTimer;
  bool _closed = false;

  /// 建立连接（幂等：重复调用只会有一路连接）。
  void connect() {
    if (_closed || _client != null) return;
    final client = http.Client();
    _client = client;

    final request = http.Request('GET', Uri.parse('${ApiConfig.baseUrl}/claims/stream'));
    if (ApiConfig.token.isNotEmpty) {
      request.headers['token'] = ApiConfig.token;
    }

    // SSE 是长连接，注意不要给这条请求设超时
    client.send(request).then((resp) {
      if (resp.statusCode != 200) {
        _handleDisconnect(Exception('SSE 连接失败：HTTP ${resp.statusCode}'));
        return;
      }
      onConnected?.call();
      final dataBuffer = StringBuffer();
      _lines = resp.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => _handleLine(line, dataBuffer),
            onError: (Object e) => _handleDisconnect(e),
            onDone: () => _handleDisconnect(null),
            cancelOnError: true,
          );
    }).catchError((Object e) {
      _handleDisconnect(e);
    });
  }

  /// 断开连接，不再重连。页面 dispose 时调用。
  void cancel() {
    _closed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _lines?.cancel();
    _lines = null;
    _client?.close();
    _client = null;
  }

  /// 解析一行 SSE 文本。事件以空行分隔，`data:` 是负载，`:` 开头是注释（心跳）。
  void _handleLine(String line, StringBuffer dataBuffer) {
    if (line.isEmpty) {
      final payload = dataBuffer.toString();
      dataBuffer.clear();
      if (payload.isNotEmpty) _dispatch(payload);
      return;
    }
    if (line.startsWith(':')) return; // 心跳注释帧，忽略
    if (line.startsWith('data:')) {
      dataBuffer.write(line.substring(5).trimLeft());
    }
    // event: / id: / retry: 本模块用不到，直接忽略
  }

  void _dispatch(String payload) {
    // 建连首帧，不是消息
    if (payload == 'connected') return;
    try {
      final json = jsonDecode(payload);
      if (json is Map<String, dynamic>) {
        onMessage(notificationFromJson(json, currentUserId: currentUserId));
      }
    } catch (e) {
      onError?.call(e);
    }
  }

  void _handleDisconnect(Object? error) {
    if (_closed) return;
    // onError 和 onDone 可能连续触发，用「是否还有连接」做去重
    if (_client == null && _lines == null) return;

    _lines?.cancel();
    _lines = null;
    _client?.close();
    _client = null;

    if (error != null) onError?.call(error);
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, connect);
  }
}

/// 把后端 `ClaimVo` 转成页面直接可用的 [NotificationModel]。
///
/// 方向判断：senderId == 当前登录用户 → 这条是我发出去的（OUT），
/// 否则就是我收到的（IN），「对方」信息相应取 receiver / sender。
///
/// 注意：后端返回的是完整 User 对象，所以 college / grade / studentId / phone
/// 都能直接展示（消息卡片上要显示对方的联系方式）。
NotificationModel notificationFromJson(
  Map<String, dynamic> json, {
  required int currentUserId,
}) {
  final senderId = (json['senderId'] as num?)?.toInt() ?? 0;
  final isIncoming = senderId != currentUserId;

  final peerRaw = isIncoming ? json['sender'] : json['receiver'];
  final peer = peerRaw is Map<String, dynamic> ? peerRaw : const <String, dynamic>{};

  return NotificationModel(
    id: (json['claimId'] as num?)?.toInt() ?? 0,
    type: json['msgType'] as String? ?? NotificationType.contact,
    direction: isIncoming ? NotificationDirection.incoming : NotificationDirection.outgoing,
    itemId: (json['itemId'] as num?)?.toInt() ?? 0,
    itemTitle: json['itemName'] as String? ?? '',
    peerNickname: peer['nickname'] as String? ?? '',
    peerCollege: peer['college'] as String? ?? '',
    peerGrade: peer['grade'] as String? ?? '',
    peerStudentId: peer['studentId'] as String? ?? '',
    peerPhone: peer['phone'] as String? ?? '',
    message: json['claimContent'] as String? ?? '',
    read: ((json['readStatus'] as num?)?.toInt() ?? 0) == 1,
    createdAt: json['createTime'] as String? ?? '',
  );
}