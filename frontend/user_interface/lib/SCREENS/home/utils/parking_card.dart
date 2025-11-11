import 'package:flutter/material.dart';

class ParkingCard extends StatelessWidget {
  final String name;
  final String address;
  final double distance; // in km
  final int availableSpots;
  final double hourlyRate; // tariffa oraria

  const ParkingCard({
    super.key,
    required this.name,
    required this.address,
    required this.distance,
    required this.availableSpots,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏢 Nome parcheggio
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "$address · ${distance.toStringAsFixed(1)} km",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$availableSpots spots • €${hourlyRate.toStringAsFixed(2)}/h",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueAccent,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
