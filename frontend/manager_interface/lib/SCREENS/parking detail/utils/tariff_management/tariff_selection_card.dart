import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/parking_cost_calculator.dart';

typedef FieldUpdateCallback = void Function(String value);
typedef TimeUpdateCallback = void Function(TimeOfDay time);
typedef TariffUpdateCallback = void Function(String type);

class TariffManagementCard extends StatefulWidget {
  final String selectedRateType;
  final TextEditingController dailyRateController;
  final TextEditingController dayRateController;
  final TextEditingController nightRateController;
  final TimeOfDay nightStartTime;
  final TimeOfDay nightEndTime;
  final List<FlexRule> flexRules;

  final TimeOfDay simulationStartTime;
  final TimeUpdateCallback onSimulationTimeChanged;

  final VoidCallback onDataChanged;
  final TariffUpdateCallback onSelectType;
  final TimeUpdateCallback onStartTimeChanged;
  final TimeUpdateCallback onEndTimeChanged;

  const TariffManagementCard({
    super.key,
    required this.selectedRateType,
    required this.dailyRateController,
    required this.dayRateController,
    required this.nightRateController,
    required this.nightStartTime,
    required this.nightEndTime,
    required this.flexRules,
    required this.simulationStartTime,
    required this.onSimulationTimeChanged,
    required this.onDataChanged,
    required this.onSelectType,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  State<TariffManagementCard> createState() => _TariffManagementCardState();
}

class _TariffManagementCardState extends State<TariffManagementCard> {
  Widget _buildRateButton(String type, String label) {
    final bool isSelected = widget.selectedRateType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => widget.onSelectType(type),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.greenAccent : Colors.white12,
            foregroundColor: isSelected
                ? const Color(0xFF020B3C)
                : Colors.white70,
            elevation: isSelected ? 4 : 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          final normalizedValue = value.replaceAll(',', '.');
          controller.value = controller.value.copyWith(text: normalizedValue);
          onChanged?.call(normalizedValue);
          widget.onDataChanged();
        },
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerButton(
    String label,
    TimeOfDay time,
    TimeUpdateCallback onSelected,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) onSelected(newTime);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white12,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          '$label: ${time.format(context)}',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRuleTextField(
    String initialValue,
    Function(num?) onChanged, {
    required bool isHours,
  }) {
    final controller = TextEditingController(text: initialValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: (value) {
          final num? parsedValue = isHours
              ? int.tryParse(value)
              : double.tryParse(value.replaceAll(',', '.'));
          onChanged(parsedValue);
          widget.onDataChanged();
        },
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFlexRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white12, height: 20),
        Text(
          'Duration Multipliers',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.flexRules.length,
          itemBuilder: (context, index) {
            final rule = widget.flexRules[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: _buildRuleTextField(
                      rule.durationFromHours.toString(),
                      (v) {
                        if (v != null)
                          setState(() => rule.durationFromHours = v.toInt());
                      },
                      isHours: true,
                    ),
                  ),
                  const Text(' to ', style: TextStyle(color: Colors.white)),
                  SizedBox(
                    width: 50,
                    child: _buildRuleTextField(
                      rule.durationToHours.toString(),
                      (v) {
                        if (v != null)
                          setState(() => rule.durationToHours = v.toInt());
                      },
                      isHours: true,
                    ),
                  ),
                  const Text(' hours x', style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: _buildRuleTextField(
                      rule.multiplier.toStringAsFixed(2),
                      (v) {
                        if (v != null)
                          setState(() => rule.multiplier = v.toDouble());
                      },
                      isHours: false,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      setState(() => widget.flexRules.removeAt(index));
                      widget.onDataChanged();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              int lastEnd = widget.flexRules.isNotEmpty
                  ? widget.flexRules.last.durationToHours
                  : 0;
              widget.flexRules.add(
                FlexRule(
                  durationFromHours: lastEnd,
                  durationToHours: lastEnd + 4,
                  multiplier: 1.0,
                ),
              );
              widget.onDataChanged();
            });
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Step',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationTimeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Simulation Entry Time',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: widget.simulationStartTime,
              );
              if (newTime != null) widget.onSimulationTimeChanged(newTime);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                // 统一为 15，与下方输入框保持一致
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Text(
              widget.simulationStartTime.format(context),
              style: GoogleFonts.poppins(
                color: Colors.white,
                // 删除了 fontWeight: FontWeight.bold，现在字体与下方一致
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tariff & Rules',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white12, height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRateButton('FIXED_DAILY', 'Fixed Daily'),
            _buildRateButton('HOURLY_LINEAR', 'Hourly Linear'),
            _buildRateButton('HOURLY_VARIABLE', 'Hourly Variable'),
          ],
        ),

        _buildSimulationTimeSelector(),

        const SizedBox(height: 10),

        if (widget.selectedRateType == 'FIXED_DAILY')
          _buildTextField('Daily Rate (€)', widget.dailyRateController),

        if (widget.selectedRateType == 'HOURLY_LINEAR' ||
            widget.selectedRateType == 'HOURLY_VARIABLE')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Base Hourly Rates',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Day (€/h)',
                      widget.dayRateController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      'Night (€/h)',
                      widget.nightRateController,
                    ),
                  ),
                ],
              ),
              Text(
                'Night Definition (Start - End)',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimePickerButton(
                    'Start',
                    widget.nightStartTime,
                    widget.onStartTimeChanged,
                  ),
                  const SizedBox(width: 10),
                  _buildTimePickerButton(
                    'End',
                    widget.nightEndTime,
                    widget.onEndTimeChanged,
                  ),
                ],
              ),
            ],
          ),

        if (widget.selectedRateType == 'HOURLY_VARIABLE')
          _buildFlexRulesSection(),
      ],
    );
  }
}
