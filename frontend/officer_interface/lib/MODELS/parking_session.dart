import 'package:officer_interface/MODELS/parking.dart';
import 'package:officer_interface/MODELS/vehicle.dart';

class ParkingSession {
  final int id;
  final Vehicle vehicle;
  final Parking? parkingLot;
  final DateTime startTime;
  final bool isActive;
  final double? totalCost;
  
  // NUOVO CAMPO
  final DateTime? plannedEndTime; 

  // Convenience getters
  String get vehiclePlate => vehicle.plate;
  String get vehicleName => vehicle.name;

  ParkingSession({
    required this.id,
    required this.vehicle,
    this.parkingLot,
    required this.startTime,
    required this.isActive,
    this.totalCost,
    this.plannedEndTime, // Aggiunto al costruttore
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
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
      parkingLot: parkingLotData.isNotEmpty ? Parking.fromJson(parkingLotData) : null,
      startTime: DateTime.parse(json['start_time']),
      isActive: json['is_active'] ?? false,
      totalCost: parseCost(json['total_cost']),
      
      // Parsing della data di fine (se presente)
      plannedEndTime: json['planned_end_time'] != null 
          ? DateTime.parse(json['planned_end_time']) 
          : null,
    );
  }
}