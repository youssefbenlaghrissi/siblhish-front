import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_item.dart';
import '../widgets/add_transaction_modal.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            final balance = provider.balance;
            final userName =
                provider.currentUser?.firstName ?? 'Utilisateur';
            DateTime _getTransactionDate(dynamic t) {
              if (t is Expense) return t.date;
              if (t is Income) return t.date;
              return DateTime.fromMillisecondsSinceEpoch(0);
            }

            final recentTransactions = [
              ...provider.expenses.take(5),
              ...provider.incomes.take(5),
            ]..sort((a, b) {
                final dateA = _getTransactionDate(a);
                final dateB = _getTransactionDate(b);
                return dateB.compareTo(dateA);
              });

            return CustomScrollView(
              slivers: [
                // Top bar (greeting + notification)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.2),
                                    AppTheme.primaryColor.withOpacity(0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monetization_on_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Bonjour $userName',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimary.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color: AppTheme.textPrimary,
                              size: 24,
                            ),
                            onPressed: () {
                              // TODO: open notifications page or modal
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Balance Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _BalanceCard(balance: balance),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: _QuickActions(),
                  ),
                ),

                // Recent Transactions Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions récentes',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Voir tout',
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                recentTransactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(60),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_rounded,
                                    size: 56,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Aucune transaction',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Commencez à enregistrer vos revenus et dépenses',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = recentTransactions[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                index == recentTransactions.length - 1 ? 20 : 10,
                              ),
                              child: TransactionItem(
                                transaction: transaction,
                                category: transaction is Expense
                                    ? provider.categories.firstWhere(
                                        (Category c) =>
                                            c.id == transaction.categoryId,
                                        orElse: () => Category(
                                          id: '',
                                          name: 'Autre',
                                          icon: '📦',
                                          color: '#999999',
                                        ),
                                      )
                                    : null,
                              )
                                  .animate()
                                  .fadeIn(
                                    duration: 300.ms,
                                    delay: (index * 50).ms,
                                  )
                                  .slideX(
                                    begin: 0.2,
                                    end: 0,
                                    duration: 300.ms,
                                    delay: (index * 50).ms,
                                  ),
                            );
                          },
                          childCount: recentTransactions.length,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTransactionModal(),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            'Ajouter',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
        ),
      )
          .animate()
          .scale(delay: 500.ms, duration: 400.ms, begin: const Offset(0.8, 0.8))
          .fadeIn(delay: 500.ms),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2);
    final provider = context.read<BudgetProvider>();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.balanceCardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde actuel',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(balance),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Revenus',
                  amount: provider.totalIncome,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Dépenses',
                  amount: provider.totalExpenses,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color.withOpacity(0.95)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          formatter.format(amount),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Revenu',
            color: AppTheme.incomeColor,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddTransactionModal(isIncome: true),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.remove_circle_outline_rounded,
            label: 'Dépense',
            color: AppTheme.expenseColor,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddTransactionModal(isIncome: false),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(delay: 100.ms, begin: const Offset(0.95, 0.95));
  }
}


