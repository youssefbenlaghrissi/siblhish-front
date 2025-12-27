import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/color_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'transaction_details_modal.dart';

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
    
    // Pour les dépenses, utiliser la catégorie de la transaction ou celle passée en paramètre
    final expenseCategory = !isIncome 
        ? (transaction as Expense).category ?? category
        : null;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TransactionDetailsModal(
            transaction: transaction,
            category: expenseCategory,
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon - flèche pour les revenus et les dépenses
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppTheme.incomeColor.withOpacity(0.1)
                  : AppTheme.expenseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIncome
                  ? AppTheme.incomeColor
                  : AppTheme.expenseColor,
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
                // Titre : catégorie avec icône pour dépenses, source pour revenus
                Row(
                  children: [
                    if (!isIncome && expenseCategory != null) ...[
                      Text(
                        expenseCategory.icon ?? '📦',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        isIncome
                            ? (transaction as Income).source ?? 'Revenu'
                            : (expenseCategory?.name ?? 'Dépense'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Date et heure
                Text(
                  _formatDateTime(date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Montant et mode de paiement alignés à droite
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Montant en haut à droite
              Text(
                CurrencyFormatter.formatWithSign(amount, isIncome: isIncome),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                ),
                textAlign: TextAlign.right,
              ),
              // Mode de paiement en bas à droite
              if (transaction.paymentMethod != null && transaction.paymentMethod.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _getPaymentMethodLabel(transaction.paymentMethod),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    // Formater la date (jour et mois seulement) et l'heure
    final dateStr = DateFormatter.formatDateWithoutYear(date);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr $timeStr';
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Espèces';
      case 'CREDIT_CARD':
        return 'Carte bancaire';
      case 'BANK_TRANSFER':
        return 'Virement';
      case 'MOBILE_PAYMENT':
        return 'Mobile';
      case 'PAYPAL':
        return 'PayPal';
      default:
        return method;
    }
  }
}

