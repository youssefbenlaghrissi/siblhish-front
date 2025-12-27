import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../providers/budget_provider.dart';
import 'edit_transaction_modal.dart';
import 'custom_snackbar.dart';

class TransactionDetailsModal extends StatefulWidget {
  final dynamic transaction;
  final Category? category;

  const TransactionDetailsModal({
    super.key,
    required this.transaction,
    this.category,
  });

  @override
  State<TransactionDetailsModal> createState() => _TransactionDetailsModalState();
}

class _TransactionDetailsModalState extends State<TransactionDetailsModal> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final category = widget.category;
    final isIncome = transaction is Income;
    final amount = transaction.amount;
    final date = transaction.date;
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2);
    final dateFormatter = DateFormat('dd MMMM yyyy', 'fr');
    final timeFormatter = DateFormat('HH:mm', 'fr');
    
    // Pour les dépenses, utiliser la catégorie de la transaction ou celle passée en paramètre
    final expenseCategory = !isIncome 
        ? (transaction as Expense).category ?? category
        : null;
    
    final expense = !isIncome ? transaction as Expense : null;
    final income = isIncome ? transaction as Income : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isIncome ? 'Détails du revenu' : 'Détails de la dépense',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isIncome
                            ? [
                                AppTheme.incomeColor.withOpacity(0.1),
                                AppTheme.incomeColor.withOpacity(0.05),
                              ]
                            : [
                                (expenseCategory?.color != null
                                    ? _parseColor(expenseCategory!.color!)
                                    : AppTheme.expenseColor).withOpacity(0.1),
                                (expenseCategory?.color != null
                                    ? _parseColor(expenseCategory!.color!)
                                    : AppTheme.expenseColor).withOpacity(0.05),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isIncome
                            ? AppTheme.incomeColor.withOpacity(0.2)
                            : (expenseCategory?.color != null
                                ? _parseColor(expenseCategory!.color!)
                                : AppTheme.expenseColor).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? AppTheme.incomeColor.withOpacity(0.15)
                                : (expenseCategory?.color != null
                                    ? _parseColor(expenseCategory!.color!)
                                        .withOpacity(0.15)
                                    : AppTheme.expenseColor.withOpacity(0.15)),
                            shape: BoxShape.circle,
                          ),
                          child: isIncome
                              ? Icon(
                                  Icons.arrow_downward_rounded,
                                  color: AppTheme.incomeColor,
                                  size: 32,
                                )
                              : Center(
                                  child: Text(
                                    expenseCategory?.icon ?? '📦',
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Amount
                        Text(
                          '${isIncome ? '+' : '-'}${formatter.format(amount)}',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isIncome
                                ? AppTheme.incomeColor
                                : (expenseCategory?.color != null
                                    ? _parseColor(expenseCategory!.color!)
                                    : AppTheme.expenseColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Details Section
                  Text(
                    'Informations',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category (for expenses) or Source (for income)
                  if (!isIncome && expenseCategory != null)
                    _DetailRow(
                      icon: Icons.category_rounded,
                      label: 'Catégorie',
                      value: Row(
                        children: [
                          Text(
                            expenseCategory.icon ?? '📦',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            expenseCategory.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isIncome && income?.source != null)
                    _DetailRow(
                      icon: Icons.source_rounded,
                      label: 'Source',
                      value: Text(
                        income!.source!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                  // Date
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: Text(
                      dateFormatter.format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),

                  // Time
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Heure',
                    value: Text(
                      timeFormatter.format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),

                  // Payment Method
                  _DetailRow(
                    icon: Icons.payment_rounded,
                    label: 'Méthode de paiement',
                    value: Text(
                      _getPaymentMethodLabel(transaction.paymentMethod),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),

                  // Description
                  if (expense?.description != null || income?.description != null)
                    _DetailRow(
                      icon: Icons.description_rounded,
                      label: 'Description',
                      value: Text(
                        expense?.description ?? income?.description ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                  // Location (for expenses)
                  if (!isIncome && expense?.location != null)
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Lieu',
                      value: Text(
                        expense!.location!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : () => _handleDelete(context),
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                  ),
                                )
                              : const Icon(Icons.delete_outline_rounded),
                          label: Text(_isDeleting ? 'Suppression...' : 'Supprimer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isDeleting ? null : () => _handleEdit(context),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Modifier'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    final isIncome = widget.transaction is Income;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Supprimer la transaction',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette ${isIncome ? 'revenu' : 'dépense'} ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        if (isIncome) {
          await provider.deleteIncome(widget.transaction.id);
        } else {
          await provider.deleteExpense(widget.transaction.id);
        }
        
        if (mounted) {
          Navigator.pop(context); // Fermer le modal de détails
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.success(
              title: '${isIncome ? 'Revenu' : 'Dépense'} supprimé${isIncome ? '' : 'e'} avec succès',
              description: 'La transaction a été supprimée',
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleEdit(BuildContext context) {
    final isIncome = widget.transaction is Income;
    final expenseCategory = !isIncome 
        ? (widget.transaction as Expense).category ?? widget.category
        : null;
    
    Navigator.pop(context); // Fermer le modal de détails
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTransactionModal(
        transaction: widget.transaction,
        category: expenseCategory,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

