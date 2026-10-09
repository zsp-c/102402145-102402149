import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/notification_api.dart';
import '../utils/toast_util.dart';

/// 消息通知页，对应接口文档「消息模块」的 `GET /claims`（认领消息列表）。
/// 由首页右上角铃铛进入；「联系 TA」发出的联系申请也会出现在这里。
///
/// 列表以服务端为准（`claim` 表是事实来源），`GET /claims/stream` 只负责
/// 把新消息实时推过来；推送断了也不丢数据，重新进入页面拉一次即可补齐。
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  /// 消息列表：收发合一，按时间倒序。
  List<NotificationModel> _items = [];

  /// 当前登录用户 id，用来判定消息方向（IN / OUT）。
  int get _currentUserId => AppData.currentUser.value.userId;

  bool _loading = true;
  String? _error;

  /// 未读数，供「全部已读」与页面内计数使用。
  int _unread = 0;

  /// SSE 实时推送连接，页面销毁时断开。
  NotificationStream? _stream;

  @override
  void initState() {
    super.initState();
    _load();
    _connectStream();
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  /// 拉取消息列表与未读数。
  Future<void> _load() async {
    try {
      final resp = await NotificationApi.fetchNotifications(
        currentUserId: _currentUserId,
        pageSize: 50,
      );
      if (!resp.success) {
        if (mounted) {
          setState(() {
            _error = resp.msg.isEmpty ? '加载失败' : resp.msg;
            _loading = false;
          });
        }
        return;
      }
      final records = resp.data?.records ?? <NotificationModel>[];
      final unread = await NotificationApi.fetchUnreadCount();
      if (mounted) {
        setState(() {
          _items = records;
          // 后端拿不到时按列表里的未读条数兜底。
          _unread = unread.success ? (unread.data ?? 0) : records.where((e) => !e.read).length;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// 建立 SSE 连接：收到新消息直接插到列表顶部。
  void _connectStream() {
    _stream = NotificationStream(
      currentUserId: _currentUserId,
      onMessage: (n) {
        if (!mounted) return;
        // 同一条消息可能既被推送又出现在列表刷新里，按 id 去重。
        if (_items.any((e) => e.id == n.id)) return;
        setState(() {
          _items.insert(0, n);
          if (!n.read) _unread++;
        });
      },
    )..connect();
  }

  /// 点击一条消息：收到的消息调后端标记已读；自己发出的不处理
  /// （后端只允许收件人变更已读状态，本地改只会和后端不一致）。
  Future<void> _onTapMessage(NotificationModel n) async {
    if (!n.isIncoming || n.read) return;
    setState(() {
      n.read = true;
      if (_unread > 0) _unread--;
    });
    try {
      await NotificationApi.markRead(n.id);
    } catch (_) {
      // 失败不打扰用户：本地已是已读观感，下次进页面以后端为准。
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const Spacer(),
            const Text('消息通知'),
            const Spacer(),
            GestureDetector(
              onTap: _markAllRead,
              child: const Text('全部已读',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A2E)))
          : _error != null && items.isEmpty
              ? _buildErrorView()
              : items.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildDismissible(items[index], index),
                    ),
    );
  }

  /// 左滑删除。未读 / 已读删除后给出不同提示。
  Widget _buildDismissible(NotificationModel n, int index) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE54D42),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除通知', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            content: Text('确定删除这条${n.read ? '已读' : '未读'}消息吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消', style: TextStyle(color: Color(0xFF6B7280))),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('删除', style: TextStyle(color: Color(0xFFE54D42))),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) {
        setState(() {
          _items.removeAt(index);
          if (n.isIncoming && !n.read && _unread > 0) _unread--;
        });
        // 接口文档没有提供消息删除接口，这里只从本地列表移除，服务端记录仍在。
        ToastUtil.success(context, n.read ? '已删除' : '已删除一条未读消息');
      },
      child: _buildCard(n),
    );
  }

  /// `PUT /claims/read-all` —— 把收到的消息全部标记已读。
  /// 未读数按「我收到的且未读」统计，与后端 unread-count 口径一致。
  Future<void> _markAllRead() async {
    final unread = _items.where((e) => e.isIncoming && !e.read).length;
    if (unread == 0) {
      ToastUtil.info(context, '没有未读消息');
      return;
    }
    setState(() {
      for (final n in _items) {
        if (n.isIncoming) n.read = true;
      }
      _unread = 0;
    });
    try {
      final resp = await NotificationApi.markAllRead();
      if (!mounted) return;
      if (!resp.success) {
        ToastUtil.info(context, resp.msg.isEmpty ? '操作失败' : resp.msg);
        _load();
        return;
      }
      ToastUtil.success(context, '已将 $unread 条消息标记为已读');
    } catch (_) {
      if (mounted) ToastUtil.info(context, '网络异常，已读状态未能同步到服务器');
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('暂无消息', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  /// 列表加载失败（后端未启动 / token 失效）时的重试视图。
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 52, color: Color(0xFFFF7A2E)),
          const SizedBox(height: 10),
          Text(_error ?? '加载失败', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('重试',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(NotificationModel n) {
    final isSystem = n.type == NotificationType.system;
    return GestureDetector(
      onTap: () => _onTapMessage(n),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // 未读用左侧色条标记。
          border: Border(
            left: BorderSide(
              color: n.read ? Colors.transparent : const Color(0xFFFF7A2E),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSystem ? const Color(0xFFF3F4F6) : const Color(0xFFFFF1E8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isSystem
                      ? const Icon(Icons.campaign_outlined, color: Color(0xFF9CA3AF), size: 20)
                      : Text(n.peerAvatarText,
                          style: const TextStyle(
                              color: Color(0xFFFF7A2E), fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(n.peerNickname,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSystem ? const Color(0xFFF3F4F6) : const Color(0xFFE8F8F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(n.isIncoming ? n.typeLabel : '我发出的',
                                style: TextStyle(
                                  color: isSystem ? const Color(0xFF6B7280) : const Color(0xFF2DB8A3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ),
                      if (!isSystem && n.peerCollege.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('${n.peerCollege} · ${n.peerGrade} · 学号 ${n.peerStudentId}',
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        if (n.peerPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Color(0xFF9CA3AF), size: 12),
                              const SizedBox(width: 4),
                              Text(n.peerPhone,
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Text(n.createdAt, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(n.message,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFF9CA3AF), size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(n.itemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}