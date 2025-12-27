import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/budget_vs_actual.dart';
import '../../theme/app_theme.dart';

class BudgetVsActualChartWidget extends StatelessWidget {
  final List<BudgetVsActual> data;
  final bool isLoading;

  const BudgetVsActualChartWidget({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget vs Réel',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune donnée disponible',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    final maxY = data.fold<double>(
      0.0,
      (max, item) => max > item.budgetAmount && max > item.actualAmount
          ? max
          : (item.budgetAmount > item.actualAmount ? item.budgetAmount : item.actualAmount),
    ) * 1.2; // Ajouter 20% de marge

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget vs Réel',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = 250.0;
              final dataCount = data.length;
              
              // Si trop de points, permettre le scroll horizontal
              final needsScroll = dataCount > 15;
              final chartWidth = needsScroll ? dataCount * 50.0 : constraints.maxWidth;
              
              Widget chart = SizedBox(
                width: chartWidth,
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = data[groupIndex];
                          final value = rod.toY;
                          final label = rodIndex == 0 ? 'Budget' : 'Réel';
                          return BarTooltipItem(
                            '${item.categoryName}\n$label: ${formatter.format(value)}',
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= data.length) return const Text('');
                            final item = data[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                item.categoryName.length > 10
                                    ? '${item.categoryName.substring(0, 10)}...'
                                    : item.categoryName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          reservedSize: 40,
                          interval: _getBottomTitlesInterval(dataCount),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              formatter.format(value),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                          reservedSize: 50,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[200]!,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        left: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    barGroups: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      // Calculer la largeur des barres selon le nombre de données
                      final barWidth = dataCount > 10 ? 10.0 : (dataCount > 5 ? 12.0 : 16.0);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: item.budgetAmount,
                            color: AppTheme.primaryColor,
                            width: barWidth,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: item.actualAmount,
                            color: item.percentageUsed > 100
                                ? Colors.red
                                : item.percentageUsed > 80
                                    ? Colors.orange
                                    : AppTheme.expenseColor,
                            width: barWidth,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                        barsSpace: dataCount > 10 ? 2 : (dataCount > 5 ? 3 : 4),
                      );
                    }).toList(),
                  ),
                ),
              );

              if (needsScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chart,
                );
              }

              return chart;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Budget', AppTheme.primaryColor),
              const SizedBox(width: 24),
              _buildLegendItem('Réel', AppTheme.expenseColor),
            ],
          ),
        ],
      ),
    );
  }

  double _getBottomTitlesInterval(int dataCount) {
    if (dataCount <= 5) return 1;
    if (dataCount <= 10) return 2;
    if (dataCount <= 20) return 3;
    return 5;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
