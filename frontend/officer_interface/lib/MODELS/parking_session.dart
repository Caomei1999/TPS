import 'package:officer_interface/MODELS/parking.dart';
import 'package:officer_interface/MODELS/vehicle.dart';

class ParkingSession {
  final int id;
  final Vehicle vehicle;
  final Parking? parkingLot;
  final DateTime startTime;
  final bool isActive;
  final DateTime endTime;
  final double? totalCost;

  // Convenience getters for display (Controller App)
  String get vehiclePlate => vehicle.plate;
  String get vehicleName => vehicle.name;

  ParkingSession({
    required this.id,
    required this.vehicle,
    this.parkingLot,
    required this.endTime,
    required this.startTime,
    required this.isActive,
    this.totalCost,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    // Deserialize nested objects using the lighter models
    final vehicleData = json['vehicle'] ?? {};
    final parkingLotData = json['parking_lot'] ?? {};

    double? parseCost(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return ParkingSession(
      id: json['id'],
      vehicle: Vehicle.fromJson(vehicleData),
      parkingLot: parkingLotData.isNotEmpty
          ? Parking.fromJson(parkingLotData)
          : null,
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      isActive: json['is_active'] ?? false,
      totalCost: parseCost(json['total_cost']),
    );
  }
}
