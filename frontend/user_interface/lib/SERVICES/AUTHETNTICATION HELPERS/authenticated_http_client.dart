import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';

class AuthenticatedHttpClient {
  final SecureStorageService _storageService;

  AuthenticatedHttpClient() : _storageService = SecureStorageService();

  final Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
  };

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storageService.getAccessToken();
    
    if (token == null) {
      return _baseHeaders;
    }

    final authHeaders = {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };
    
    return authHeaders;
  }

  Future<http.Response> get(Uri url) async {
    final headers = await _getAuthHeaders();
    
    try {
      final response = await http.get(url, headers: headers);
      return response;
    } catch (e) {
      rethrow; 
    }
  }

  Future<http.Response> post(Uri url, {Object? body}) async {
    final headers = await _getAuthHeaders();
    final bodyString = body != null ? json.encode(body) : null;

    try {
      final response = await http.post(
        url, 
        headers: headers, 
        body: bodyString,
      );
      return response;
    } catch (e) {
      rethrow; 
    }
  }
}