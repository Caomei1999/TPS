import 'dart:convert';
import 'package:officer_interface/services/authentication%20helpers/authenticated%20_http_client.dart';

class ControllerService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  static const String _apiRoot = 'http://127.0.0.1:8000/api';
  // static const String _apiRoot = 'http://10.0.2.2:8000/api';

  // Calls: api/sessions/search_by_plate/?plate=XXXXXX
  static Future<Map<String, dynamic>?> searchActiveSessionByPlate(
    String plate,
  ) async {
    final url = Uri.parse('$_apiRoot/sessions/search_by_plate/?plate=$plate');

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        // ✅ 核心修改：直接返回解码后的 JSON 字典 (包含 status, session_data 等)
        // 不要在这里调用 ParkingSession.fromJson，交给 UI 层去处理
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception(
          'Permission denied: You are not authorized for this city.',
        );
      } else if (response.statusCode == 404) {
        return {'status': 'not_found'};
      } else {
        // 其他错误 (如 404, 500)
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<int> reportViolation(String plate) async {
    final url = Uri.parse('$_apiRoot/users/violations/report/');
    try {
      final response = await _httpClient.post(
        url,
        // body: {'plate': plate}, // 记得用我们之前修好的写法
        body: {'plate': plate},
      );

      // 直接返回状态码，交给 UI 去判断显示什么提示
      return response.statusCode;
    } catch (e) {
      print('Report error: $e');
      return 500; // 网络错误或其他异常
    }
  }
}
