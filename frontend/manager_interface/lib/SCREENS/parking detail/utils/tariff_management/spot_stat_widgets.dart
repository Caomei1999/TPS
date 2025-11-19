import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpotStatCard extends StatelessWidget {
  final int totalSpots;
  final int occupiedSpots;
  final int availableSpots;
  final VoidCallback onAddSpot;
  final VoidCallback onRemoveLastSpot;

  const SpotStatCard({
    super.key,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.availableSpots,
    required this.onAddSpot,
    required this.onRemoveLastSpot,
  });

  Widget _buildSpotStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(color: color.withOpacity(0.8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spot Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white12, height: 20),
        Row(
          children: [
            _buildSpotStat('Total Spots', totalSpots, Colors.blueGrey),
            const SizedBox(width: 10),
            _buildSpotStat('Occupied', occupiedSpots, Colors.redAccent),
            const SizedBox(width: 10),
            _buildSpotStat('Available', availableSpots, Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddSpot,
                icon: const Icon(Icons.add, color: Color(0xFF340C6C)),
                label: Text('Add Spot', style: GoogleFonts.poppins(color: Color(0xFF340C6C))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRemoveLastSpot,
                icon: const Icon(Icons.remove, color: Colors.white),
                label: Text('Remove Last', style: GoogleFonts.poppins(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}