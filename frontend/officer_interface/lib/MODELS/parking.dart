class Parking {
  final int id;
  final String name;
  final String city;
  final String address;
  
  Parking({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'] as int,
      name: json['name'] ?? 'N/A',
      city: json['city'] ?? 'N/A',
      address: json['address'] ?? 'N/A',
    );
  }
}