import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse {
  final bool ok;
  final String data;
  final String? error;
  final int? statusCode;
  ApiResponse.ok(this.data)
      : ok = true,
        error = null,
        statusCode = null;
  ApiResponse.error(this.error, {this.statusCode})
      : ok = false,
        data = '';
}

class ApiService {
  final String baseUrl;
  final String token;
  final http.Client _client = http.Client();

  ApiService(String baseUrl, this.token)
      : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  Future<ApiResponse> get(String path) async {
    try {
      final resp = await _client.get(
        Uri.parse('$baseUrl$path'),
        headers: {'X-Api-Token': token},
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse.error(_netMessage(e));
    }
  }

  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'X-Api-Token': token,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse.error(_netMessage(e));
    }
  }

  Future<ApiResponse> uploadAvatar(
      String deviceId, String familyId, List<int> jpeg) async {
    try {
      final uri = Uri.parse('$baseUrl/api/avatar/upload');
      final req = http.MultipartRequest('POST', uri)
        ..headers['X-Api-Token'] = token
        ..fields['deviceId'] = deviceId
        ..fields['familyId'] = familyId
        ..files.add(
            http.MultipartFile.fromBytes('file', jpeg, filename: 'avatar.jpg'));
      final resp = await req.send().timeout(const Duration(seconds: 30));
      final body = await http.Response.fromStream(resp)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(body);
    } catch (e) {
      return ApiResponse.error(_netMessage(e));
    }
  }

  ApiResponse _handleResponse(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return ApiResponse.ok(resp.body);
    }
    return ApiResponse.error('HTTP ${resp.statusCode}',
        statusCode: resp.statusCode);
  }

  String _netMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('UnknownHostException') ||
        msg.contains('connect') ||
        msg.contains('timeout')) {
      return '无法连接服务器';
    }
    return msg;
  }

  void close() => _client.close();
}
