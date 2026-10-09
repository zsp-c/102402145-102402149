import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// 搜索模块接口客户端（`/search/history`）。
///
/// 单独成一个文件，避免改动同学写好的 `api_service.dart`；
/// 统一响应的解析复用 `api_service.dart` 里的 `ApiResponse`，
/// 请求头与 `ApiConfig`（baseUrl / token）保持同一套约定。
class SearchHistoryApi {
  /// 构造带鉴权的请求头，与 api_service.dart 中的约定一致。
  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (ApiConfig.token.isNotEmpty) {
      headers['token'] = ApiConfig.token;
    }
    return headers;
  }

  /// 安全解析后端响应，逻辑与 api_service.dart 的 _parseResponse 对齐。
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

  /// `GET /search/history` —— 获取我的搜索历史（按时间倒序）。
  /// 返回 data 为关键词字符串数组，例如 ["学生证", "操场", "充电线"]。
  static Future<ApiResponse<List<String>>> fetchHistory({int limit = 10}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/search/history?limit=$limit');
    final resp = await http.get(uri, headers: _headers(json: false));
    return _parse<List<String>>(
      resp.body,
      (d) => (d as List).map((e) => e.toString()).toList(),
    );
  }

  /// `POST /search/history` —— 记录一次搜索关键词。
  /// 接口文档未列出该 POST，但「历史从哪来」需要入口，搜索成功后调用即可。
  static Future<ApiResponse<void>> recordHistory(String keyword) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/search/history');
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'keyword': keyword}),
    );
    return _parse<void>(resp.body, null);
  }

  /// `DELETE /search/history` —— 清除我的全部搜索历史。
  static Future<ApiResponse<void>> clearHistory() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/search/history');
    final resp = await http.delete(uri, headers: _headers(json: false));
    return _parse<void>(resp.body, null);
  }
}
