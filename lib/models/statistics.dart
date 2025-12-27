import 'package:flutter/foundation.dart';
import 'budget_statistics.dart';

class MonthlySummary {
  final String period; // Format: "2025-01" (month), "2025-01-15" (day), ou "2025" (year)
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  MonthlySummary({
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    try {
      return MonthlySummary(
        period: json['period']?.toString() ?? json['month']?.toString() ?? '', // Supporte 'period' (nouveau) et 'month' (ancien)
        totalIncome: (json['totalIncome'] is num) ? (json['totalIncome'] as num).toDouble() : ((json['totalIncome'] as num?)?.toDouble() ?? 0.0),
        totalExpenses: (json['totalExpenses'] is num) ? (json['totalExpenses'] as num).toDouble() : ((json['totalExpenses'] as num?)?.toDouble() ?? 0.0),
        balance: (json['balance'] is num) ? (json['balance'] as num).toDouble() : ((json['balance'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (e) {
      // En cas d'erreur de parsing, retourner un objet avec des valeurs par défaut
      return MonthlySummary(
        period: json['period']?.toString() ?? json['month']?.toString() ?? '',
        totalIncome: 0.0,
        totalExpenses: 0.0,
        balance: 0.0,
      );
    }
  }
  
  // Getter pour compatibilité avec le code existant qui utilise .month
  String get month => period;
}

class CategoryExpense {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double totalAmount;
  final double percentage;
  final int transactionCount;

  CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) {
    // Debug: afficher les données reçues
    final amount = json['amount'] ?? json['totalAmount'] ?? 0;
    final parsedAmount = (amount is num) ? amount.toDouble() : 0.0;
    
    return CategoryExpense(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] ?? 'Inconnu',
      categoryIcon: json['icon'] ?? json['categoryIcon'] ?? '📦',
      categoryColor: json['color'] ?? json['categoryColor'] ?? '#95A5A6',
      totalAmount: parsedAmount,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transactionCount'] ?? 0,
    );
  }

  // Méthode pour créer une copie avec une couleur modifiée
  CategoryExpense copyWith({String? categoryColor}) {
    return CategoryExpense(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      totalAmount: totalAmount,
      percentage: percentage,
      transactionCount: transactionCount,
    );
  }
}

/// Modèle unifié pour TOUTES les statistiques
/// Contient toutes les données nécessaires pour tous les graphiques
class Statistics {
  final List<MonthlySummary> monthlySummary;
  final CategoryExpenses categoryExpenses;
  final BudgetStatistics budgetStatistics;

  Statistics({
    required this.monthlySummary,
    required this.categoryExpenses,
    required this.budgetStatistics,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      monthlySummary: (json['monthlySummary'] as List<dynamic>?)
              ?.map((item) => MonthlySummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      categoryExpenses: CategoryExpenses.fromJson(
        json['categoryExpenses'] as Map<String, dynamic>? ?? {},
      ),
      budgetStatistics: BudgetStatistics.fromJson(
        json['budgetStatistics'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlySummary': monthlySummary.map((item) => {
            'period': item.period,
            'totalIncome': item.totalIncome,
            'totalExpenses': item.totalExpenses,
            'balance': item.balance,
          }).toList(),
      'categoryExpenses': {
        'total': categoryExpenses.total,
        'categories': categoryExpenses.categories.map((item) => {
              'categoryId': item.categoryId,
              'categoryName': item.categoryName,
              'icon': item.categoryIcon,
              'color': item.categoryColor,
              'amount': item.totalAmount,
              'percentage': item.percentage,
            }).toList(),
      },
      'budgetStatistics': budgetStatistics.toJson(),
    };
  }
}

/// Modèle pour les dépenses par catégorie
class CategoryExpenses {
  final double total;
  final List<CategoryExpense> categories;

  CategoryExpenses({
    required this.total,
    required this.categories,
  });

  factory CategoryExpenses.fromJson(Map<String, dynamic> json) {
    return CategoryExpenses(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => CategoryExpense.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
