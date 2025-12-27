import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/scheduled_payment.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../providers/budget_provider.dart';
import 'edit_scheduled_payment_modal.dart';
import 'custom_snackbar.dart';

class ScheduledPaymentDetailsModal extends StatefulWidget {
  final ScheduledPayment payment;
  final Category? category;

  const ScheduledPaymentDetailsModal({
    super.key,
    required this.payment,
    this.category,
  });

  @override
  State<ScheduledPaymentDetailsModal> createState() => _ScheduledPaymentDetailsModalState();
}

class _ScheduledPaymentDetailsModalState extends State<ScheduledPaymentDetailsModal> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final category = widget.category;
    final amount = payment.amount;
    final dueDate = payment.dueDate;
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2);
    final dateFormatter = DateFormat('dd MMMM yyyy', 'fr');
    final timeFormatter = DateFormat('HH:mm', 'fr');
    
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0 && !payment.isPaid;
    final isDueSoon = daysUntilDue <= 3 && daysUntilDue >= 0 && !payment.isPaid;
    final isPaid = payment.isPaid;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Détails du paiement planifié',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                        colors: isPaid
                            ? [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ]
                            : isOverdue
                                ? [
                                    Colors.red.withOpacity(0.1),
                                    Colors.red.withOpacity(0.05),
                                  ]
                                : isDueSoon
                                    ? [
                                        Colors.orange.withOpacity(0.1),
                                        Colors.orange.withOpacity(0.05),
                                      ]
                                    : [
                                        _parseColor(category?.color).withOpacity(0.1),
                                        _parseColor(category?.color).withOpacity(0.05),
                                      ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPaid
                            ? Colors.green.withOpacity(0.2)
                            : isOverdue
                                ? Colors.red.withOpacity(0.2)
                                : isDueSoon
                                    ? Colors.orange.withOpacity(0.2)
                                    : _parseColor(category?.color).withOpacity(0.2),
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
                            color: isPaid
                                ? Colors.green.withOpacity(0.15)
                                : _parseColor(category?.color).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              category?.icon ?? '📦',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Amount
                        Text(
                          formatter.format(amount),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.green
                                : isOverdue
                                    ? Colors.red
                                    : isDueSoon
                                        ? Colors.orange
                                        : _parseColor(category?.color),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.withOpacity(0.15)
                                : isOverdue
                                    ? Colors.red.withOpacity(0.15)
                                    : isDueSoon
                                        ? Colors.orange.withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPaid
                                ? 'Payé'
                                : isOverdue
                                    ? 'En retard'
                                    : isDueSoon
                                        ? 'Bientôt dû'
                                        : 'Planifié',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPaid
                                  ? Colors.green
                                  : isOverdue
                                      ? Colors.red
                                      : isDueSoon
                                          ? Colors.orange
                                          : Colors.grey[700],
                            ),
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

                  // Name
                  _DetailRow(
                    icon: Icons.label_rounded,
                    label: 'Nom',
                    value: Text(
                      payment.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),

                  // Category
                  if (category != null)
                    _DetailRow(
                      icon: Icons.category_rounded,
                      label: 'Catégorie',
                      value: Row(
                        children: [
                          Text(
                            category?.icon ?? '📦',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category?.name ?? 'Catégorie',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Due Date
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date d\'échéance',
                    value: Text(
                      dateFormatter.format(dueDate),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Time
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Heure',
                    value: Text(
                      timeFormatter.format(dueDate),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Days until due
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Jours restants',
                    value: Text(
                      isPaid
                          ? 'Payé'
                          : isOverdue
                              ? '${-daysUntilDue} jour${-daysUntilDue > 1 ? 's' : ''} de retard'
                              : '$daysUntilDue jour${daysUntilDue > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: isPaid
                            ? Colors.green
                            : isOverdue
                                ? Colors.red
                                : isDueSoon
                                    ? Colors.orange
                                    : AppTheme.textPrimary,
                        fontWeight: isOverdue || isDueSoon ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Beneficiary
                  if (payment.beneficiary != null)
                    _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'Bénéficiaire',
                      value: Text(
                        payment.beneficiary!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),

                  // Payment Method
                  _DetailRow(
                    icon: Icons.payment_rounded,
                    label: 'Méthode de paiement',
                    value: Text(
                      _getPaymentMethodLabel(payment.paymentMethod),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Recurring
                  _DetailRow(
                    icon: Icons.repeat_rounded,
                    label: 'Récurrent',
                    value: Text(
                      payment.isRecurring ? 'Oui' : 'Non',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Recurrence Frequency
                  if (payment.isRecurring && payment.recurrenceFrequency != null)
                    _DetailRow(
                      icon: Icons.repeat_one_rounded,
                      label: 'Fréquence',
                      value: Text(
                        _getRecurrenceFrequencyLabel(payment.recurrenceFrequency!),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                  // Notification Option
                  _DetailRow(
                    icon: Icons.notifications_rounded,
                    label: 'Rappel',
                    value: Text(
                      _getNotificationOptionLabel(payment.notificationOption),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons (masqués si payé)
                  if (!isPaid)
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
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Supprimer le paiement planifié',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce paiement planifié ?',
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
        await provider.deleteScheduledPayment(widget.payment.id);
        
        if (mounted) {
          Navigator.pop(context); // Fermer le modal de détails
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.success(
              title: 'Paiement planifié supprimé avec succès',
              description: 'Le paiement a été supprimé',
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
    Navigator.pop(context); // Fermer le modal de détails
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditScheduledPaymentModal(
        payment: widget.payment,
        category: widget.category,
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Espèces';
      case 'CREDIT_CARD':
        return 'Carte bancaire';
      case 'BANK_TRANSFER':
        return 'Virement';
      case 'MOBILE_PAYMENT':
        return 'Mobile';
      default:
        return method;
    }
  }

  String _getRecurrenceFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'DAILY':
        return 'Quotidien';
      case 'WEEKLY':
        return 'Hebdomadaire';
      case 'MONTHLY':
        return 'Mensuel';
      case 'YEARLY':
        return 'Annuel';
      default:
        return frequency;
    }
  }

  String _getNotificationOptionLabel(String option) {
    switch (option) {
      case 'NONE':
        return 'Aucun';
      case 'ON_DUE_DATE':
        return 'À la date d\'échéance';
      case 'ONE_DAY_BEFORE':
        return '1 jour avant';
      case 'THREE_DAYS_BEFORE':
        return '3 jours avant';
      default:
        return option;
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return AppTheme.expenseColor;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.expenseColor;
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
                value is Text
                    ? value
                    : value,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

