class ParkingSession {
  final int id;
  final String vehiclePlate;
  final String vehicleName;
  final DateTime startTime;
  final bool isActive;
  final double? totalCost;

  ParkingSession({
    required this.id,
    required this.vehiclePlate,
    required this.vehicleName,
    required this.startTime,
    required this.isActive,
    this.totalCost,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    // Handle nested vehicle object from serializer
    final vehicleData = json['vehicle'] ?? {};
    
    return ParkingSession(
      id: json['id'],
      vehiclePlate: vehicleData['plate'] ?? 'UNKNOWN',
      vehicleName: vehicleData['name'] ?? 'Unknown',
      startTime: DateTime.parse(json['start_time']),
      isActive: json['is_active'] ?? false,
      totalCost: json['total_cost'] != null 
          ? double.tryParse(json['total_cost'].toString()) 
          : null,
    );
  }
}