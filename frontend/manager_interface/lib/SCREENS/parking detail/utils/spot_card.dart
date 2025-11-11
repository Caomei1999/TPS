import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:manager_interface/models/spot.dart';

class SpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onDelete;

  const SpotCard({super.key, required this.spot, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAvailable = !spot.isOccupied; // vero se libero

    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        title: Text(
          'Spot ${spot.id}',
          style: GoogleFonts.poppins(
            color: isAvailable ? Colors.greenAccent : Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Floor: ${spot.floor} | Zone: ${spot.zone} | Status: ${isAvailable ? "Available" : "Occupied"}',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
