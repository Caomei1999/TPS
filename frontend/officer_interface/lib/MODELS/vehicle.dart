class Vehicle {
  final int id;
  final String plate;
  final String name;

  Vehicle({
    required this.id,
    required this.plate,
    required this.name,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      plate: json['plate'] ?? '',
      name: json['name'] ?? 'Unknown Vehicle',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'name': name,
    };
  }
}