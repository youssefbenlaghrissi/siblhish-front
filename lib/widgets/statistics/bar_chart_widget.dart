import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/statistics.dart';
import '../../theme/app_theme.dart';

class BarChartWidget extends StatelessWidget {
  final List<MonthlySummary> monthlyData;

  const BarChartWidget({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
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
      );
    }

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
            'Revenus vs Dépenses',
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
              final maxY = _getMaxY();
              final dataCount = monthlyData.length;
              
              // Si trop de points, permettre le scroll horizontal
              final needsScroll = dataCount > 15;
              final chartWidth = needsScroll ? dataCount * 50.0 : constraints.maxWidth;
              
              Widget chart = SizedBox(
                width: chartWidth,
                height: chartHeight,
                child: Stack(
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final month = monthlyData[groupIndex].month;
                              final monthName = _formatMonth(month);
                              final value = rod.toY;
                              final label = rodIndex == 0 ? 'Revenus' : 'Dépenses';
                              return BarTooltipItem(
                                '$monthName\n$label: ${_formatCurrency(value)}',
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
                                if (value.toInt() >= monthlyData.length) return const Text('');
                                final month = monthlyData[value.toInt()].month;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _formatMonth(month),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                              reservedSize: 40,
                              interval: _getBottomTitlesInterval(),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _formatCurrency(value),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              },
                              reservedSize: 75,
                              interval: _getYAxisInterval(),
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
                          horizontalInterval: _getYAxisInterval(),
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
                        barGroups: monthlyData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          // Calculer la largeur des barres dynamiquement selon le nombre de points
                          final barWidth = _calculateBarWidth(monthlyData.length);
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: data.totalIncome,
                                color: AppTheme.incomeColor,
                                width: barWidth,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                              BarChartRodData(
                                toY: data.totalExpenses,
                                color: AppTheme.expenseColor,
                                width: barWidth,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                            barsSpace: barWidth * 0.3, // Espacement proportionnel à la largeur
                          );
                        }).toList(),
                      ),
                    ),
                    // Afficher les valeurs sur les barres en utilisant les coordonnées du graphique
                    ...monthlyData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      
                      // Utiliser les mêmes marges que fl_chart
                      final leftMargin = 75.0;
                      final bottomMargin = 40.0;
                      final topMargin = 10.0;
                      final availableHeight = chartHeight - bottomMargin - topMargin;
                      final availableWidth = chartWidth - leftMargin;
                      
                      // Calculer la position X exacte du centre du groupe
                      // fl_chart utilise spaceAround, donc on doit calculer l'espacement
                      final totalSpace = availableWidth;
                      final totalBarsWidth = monthlyData.length * 20.0; // Largeur approximative des barres
                      final totalSpacing = totalSpace - totalBarsWidth;
                      final spacingBetweenGroups = monthlyData.length > 1 
                          ? totalSpacing / (monthlyData.length - 1) 
                          : 0.0;
                      
                      // Position X du centre du groupe
                      final groupCenterX = leftMargin + (index * (20.0 + spacingBetweenGroups)) + 10.0;
                      
                      // Calculer la hauteur des barres en pixels (basé sur maxY)
                      final incomeBarHeight = data.totalIncome > 0 
                          ? (data.totalIncome / maxY) * availableHeight 
                          : 0.0;
                      final expenseBarHeight = data.totalExpenses > 0 
                          ? (data.totalExpenses / maxY) * availableHeight 
                          : 0.0;
                      
                      // Position Y du bas des barres
                      final barBottomY = topMargin + availableHeight;
                      final incomeBarTopY = barBottomY - incomeBarHeight;
                      final expenseBarTopY = barBottomY - expenseBarHeight;
                      
                      return Stack(
                        children: [
                          // Valeur revenus - TOUJOURS visible
                          if (data.totalIncome > 0)
                            Positioned(
                              left: groupCenterX - 35,
                              top: incomeBarHeight > 25 
                                  ? incomeBarTopY - 20  // Au-dessus
                                  : barBottomY + 6,      // En dessous avec plus d'espace
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 50),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.incomeColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _formatCurrency(data.totalIncome),
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.incomeColor,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          // Valeur dépenses - TOUJOURS visible
                          if (data.totalExpenses > 0)
                            Positioned(
                              left: groupCenterX + 8,
                              top: expenseBarHeight > 25 
                                  ? expenseBarTopY - 20  // Au-dessus
                                  : barBottomY + 6,      // En dessous avec plus d'espace
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 50),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.expenseColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _formatCurrency(data.totalExpenses),
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.expenseColor,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              );
              
              if (needsScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chart,
                );
              } else {
                return chart;
              }
            },
          ),
          const SizedBox(height: 16),
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

  double _getMaxY() {
    if (monthlyData.isEmpty) return 1000;
    double max = 0;
    for (var data in monthlyData) {
      max = max > data.totalIncome ? max : data.totalIncome;
      max = max > data.totalExpenses ? max : data.totalExpenses;
    }
    // Si max est 0, retourner une valeur par défaut
    if (max == 0) return 1000;
    
    // Ajouter seulement 10% de marge pour éviter d'écraser les petites valeurs
    final maxWithMargin = max * 1.1;
    
    // Arrondir à un intervalle simple et proche
    return _roundToSimpleMax(maxWithMargin);
  }

  /// Arrondit maxY à une valeur simple et proche
  double _roundToSimpleMax(double value) {
    if (value <= 0) return 1000;
    
    final ln10 = math.log(10);
    final magnitude = (math.log(value) / ln10).floor();
    final powerOf10 = math.pow(10, magnitude).toDouble();
    final normalized = value / powerOf10;
    
    // Arrondir vers le haut à 1, 1.2, 1.5, 2, 3, 5, ou 10
    double rounded;
    if (normalized <= 1) {
      rounded = 1;
    } else if (normalized <= 1.2) {
      rounded = 1.2;
    } else if (normalized <= 1.5) {
      rounded = 1.5;
    } else if (normalized <= 2) {
      rounded = 2;
    } else if (normalized <= 3) {
      rounded = 3;
    } else if (normalized <= 5) {
      rounded = 5;
    } else {
      rounded = 10;
    }
    
    return rounded * powerOf10;
  }

  /// Arrondit une valeur à un intervalle "propre" pour l'affichage
  /// Exemples : 1234 → 1500, 5678 → 6000, 12345 → 15000
  double _roundToNiceInterval(double value) {
    if (value <= 0) return 1000;
    
    // Calculer l'ordre de grandeur en utilisant log naturel
    // log10(x) = ln(x) / ln(10)
    final ln10 = math.log(10);
    final magnitude = (math.log(value) / ln10).floor();
    final powerOf10 = math.pow(10, magnitude).toDouble();
    
    // Normaliser la valeur (ex: 1234 → 1.234)
    final normalized = value / powerOf10;
    
    // Arrondir à un intervalle "propre" mais plus proche (1, 1.5, 2, 3, 5, 10)
    double rounded;
    if (normalized <= 1) {
      rounded = 1;
    } else if (normalized <= 1.5) {
      rounded = 1.5;
    } else if (normalized <= 2) {
      rounded = 2;
    } else if (normalized <= 3) {
      rounded = 3;
    } else if (normalized <= 5) {
      rounded = 5;
    } else {
      rounded = 10;
    }
    
    return rounded * powerOf10;
  }

  String _formatMonth(String month) {
    try {
      // Gérer les différents formats de période :
      // - "2025-01-15" (day) -> afficher seulement le numéro du jour "15"
      // - "2025-01" (month) -> afficher "Jan"
      // - "2025" (year) -> afficher "2025"
      if (month.contains('-')) {
        final parts = month.split('-');
        if (parts.length == 3) {
          // Format day: "2025-01-15" -> afficher seulement "15"
          final date = DateTime.parse(month);
          return date.day.toString();
        } else if (parts.length == 2) {
          // Format month: "2025-01"
          final date = DateTime.parse('$month-01');
          return DateFormat('MMM', 'fr').format(date);
        }
      } else {
        // Format year: "2025"
        return month;
      }
      return month;
    } catch (e) {
      return month;
    }
  }

  /// Calcule la largeur des barres dynamiquement selon le nombre de points
  double _calculateBarWidth(int dataCount) {
    if (dataCount <= 7) {
      // Pour 7 jours ou moins : largeur normale
      return 20;
    } else if (dataCount <= 15) {
      // Pour 8-15 jours : réduire la largeur
      return 16;
    } else if (dataCount <= 31) {
      // Pour 16-31 jours : largeur encore plus petite
      return 12;
    } else {
      // Pour plus de 31 points : largeur minimale
      return 8;
    }
  }

  /// Détermine l'intervalle d'affichage des labels sur l'axe X pour éviter le chevauchement
  double _getBottomTitlesInterval() {
    final dataCount = monthlyData.length;
    if (dataCount <= 7) {
      // Afficher tous les labels pour 7 jours ou moins
      return 1;
    } else if (dataCount <= 15) {
      // Afficher un label sur deux pour 8-15 jours
      return 2;
    } else if (dataCount <= 31) {
      // Afficher un label sur trois pour 16-31 jours
      return 3;
    } else {
      // Afficher un label sur cinq pour plus de 31 points
      return 5;
    }
  }

  /// Calcule l'intervalle optimal pour l'axe Y
  /// Assure que les lignes de grille correspondent aux labels
  double _getYAxisInterval() {
    final maxY = _getMaxY();
    // Diviser en 4-5 intervalles pour une meilleure lisibilité
    final numIntervals = 4;
    final rawInterval = maxY / numIntervals;
    // Arrondir à un intervalle "propre" mais plus simple
    return _roundToSimpleInterval(rawInterval);
  }

  /// Arrondit à un intervalle simple (1, 2, 5, 10, 20, 50, 100, etc.)
  double _roundToSimpleInterval(double value) {
    if (value <= 0) return 1;
    
    final ln10 = math.log(10);
    final magnitude = (math.log(value) / ln10).floor();
    final powerOf10 = math.pow(10, magnitude).toDouble();
    final normalized = value / powerOf10;
    
    double rounded;
    if (normalized <= 1) {
      rounded = 1;
    } else if (normalized <= 2) {
      rounded = 2;
    } else if (normalized <= 5) {
      rounded = 5;
    } else {
      rounded = 10;
    }
    
    return rounded * powerOf10;
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
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
      mainAxisSize: MainAxisSize.min,
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
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

