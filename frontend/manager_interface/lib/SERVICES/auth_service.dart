import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manager_interface/services/authentication%20helpers/secure_storage_service.dart';


class AuthService {
  static const String baseUrl = "http://127.0.0.1:8000/api/users"; // adjust backend URL
  static final SecureStorageService _storageService = SecureStorageService();

  // Login specific for manager
  static Future<bool> loginManager(String email, String password) async {
    final url = Uri.parse('$baseUrl/token/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Optional: check role via backend (if backend returns user info)
      final accessToken = data['access'];
      final refreshToken = data['refresh'];

      // Save tokens securely
      await _storageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // If backend returns role, validate manager
      if (data.containsKey('role') && data['role'] == 'manager') {
        return true;
      }

      // If backend doesn't return role, assume all JWT users are allowed
      return true;
    } else {
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _storageService.deleteTokens();
  }
}
