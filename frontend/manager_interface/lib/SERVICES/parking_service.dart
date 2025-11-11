import 'dart:convert';
import 'package:manager_interface/services/authentication helpers/authenticated_http_client.dart';
import 'package:http/http.dart' as http;
import '../models/parking.dart';
import '../models/spot.dart';

class ParkingService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  static const String _apiBase = 'http://127.0.0.1:8000/api/parkings/';
  static const String baseUrl = '${_apiBase}parkings/'; 

  static Future<List<String>> getCities() async {
    final response = await _httpClient.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final cities = data.map((p) => p['city'] as String).toSet().toList();
      cities.sort();
      return cities;
    } else {
      throw Exception('Failed to load cities: ${response.statusCode}');
    }
  }

  static Future<List<Parking>> getParkingsByCity(String city) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl?city=$city'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Parking.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load parkings for city $city: ${response.statusCode}');
    }
  }

  static Future<Parking> getParking(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl$parkingId/'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Parking.fromJson(jsonData);
    } else {
      throw Exception('Failed to load parking $parkingId: ${response.statusCode}');
    }
  }

  static Future<List<Spot>> getSpots(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl$parkingId/spots/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Spot.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load spots for parking $parkingId: ${response.statusCode}');
    }
  }

  static Future<Parking> saveParking(Parking parkingData) async {
    Uri url;
    http.Response response;
    final body = parkingData.toJson();
    if (parkingData.id != 0) {
      url = Uri.parse('$baseUrl${parkingData.id}/');
      response = await _httpClient.put(url, body: body);
    } else {
      url = Uri.parse(baseUrl);
      response = await _httpClient.post(url, body: body);
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Parking.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to save parking: ${response.statusCode}');
    }
  }

  static Future<bool> deleteParking(int parkingId) async {
    final url = Uri.parse('$baseUrl$parkingId/');
    final response = await _httpClient.delete(url);
    if (response.statusCode == 204) {
      return true;
    } else {
      String errorDetail = response.body.isNotEmpty 
                           ? json.decode(response.body).toString() 
                           : 'Unknown error occurred.';
      throw Exception('Failed to delete parking (Code ${response.statusCode}): $errorDetail');
    }
  }

  static Future<Spot> addSpot(int parkingId) async {
    final url = Uri.parse('${_apiBase}spots/'); 
    final body = {
        'parking': parkingId, 
        'number': 'AUTO', 
        'floor': '', 
        'zone': '', 
        'is_occupied': false
    };
    final response = await _httpClient.post(url, body: body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Spot.fromJson(json.decode(response.body));
    } else {
      String errorDetail = response.body.isNotEmpty 
                           ? json.decode(response.body).toString() 
                           : 'Unknown error occurred.';
      throw Exception('Failed to add spot (Code ${response.statusCode}): $errorDetail');
    }
}

  static Future<bool> deleteSpot(int spotId) async {
    final url = Uri.parse('${_apiBase}spots/$spotId/');
    final response = await _httpClient.delete(url);
    return response.statusCode == 204;
  }

  static Future<Parking?> updateParking({
    required int parkingId,
    required String name,
    required String city,
    required String address,
  }) async {
    final url = Uri.parse('$baseUrl$parkingId/');
    final body = {'name': name, 'city': city, 'address': address};
    final response = await _httpClient.put(url, body: body);
    if (response.statusCode == 200) {
      return Parking.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }
}
