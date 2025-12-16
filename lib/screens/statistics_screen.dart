import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            final expensesByCategory = provider.expensesByCategory;
            final monthlyIncome = provider.monthlyIncome;
            final monthlyExpenses = provider.monthlyExpenses;

            return CustomScrollView(
              slivers: [
                // Small top spacing to align with other pages
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Summary Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Revenus totaux',
                            amount: provider.totalIncome,
                            color: AppTheme.incomeColor,
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Dépenses totales',
                            amount: provider.totalExpenses,
                            color: AppTheme.expenseColor,
                            icon: Icons.trending_down_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expenses by Category
                if (expensesByCategory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Text(
                        'Dépenses par catégorie',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                if (expensesByCategory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CategoryChart(expensesByCategory: expensesByCategory),
                    ),
                  ),

                // Monthly Evolution
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text(
                      'Évolution mensuelle',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MonthlyChart(
                      monthlyIncome: monthlyIncome,
                      monthlyExpenses: monthlyExpenses,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(amount),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<String, double> expensesByCategory;

  const _CategoryChart({required this.expensesByCategory});

  @override
  Widget build(BuildContext context) {
    final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final entries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final categoryEntry = entry.value;
                  final percentage = (categoryEntry.value / total) * 100;
                  final color = AppTheme.categoryColors[index % AppTheme.categoryColors.length];

                  return PieChartSectionData(
                    value: categoryEntry.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: color,
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final percentage = (categoryEntry.value / total) * 100;
            final color = AppTheme.categoryColors[index % AppTheme.categoryColors.length];
            final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryEntry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    formatter.format(categoryEntry.value),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpenses;

  const _MonthlyChart({
    required this.monthlyIncome,
    required this.monthlyExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final allMonths = <String>{...monthlyIncome.keys, ...monthlyExpenses.keys}.toList()
      ..sort();

    if (allMonths.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Aucune donnée disponible',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    final maxValue = [
      ...monthlyIncome.values,
      ...monthlyExpenses.values,
    ].fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey[800],
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < allMonths.length) {
                          final month = allMonths[value.toInt()];
                          final parts = month.split('-');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${parts[1]}/${parts[0].substring(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value % (maxValue / 4) == 0) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
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
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(allMonths.length, (index) {
                  final month = allMonths[index];
                  final income = monthlyIncome[month] ?? 0;
                  final expense = monthlyExpenses[month] ?? 0;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: AppTheme.incomeColor,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: expense,
                        color: AppTheme.expenseColor,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: AppTheme.incomeColor,
                label: 'Revenus',
              ),
              const SizedBox(width: 24),
              _LegendItem(
                color: AppTheme.expenseColor,
                label: 'Dépenses',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

