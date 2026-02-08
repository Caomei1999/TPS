import 'dart:convert';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/SERVICES/CONFIG/api.dart';

const String _baseUrl = Api.users;


class UserService {
  final AuthenticatedHttpClient _httpClient;
  final SecureStorageService _storageService;

  UserService() : _httpClient = AuthenticatedHttpClient(), _storageService = SecureStorageService();

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final url = Uri.parse('$_baseUrl/profile/');
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _storageService.deleteTokens();
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/change-password/');
    try {
      final response = await _httpClient.put(
        url,
        body: {'old_password': oldPassword, 'new_password': newPassword},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    final url = Uri.parse('$_baseUrl/delete/');
    try {
      final response = await _httpClient.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _storageService.deleteTokens();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final url = Uri.parse('$_baseUrl/profile/');
    try {
      final response = await _httpClient.patch(
        url,
        body: {'first_name': firstName, 'last_name': lastName},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
