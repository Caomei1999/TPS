import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlockedAccountAlert extends StatelessWidget {
  const BlockedAccountAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15), // Sfondo rosso trasparente
        border: Border.all(color: Colors.redAccent, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(Icons.block, color: Colors.redAccent, size: 30),
          const SizedBox(height: 10),
          Text(
            "Account Blocked",
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "You have exceeded violations limit.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "For more information contact:\nsupport@tps.com",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}