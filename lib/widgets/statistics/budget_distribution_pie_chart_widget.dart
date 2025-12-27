import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/budget_distribution.dart';
import '../../theme/app_theme.dart';

class BudgetDistributionPieChartWidget extends StatelessWidget {
  final List<BudgetDistribution> data;
  final bool isLoading;

  const BudgetDistributionPieChartWidget({
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
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Répartition des Budgets',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey[400]),
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

    // Limiter à 8 catégories pour la lisibilité
    final displayData = data.take(8).toList();
    final otherTotal = data.length > 8
        ? data.skip(8).fold<double>(0, (sum, item) => sum + item.budgetAmount)
        : 0.0;
    final total = data.fold<double>(0, (sum, item) => sum + item.budgetAmount);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Répartition des Budgets',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              // Utiliser une mise en page verticale si l'écran est trop petit
              final useVerticalLayout = constraints.maxWidth < 400;
              
              if (useVerticalLayout) {
                // Mise en page verticale : graphique en haut, légende en bas
                return Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildSections(displayData, otherTotal, total),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Légende en colonne
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        ...displayData.map((item) => SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: _BudgetLegendItem(
                                icon: item.icon,
                                name: item.categoryName,
                                amount: item.budgetAmount,
                                percentage: item.percentage,
                                color: _parseColor(item.color),
                              ),
                            )),
                        if (otherTotal > 0)
                          SizedBox(
                            width: (constraints.maxWidth - 16) / 2,
                            child: _BudgetLegendItem(
                              icon: '📦',
                              name: 'Autres',
                              amount: otherTotal,
                              percentage: (otherTotal / total) * 100,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              } else {
                // Mise en page horizontale : graphique à gauche, légende à droite
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Graphique
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 35,
                          sections: _buildSections(displayData, otherTotal, total),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Légende
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...displayData.map((item) => _BudgetLegendItem(
                                icon: item.icon,
                                name: item.categoryName,
                                amount: item.budgetAmount,
                                percentage: item.percentage,
                                color: _parseColor(item.color),
                              )),
                          if (otherTotal > 0)
                            _BudgetLegendItem(
                              icon: '📦',
                              name: 'Autres',
                              amount: otherTotal,
                              percentage: (otherTotal / total) * 100,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      List<BudgetDistribution> data, double otherTotal, double total) {
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final categoryColor = _parseColor(item.color);
      sections.add(
        PieChartSectionData(
          value: item.budgetAmount,
          title: '${item.percentage.toStringAsFixed(0)}%',
          color: categoryColor,
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Couleur noire pour le pourcentage
          ),
        ),
      );
    }

    if (otherTotal > 0) {
      sections.add(
        PieChartSectionData(
          value: otherTotal,
          title: '${((otherTotal / total) * 100).toStringAsFixed(0)}%',
          color: Colors.grey,
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Couleur noire pour le pourcentage
          ),
        ),
      );
    }

    return sections;
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return Colors.grey;
    try {
      // Nettoyer la chaîne de couleur
      String cleanedColor = colorString.trim();
      
      // Si la couleur commence par #, la remplacer par 0xFF
      if (cleanedColor.startsWith('#')) {
        cleanedColor = cleanedColor.replaceFirst('#', '0xFF');
      } 
      // Si la couleur ne commence pas par 0x ou 0xFF, ajouter 0xFF
      else if (!cleanedColor.startsWith('0x') && !cleanedColor.startsWith('0xFF')) {
        cleanedColor = '0xFF$cleanedColor';
      }
      
      // Parser la couleur
      final colorValue = int.parse(cleanedColor);
      return Color(colorValue);
    } catch (e) {
      debugPrint('⚠️ Erreur parsing couleur "$colorString": $e');
      return Colors.grey;
    }
  }
}

class _BudgetLegendItem extends StatelessWidget {
  final String icon;
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const _BudgetLegendItem({
    required this.icon,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur de couleur avec icône
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color,
                width: 1.5,
              ),
            ),
            child: Center(
              child: icon.isNotEmpty
                  ? Text(
                      icon,
                      style: const TextStyle(fontSize: 16),
                    )
                  : Icon(
                      _getIconData(icon),
                      size: 16,
                      color: color,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ligne 1 : Nom de la catégorie + Pourcentage
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pourcentage avec couleur noire
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Ligne 2 : Montant seul
                Text(
                  formatter.format(amount),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Mapping simple des noms d'icônes vers IconData
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'entertainment':
      case 'fun':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
