import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:manager_interface/models/tariff_config.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/parking_cost_calculator.dart';

class ActiveRulesCard extends StatelessWidget {
  final TariffConfig config;

  const ActiveRulesCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    
    // Convert raw dynamic list back to FlexRule for display safety
    final List<FlexRule> flexRules = (config.flexRulesRaw as List<dynamic>?)
        ?.map((r) => FlexRule.fromTariffConfig(r))
        .toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Rules Summary',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white12, height: 20),
        Text('Type: ${config.type.replaceAll('_', ' ')}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        Text('Day Tariff: ${currencyFormatter.format(config.dayBaseRate)} /h', style: GoogleFonts.poppins(color: Colors.white70)),
        Text('Night Tariff: ${currencyFormatter.format(config.nightBaseRate)} /h', style: GoogleFonts.poppins(color: Colors.white70)),
        Text('Night Hours: ${config.nightStartTime} - ${config.nightEndTime}', style: GoogleFonts.poppins(color: Colors.white70)),
        
        if (config.type == 'HOURLY_VARIABLE' && flexRules.isNotEmpty) ...[
          const Divider(color: Colors.white12, height: 20),
          Text('Duration Multipliers:', style: GoogleFonts.poppins(color: Colors.white)),
          ...flexRules.map((rule) => 
            Text('${rule.durationFromHours}h to ${rule.durationToHours}h: x${rule.multiplier.toStringAsFixed(1)}', style: GoogleFonts.poppins(color: Colors.blueAccent))
          ).toList(),
        ]
      ],
    );
  }
}