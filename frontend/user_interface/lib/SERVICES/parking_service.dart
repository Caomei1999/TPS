import 'dart:convert';
import 'package:user_interface/services/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';


const String _baseUrl = 'http://127.0.0.1:8000/api/parkings'; 

class ParkingApiService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<Map<String, dynamic>?> registerVehicle({
    required String name,
    required String plate,
  }) async {
    final url = Uri.parse('$_baseUrl/vehicles/');
    
    final body = {
      'name': name,
      'plate': plate,
    };

    try {
      final response = await _httpClient.post(url, body: body);

      if (response.statusCode == 201) {
        return json.decode(response.body); 
      } else {
        return json.decode(response.body); 
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> startSession({
    required String plate,
    required int lotId,
    required String spotIdentifier,
  }) async {
    final url = Uri.parse('$_baseUrl/sessions/');
    
    final body = {
      'vehicle_plate': plate,
      'parking_lot_id': lotId,
      'spot_identifier': spotIdentifier,
    };

    try {
      final response = await _httpClient.post(url, body: body);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return json.decode(response.body);
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> endSession({required int sessionId}) async {
    final url = Uri.parse('$_baseUrl/sessions/$sessionId/end_session/');

    try {
      final response = await _httpClient.post(url); 

      if (response.statusCode == 200) {
        return json.decode(response.body); 
      } else {
        return json.decode(response.body); 
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchActiveSessions() async {
    final url = Uri.parse('$_baseUrl/sessions/'); 

    try {
      final response = await _httpClient.get(url); 

      if (response.statusCode == 200) {
        final List<dynamic> sessionList = json.decode(response.body);

        final activeSessions = sessionList.where((s) => s['status'] == 'ACTIVE').toList();

        return activeSessions.cast<Map<String, dynamic>>(); 
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchUserVehicles() async {
      final url = Uri.parse('$_baseUrl/vehicles/'); 
      try {
          final response = await _httpClient.get(url); 
          if (response.statusCode == 200) {
              return json.decode(response.body).cast<Map<String, dynamic>>();
          }
          return null;
      } catch (e) {
          return null;
      }
  }
}