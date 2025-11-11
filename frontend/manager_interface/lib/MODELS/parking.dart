class Parking {
  final int id;
  final String name;
  final String city;
  final String address;
  final int totalSpots;
  final int occupiedSpots;
  final double ratePerHour;

  Parking({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.ratePerHour,
  });

  /// Safe parser for rate (handles num, string, null)
  static double _parseRate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString();
    // try parse with comma or dot
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'] as int,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      totalSpots: (json['total_spots'] is int)
          ? json['total_spots'] as int
          : (int.tryParse('${json['total_spots']}') ?? 0),
      occupiedSpots: (json['occupied_spots'] is int)
          ? json['occupied_spots'] as int
          : (int.tryParse('${json['occupied_spots']}') ?? 0),
      ratePerHour: _parseRate(json['rate'] ?? json['rate_per_hour']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      // send numeric types (not string) so backend receives numbers
      'total_spots': totalSpots,
      'occupied_spots': occupiedSpots,
      'rate': ratePerHour,
    };
  }

  int get availableSpots => totalSpots - occupiedSpots;
}
