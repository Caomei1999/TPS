import 'dart:convert';
import 'dart:developer' as developer;
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';
import 'package:user_interface/SERVICES/CONFIG/api.dart';

const String _baseUrl = Api.sessions;

class ParkingSessionService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<List<ParkingSession>> fetchSessions({bool? active}) async {
    String urlString = _baseUrl;
    if (active != null) {
      urlString += '?active=${active.toString()}';
    }
    final url = Uri.parse(urlString);
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        List<dynamic> jsonList;
        if (decodedBody is Map<String, dynamic> &&
            decodedBody.containsKey('results')) {
          jsonList = decodedBody['results'] as List<dynamic>;
        } else if (decodedBody is List) {
          jsonList = decodedBody;
        } else {
          jsonList = [];
        }
        return jsonList
            .map((json) => ParkingSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      developer.log('Errore fetchSessions: $e');
    }
    return [];
  }

  Future<ParkingSession?> startSession({
    required int vehicleId,
    required int parkingLotId,
    required int durationMinutes,
    required double prepaidCost, 
  }) async {
    final url = Uri.parse(_baseUrl);

    final double roundedCost = double.parse(prepaidCost.toStringAsFixed(2));

    try {
      final response = await _httpClient.post(
        url,
        body: {
          'vehicle_id': vehicleId,
          'parking_lot_id': parkingLotId,
          'duration_purchased_minutes': durationMinutes,
          'prepaid_cost': roundedCost,
        },
      );

      if (response.statusCode == 201) {
        return ParkingSession.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      developer.log('Errore startSession status');
      
    } catch (e) {
      developer.log('Errore startSession network');
    }
    return null;
  }

  Future<ParkingSession?> endSession(int sessionId) async {
    final url = Uri.parse('$_baseUrl$sessionId/end_session/');
    try {
      final response = await _httpClient.post(url);
      if (response.statusCode == 200) {
        return ParkingSession.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      developer.log('Errore endSession status:');
    } catch (e) {
      developer.log('Errore endSession network');
    }
    return null;
  }
}