import 'dart:convert';
import 'dart:developer' as developer;
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';
import 'package:user_interface/SERVICES/CONFIG/api.dart'; 

class ViolationService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  static const String _baseUrl = Api.users; 

  Future<List<dynamic>> fetchMyFines() async {
    final url = Uri.parse('$_baseUrl/me/fines/');
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
        developer.log("Error fetching fines: $e");
      return [];
    }
  }

  Future<bool> payFine(int fineId) async {
    final url = Uri.parse('$_baseUrl/fines/$fineId/pay/');
    try {
      final response = await _httpClient.post(url);
      return response.statusCode == 200;
    } catch (e) {
        developer.log("Error paying fine: $e");
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
        developer.log("Error contesting fine: $e");
      return false;
    }
  }
}