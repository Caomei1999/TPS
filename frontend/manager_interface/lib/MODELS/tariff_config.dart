import 'dart:convert';

class TariffConfig {
  final String type;
  final double dailyRate;
  final double dayBaseRate;
  final double nightBaseRate;
  final String nightStartTime;
  final String nightEndTime;
  final List<dynamic> flexRulesRaw;

  TariffConfig({
    required this.type,
    required this.dailyRate,
    required this.dayBaseRate,
    required this.nightBaseRate,
    required this.nightStartTime,
    required this.nightEndTime,
    required this.flexRulesRaw,
  });

  factory TariffConfig.fromJson(Map<String, dynamic> json) {
    return TariffConfig(
      type: json['type'] ?? 'HOURLY_LINEAR',
      dailyRate: (json['daily_rate'] ?? 0).toDouble(),
      dayBaseRate: (json['day_base_rate'] ?? 0).toDouble(),
      nightBaseRate: (json['night_base_rate'] ?? 0).toDouble(),
      nightStartTime: json['night_start_time'] ?? '22:00',
      nightEndTime: json['night_end_time'] ?? '06:00',
      flexRulesRaw: json['flex_rules'] ?? [],
    );
  }

  String toJson() {
    final map = {
      'type': type,
      'daily_rate': dailyRate,
      'day_base_rate': dayBaseRate,
      'night_base_rate': nightBaseRate,
      'night_start_time': nightStartTime,
      'night_end_time': nightEndTime,
      'flex_rules': flexRulesRaw,
    };
    return jsonEncode(map);
  }
}

class FlexRule {
  String ruleType;
  String? dayOfWeek;
  String? startTime;
  String? endTime;
  double modifier;
  
  // Mutable fields for duration-based rules
  int durationFromHours;
  int durationToHours;
  double multiplier;

  FlexRule({
    this.ruleType = 'DURATION',
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.modifier = 1.0,
    this.durationFromHours = 0,
    this.durationToHours = 4,
    this.multiplier = 1.0,
  });

  factory FlexRule.fromTariffConfig(Map<String, dynamic> json) {
    final ruleType = json['rule_type'] ?? 'DURATION';
    
    return FlexRule(
      ruleType: ruleType,
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      modifier: (json['modifier'] ?? 1.0).toDouble(),
      durationFromHours: (json['duration_from_hours'] ?? 0),
      durationToHours: (json['duration_to_hours'] ?? 4),
      multiplier: (json['multiplier'] ?? json['modifier'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rule_type': ruleType,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'modifier': modifier,
      'duration_from_hours': durationFromHours,
      'duration_to_hours': durationToHours,
      'multiplier': multiplier,
    };
  }
}