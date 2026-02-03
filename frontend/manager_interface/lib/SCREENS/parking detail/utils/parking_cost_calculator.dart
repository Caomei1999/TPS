import 'package:flutter/material.dart';
import 'package:manager_interface/models/tariff_config.dart';

class CostCalculator {
  final TariffConfig config;

  CostCalculator(this.config);

  double calculateCostForHours(double hours, {TimeOfDay? startTime}) {
    if (hours <= 0) return 0.0;

    if (config.type == 'FIXED_DAILY') {
      return config.dailyRate;
    }

    double totalCost = 0.0;
    double remainingHours = hours;

    double currentHourOfDay = 0.0;
    if (startTime != null) {
      currentHourOfDay = startTime.hour + (startTime.minute / 60.0);
    }

    final List<FlexRule> flexRules =
        (config.flexRulesRaw as List<dynamic>?)
            ?.map((r) => FlexRule.fromTariffConfig(r))
            .toList() ??
        [];

    while (remainingHours > 0) {
      double hourlyRate;
      double segmentDuration = 1.0;

      bool isNight = _isNightTime(currentHourOfDay);
      double baseRate = isNight ? config.nightBaseRate : config.dayBaseRate;

      if (config.type == 'HOURLY_LINEAR') {
        hourlyRate = baseRate;
      } else {
        double elapsedTime = hours - remainingHours;

        FlexRule? activeRule;
        for (var rule in flexRules) {
          if (elapsedTime >= rule.durationFromHours &&
              elapsedTime < rule.durationToHours) {
            activeRule = rule;
            break;
          }
        }

        double multiplier = activeRule?.multiplier ?? 1.0;
        hourlyRate = baseRate * multiplier;
      }

      double chargeDuration = (remainingHours >= segmentDuration)
          ? segmentDuration
          : remainingHours;
      totalCost += hourlyRate * chargeDuration;

      remainingHours -= chargeDuration;
      currentHourOfDay = (currentHourOfDay + chargeDuration) % 24;
    }

    double max24hCost = 24.0 * config.dayBaseRate;
    return totalCost > max24hCost ? max24hCost : totalCost;
  }

  bool _isNightTime(double hourOfDay) {
    final nightStart =
        double.tryParse(config.nightStartTime.split(':').first) ?? 22.0;
    final nightEnd =
        double.tryParse(config.nightEndTime.split(':').first) ?? 6.0;

    if (nightStart > nightEnd) {
      return hourOfDay >= nightStart || hourOfDay < nightEnd;
    } else {
      return hourOfDay >= nightStart && hourOfDay < nightEnd;
    }
  }
}
