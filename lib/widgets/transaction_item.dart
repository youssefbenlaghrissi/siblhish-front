import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class TransactionItem extends StatelessWidget {
  final dynamic transaction;
  final Category? category;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction is Income;
    final amount = transaction.amount;
    final date = transaction.date;
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2);
    final dateFormatter = DateFormat('dd MMM yyyy', 'fr');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIncome
                      ? (transaction as Income).source ?? 'Revenu'
                      : (category?.name ?? 'Dépense'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!isIncome)
                      Builder(
                        builder: (context) {
                          final cat = category;
                          if (cat == null) return const SizedBox.shrink();
                          final catColor = cat.color ?? '#999999';
                          final catIcon = cat.icon ?? '📦';
                          final parsedColor = _parseColor(catColor);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: parsedColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  catIcon,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: parsedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (!isIncome) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateFormatter.format(date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount - aligné à droite, taille réduite
          Text(
            '${isIncome ? '+' : '-'}${formatter.format(amount)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

