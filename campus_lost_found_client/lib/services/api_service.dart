import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/item_model.dart';

/// 后端接口地址。Spring Boot 默认 8080 端口。
/// 真机调试时需改为电脑局域网 IP（如 http://192.168.x.x:8080）。
/// 'http://10.0.2.2:8080'
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080';

  /// 当前登录用户的 JWT token，登录成功后写入。
  static String token = '';

  /// 是否已登录。
  static bool get isLoggedIn => token.isNotEmpty;

  // ---- 测试用默认账号（对接后端后可删除）----
  static const String defaultStudentId = '00000';
  static const String defaultPassword = '123456';
}

/// 统一响应结构，对齐后端 com.zsp.campus.result.ApiResponse。
/// code == 1 表示成功，data 为业务数据；code == 0 表示失败，msg 为错误信息。
class ApiResponse<T> {
  final int code;
  final String msg;
  final T? data;

  ApiResponse({required this.code, required this.msg, this.data});

  bool get success => code == 1;

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? dataParser) {
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? 0,
      msg: json['msg'] as String? ?? '',
      data: json['data'] == null ? null : (dataParser != null ? dataParser(json['data']) : json['data'] as T?),
    );
  }
}

/// 网络请求服务。所有需要鉴权的请求都会自动带上 `token` 请求头，
/// 与后端 application.yaml 中 `campus.jwt.user-token-name: token` 对齐。
class ApiService {
  /// 构造带鉴权的请求头。
  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (ApiConfig.token.isNotEmpty) {
      headers['token'] = ApiConfig.token;
    }
    return headers;
  }

  /// 发送一个 JSON POST 请求并解析统一响应。
  static Future<ApiResponse<T>> _postJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic)? dataParser,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _parseResponse<T>(resp.body, dataParser);
  }

  /// 发送一个 JSON PUT 请求并解析统一响应。
  static Future<ApiResponse<T>> _putJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic)? dataParser,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final resp = await http.put(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _parseResponse<T>(resp.body, dataParser);
  }

  /// 发送一个 GET 请求并解析统一响应。
  static Future<ApiResponse<T>> _get<T>(
    String path,
    T Function(dynamic)? dataParser,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final resp = await http.get(uri, headers: _headers());
    return _parseResponse<T>(resp.body, dataParser);
  }

  /// 安全解析后端响应。
  /// - 若响应体为空或非 JSON，抛出可读的异常；
  /// - 若响应结构符合 ApiResponse，正常解析。
  static ApiResponse<T> _parseResponse<T>(
    String body,
    T Function(dynamic)? dataParser,
  ) {
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

  /// `POST /login` —— 用户登录。
  /// 请求体 LoginDto: {studentId, password}
  /// 成功返回 LoginVo: {token, user}
  static Future<ApiResponse<LoginVo>> login(String studentId, String password) async {
    return _postJson<LoginVo>(
      '/login',
      {'studentId': studentId, 'password': password},
      (d) => LoginVo.fromJson(d as Map<String, dynamic>),
    );
  }

  /// `POST /auth/register` —— 用户注册。
  /// 请求体 RegisterDto: {studentId, password, nickname, college, grade, phone, avatar?}
  /// 注意：后端拦截器当前仅排除了 /login，若注册时返回 401，
  /// 需在后端 webMvcConfiguration 的 excludePathPatterns 中补充 "/auth/register"。
  static Future<ApiResponse<void>> register({
    required String studentId,
    required String password,
    required String nickname,
    required String college,
    required String grade,
    required String phone,
    String? avatar,
  }) async {
    final body = <String, dynamic>{
      'studentId': studentId,
      'password': password,
      'nickname': nickname,
      'college': college,
      'grade': grade,
      'phone': phone,
    };
    if (avatar != null && avatar.isNotEmpty) body['avatar'] = avatar;
    return _postJson<void>('/auth/register', body, null);
  }

  /// `GET /users/me` —— 获取当前登录用户资料。
  static Future<ApiResponse<UserModel>> getCurrentUser() async {
    return _get<UserModel>(
      '/users/me',
      (d) => UserModel.fromJson(d as Map<String, dynamic>),
    );
  }

  /// `GET /users/{userId}` —— 获取指定用户资料。
  /// 详情页点发布者看「学生详情」时用，替代原先写死的 mock 用户。
  static Future<ApiResponse<UserModel>> getUserById(int userId) async {
    return _get<UserModel>(
      '/users/$userId',
      (d) => UserModel.fromJson(d as Map<String, dynamic>),
    );
  }

  /// `PUT /users/me` —— 修改当前用户资料。
  /// 可修改字段：nickname, avatar, phone, college, grade
  static Future<ApiResponse<UserModel>> updateUser({
    String? nickname,
    String? avatar,
    String? phone,
    String? college,
    String? grade,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;
    if (phone != null) body['phone'] = phone;
    if (college != null) body['college'] = college;
    if (grade != null) body['grade'] = grade;
    return _putJson<UserModel>(
      '/users/me',
      body,
      (d) => UserModel.fromJson(d as Map<String, dynamic>),
    );
  }

  /// 上传单张图片到阿里云 OSS，返回图片访问 URL。
  /// 流程：本地选图 → POST /upload/image (multipart/form-data, field=file)
  ///      → 后端调用 AliOssUtil.upload 上传至 OSS → 返回图片访问 URL
  ///      → 前端将 URL 放入 ItemDto.images 后再发布信息。
  static Future<String> uploadImage(String filePath) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/upload/image');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_headers(json: false));

    final file = await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(file);

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('上传失败：HTTP ${streamed.statusCode}');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final resp = ApiResponse<String>.fromJson(json, (d) => d as String);

    if (!resp.success) {
      throw Exception(resp.msg.isEmpty ? '上传失败' : resp.msg);
    }
    if (resp.data == null || resp.data!.isEmpty) {
      throw Exception('上传失败：未返回图片地址');
    }
    return resp.data!;
  }

  // ============================================================
  //  物品模块
  // ============================================================

  /// `GET /items` —— 获取最新信息列表（首页）。
  /// 参数：type(LOST/FOUND), categoryId, pageNum, pageSize。
  static Future<ApiResponse<PageResult<ItemModel>>> getItems({
    String? type,
    int? categoryId,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'pageNum': pageNum.toString(),
      'pageSize': pageSize.toString(),
    };
    if (type != null) params['type'] = type;
    if (categoryId != null) params['categoryId'] = categoryId.toString();
    final uri = Uri.parse('${ApiConfig.baseUrl}/items').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers());
    return _parseResponse<PageResult<ItemModel>>(
      resp.body,
      (d) => PageResult.fromJson(d as Map<String, dynamic>, ItemModel.fromJson),
    );
  }

  /// `GET /items/{id}` —— 获取物品详情。
  static Future<ApiResponse<ItemModel>> getItemDetail(int id) async {
    return _get<ItemModel>(
      '/items/$id',
      (d) => ItemModel.fromJson(d as Map<String, dynamic>),
    );
  }

  /// `POST /items` —— 发布失物/招领信息，返回新信息的 itemId。
  static Future<ApiResponse<int>> createItem({
    required String type,
    required String name,
    required String category,
    required String description,
    required String location,
    required String findOrLostTime,
    List<String> images = const [],
  }) async {
    return _postJson<int>(
      '/items',
      {
        'type': type,
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'findOrLostTime': findOrLostTime,
        'images': images,
      },
      (d) {
        final map = d as Map<String, dynamic>;
        return (map['itemId'] as num?)?.toInt() ?? 0;
      },
    );
  }

  /// `DELETE /items/{id}` —— 删除信息（只能删除自己发布的，已解决不可删除）。
  static Future<ApiResponse<void>> deleteItem(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/$id');
    final resp = await http.delete(uri, headers: _headers());
    return _parseResponse<void>(resp.body, null);
  }

  /// `PUT /items/{id}/resolve` —— 标记已解决（已找回/已归还）。
  static Future<ApiResponse<void>> resolveItem(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/$id/resolve');
    final resp = await http.put(uri, headers: _headers(), body: jsonEncode({}));
    return _parseResponse<void>(resp.body, null);
  }

  /// `PUT /items/{id}` —— 修改已发布信息（只能修改自己发布的）。
  static Future<ApiResponse<ItemModel>> updateItem({
    required int id,
    required String type,
    required String name,
    required String category,
    required String description,
    required String location,
    required String findOrLostTime,
    List<String> images = const [],
  }) async {
    return _putJson<ItemModel>(
      '/items/$id',
      {
        'type': type,
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'findOrLostTime': findOrLostTime,
        'images': images,
      },
      (d) => ItemModel.fromJson(d as Map<String, dynamic>),
    );
  }

  /// `GET /items/search` —— 搜索信息。
  static Future<ApiResponse<PageResult<ItemModel>>> searchItems({
    required String keyword,
    String? type,
    int? categoryId,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'keyword': keyword,
      'pageNum': pageNum.toString(),
      'pageSize': pageSize.toString(),
    };
    if (type != null) params['type'] = type;
    if (categoryId != null) params['categoryId'] = categoryId.toString();
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/search').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers());
    return _parseResponse<PageResult<ItemModel>>(
      resp.body,
      (d) => PageResult.fromJson(d as Map<String, dynamic>, ItemModel.fromJson),
    );
  }

  /// `GET /items/my` —— 获取我的发布列表。
  static Future<ApiResponse<PageResult<ItemModel>>> getMyItems({
    String? type,
    String? status,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'pageNum': pageNum.toString(),
      'pageSize': pageSize.toString(),
    };
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/my').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers());
    return _parseResponse<PageResult<ItemModel>>(
      resp.body,
      (d) => PageResult.fromJson(d as Map<String, dynamic>, ItemModel.fromJson),
    );
  }

  /// `GET /categories` —— 获取所有物品分类。
  static Future<ApiResponse<List<String>>> getCategories() async {
    return _get<List<String>>(
      '/categories',
      (d) => (d as List).map((e) => e.toString()).toList(),
    );
  }
}

/// 分页数据结构，对应后端 PageResult。
class PageResult<T> {
  final List<T> records;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;

  PageResult({
    required this.records,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
  });

  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) recordParser) {
    final recordsJson = json['records'] as List? ?? [];
    return PageResult<T>(
      records: recordsJson.map((e) => recordParser(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      pageNum: (json['pageNum'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 登录返回值，对应后端 com.zsp.campus.vo.LoginVo。
class LoginVo {
  final String token;
  final UserModel user;

  LoginVo({required this.token, required this.user});

  factory LoginVo.fromJson(Map<String, dynamic> json) {
    return LoginVo(
      token: json['token'] as String? ?? '',
      user: UserModel.fromJson((json['user'] as Map<String, dynamic>?) ?? {}),
    );
  }
}