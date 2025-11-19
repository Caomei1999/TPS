import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CostChart extends StatelessWidget {
  final List<FlSpot> chartData;

  const CostChart({super.key, required this.chartData});

  Widget _buildSummaryBox(String label, int hours) {
    if (chartData.isEmpty || hours > chartData.last.x.toInt()) return const SizedBox.shrink();
    
    final costSpot = chartData.firstWhere((s) => s.x.toInt() == hours, orElse: () => FlSpot(hours.toDouble(), 0.0));
    final cost = costSpot.y;
    
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return Container( 
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 10, 100).withOpacity(0.5), 
        borderRadius: BorderRadius.circular(10),
        border: BoxBorder.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(cost),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double minY = 0;
    double maxY = 0;

    if (chartData.isNotEmpty) {
      final List<double> yValues = chartData
          .where((spot) => spot.x > 0)
          .map((spot) => spot.y)
          .toList();
      
      if (yValues.isNotEmpty) {
        minY = (yValues.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, double.infinity);
      }
      
      maxY = yValues.reduce((a, b) => a > b ? a : b) + 10;
    }
    
    if (maxY == 0) {
        maxY = 50; 
    }

    const Color gridColor = Colors.white38;
    const Color gradientStartColor = Color.fromARGB(255, 120, 70, 255); 
    const Color gradientEndColor = Color.fromARGB(255, 30, 10, 100); 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cost Projection (24h)', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const Divider(color: Colors.white12, height: 20),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              
              gridData: const FlGridData(show: false),
              
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: (maxY / 5).ceilToDouble() * 1,
                    color: gridColor.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [8, 4], 
                  ),
                  HorizontalLine(
                    y: (maxY / 5).ceilToDouble() * 2,
                    color: gridColor.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [8, 4],
                  ),
                  HorizontalLine(
                    y: (maxY / 5).ceilToDouble() * 3,
                    color: gridColor.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [8, 4],
                  ),
                  HorizontalLine(
                    y: (maxY / 5).ceilToDouble() * 4,
                    color: gridColor.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [8, 4],
                  ),
                  HorizontalLine(
                    y: (maxY / 5).ceilToDouble() * 4.99,
                    color: gridColor.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [8, 4],
                  ),
                ].where((line) => line.y < maxY).toList(), 
              ),

              lineTouchData: LineTouchData(
                enabled: true,

                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.all(10),
                  tooltipMargin: 8,
                  getTooltipItems: (touchedSpots) {
                    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

                    return touchedSpots.map((spot) {
                      final hours = spot.x.toInt();
                      final price = formatter.format(spot.y);

                      return LineTooltipItem(
                        'Duration: $hours h\nCost: $price',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),

                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> indicators) {
                  return indicators.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: Colors.white.withOpacity(0.9),
                        strokeWidth: 1.2,          
                        dashArray: null,          
                      ),

                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,                    
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.indigoAccent,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),

              clipData: const FlClipData.all(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text('Hours', style: GoogleFonts.poppins(color: Colors.white70)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                        if (value % 4 == 0) { 
                            return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text('${value.toInt()}h', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                            );
                        }
                        return const SizedBox.shrink();
                    },
                    interval: 1,
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                    axisNameWidget: Text('Cost (€)', style: GoogleFonts.poppins(color: Colors.white70)),
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('€${value.toInt()}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        reservedSize: 40,
                        interval: (maxY / 5).ceilToDouble(), 
                    ),
                ),
                // NEW: Hide top and right titles
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              
              // NEW: Show only left and bottom borders
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.white24.withOpacity(0.5), width: 1.5),
                  left: BorderSide(color: Colors.white24.withOpacity(0.5), width: 1.5),
                  top: BorderSide.none, // Hide top border
                  right: BorderSide.none, // Hide right border
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  color: Colors.indigoAccent,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        gradientStartColor.withOpacity(0.5),
                        gradientEndColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                Expanded(child: _buildSummaryBox('1 Hour', 1)), 
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryBox('4 Hours', 4)),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryBox('24 Hours', 24)),
            ]
        )
      ],
    );
  }
}