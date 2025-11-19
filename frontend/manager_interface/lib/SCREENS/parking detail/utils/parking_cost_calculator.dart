import 'package:manager_interface/models/tariff_config.dart';

class FlexRule {
  int durationFromHours;
  int durationToHours;
  double multiplier;

  FlexRule({
    required this.durationFromHours,
    required this.durationToHours,
    required this.multiplier,
  });

  factory FlexRule.fromTariffConfig(Map<String, dynamic> json) {
    return FlexRule(
      durationFromHours: json['duration_from_hours'],
      durationToHours: json['duration_to_hours'],
      multiplier: double.tryParse(json['multiplier'].toString()) ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration_from_hours': durationFromHours,
      'duration_to_hours': durationToHours,
      'multiplier': multiplier,
    };
  }
}

class CostCalculator {
  final TariffConfig config;

  CostCalculator(this.config);

  double calculateCostForHours(double hours) {
    if (hours <= 0) return 0.0;
    
    // 1. Fixed Daily Rate
    if (config.type == 'FIXED_DAILY') {
      return config.dailyRate;
    }

    double totalCost = 0.0;
    double remainingHours = hours;
    double currentHourOfDay = 0.0; 

    // Retrieve FlexRules safely
    final List<FlexRule> flexRules = (config.flexRulesRaw as List<dynamic>?)
        ?.map((r) => FlexRule.fromTariffConfig(r))
        .toList() ?? [];

    // 2. Hourly Rate (Linear or Variable)
    while (remainingHours > 0) {
      double hourlyRate;
      double segmentDuration = 1.0; 
      
      bool isNight = _isNightTime(currentHourOfDay);
      double baseRate = isNight ? config.nightBaseRate : config.dayBaseRate;

      if (config.type == 'HOURLY_LINEAR') {
        hourlyRate = baseRate;
      } else { // HOURLY_VARIABLE
        
        double elapsedTime = hours - remainingHours;
        
        FlexRule? activeRule;
        for (var rule in flexRules) {
          if (elapsedTime >= rule.durationFromHours && elapsedTime < rule.durationToHours) {
            activeRule = rule;
            break;
          }
        }
        
        double multiplier = activeRule?.multiplier ?? 1.0;
        hourlyRate = baseRate * multiplier;
      }

      double chargeDuration = (remainingHours >= segmentDuration) ? segmentDuration : remainingHours;
      totalCost += hourlyRate * chargeDuration;

      remainingHours -= chargeDuration;
      currentHourOfDay = (currentHourOfDay + chargeDuration) % 24;
    }
    
    // 3. Daily Cap (if applicable)
    double max24hCost = 24.0 * config.dayBaseRate; 
    return totalCost > max24hCost ? max24hCost : totalCost;
  }

  bool _isNightTime(double hourOfDay) {
    final nightStart = double.tryParse(config.nightStartTime.split(':').first) ?? 22.0;
    final nightEnd = double.tryParse(config.nightEndTime.split(':').first) ?? 6.0;

    if (nightStart > nightEnd) {
      // Night wraps around midnight (e.g., 22:00 to 06:00)
      return hourOfDay >= nightStart || hourOfDay < nightEnd;
    } else {
      // Night is fully contained in one day
      return hourOfDay >= nightStart && hourOfDay < nightEnd;
    }
  }
}