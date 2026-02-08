import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_interface/SERVICES/CONFIG/api.dart';

const String _baseUrl = Api.users;

class AuthService {
  Future<Map<String, dynamic>?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'password2': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final Map<String, dynamic> body = json.decode(response.body);
          if (body.containsKey('detail')) {
            throw Exception(body['detail']);
          }
        } catch (e) {
          if (e.toString().startsWith("Exception:")) rethrow;
        }

        throw Exception('Login failed. Check your credentials.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    final url = Uri.parse('$_baseUrl/password-reset-request/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final url = Uri.parse('$_baseUrl/password-reset-confirm/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'token': code,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
