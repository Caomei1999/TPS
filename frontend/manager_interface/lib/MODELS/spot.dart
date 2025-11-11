class Spot {
  final int id;
  final String zone;
  final String floor;
  final int parkingId;
  final bool isOccupied;

  Spot({
    required this.id,
    required this.zone,
    required this.floor,
    required this.parkingId,
    required this.isOccupied,
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'],
      zone: json['zone'] ?? '',
      floor: json['floor'] ?? '',
      parkingId: json['parking'],
      isOccupied: json['is_occupied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone': zone,
      'floor': floor,
      'parking': parkingId,
      'is_occupied': isOccupied,
    };
  }
}
