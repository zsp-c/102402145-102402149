import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/item_model.dart';

/// 后端接口地址。Spring Boot 默认 8080 端口。
/// 真机调试时需改为电脑局域网 IP（如 http://192.168.x.x:8080）。
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
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return ApiResponse<T>.fromJson(json, dataParser);
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