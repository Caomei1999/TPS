import 'dart:convert';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart'; 
class ViolationService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  static const String _baseUrl = 'http://10.0.2.2:8000/api/users'; 

  Future<List<dynamic>> fetchMyFines() async {
    final url = Uri.parse('$_baseUrl/me/fines/');
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error fetching fines: $e");
      return [];
    }
  }

  Future<bool> payFine(int fineId) async {
    final url = Uri.parse('$_baseUrl/fines/$fineId/pay/');
    try {
      final response = await _httpClient.post(url);
      return response.statusCode == 200;
    } catch (e) {
      print("Error paying fine: $e");
      return false;
    }
  }

  Future<bool> contestFine(int fineId, String reason) async {
    final url = Uri.parse('$_baseUrl/fines/$fineId/contest/');
    try {
      final response = await _httpClient.post(
        url, 
        body: {'reason': reason}
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error contesting fine: $e");
      return false;
    }
  }
}