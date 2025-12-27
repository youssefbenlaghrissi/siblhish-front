import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';
import '../widgets/add_category_modal.dart';
import '../widgets/add_budget_modal.dart';
import '../widgets/edit_budget_modal.dart';
import '../widgets/edit_category_color_modal.dart';
import '../utils/color_utils.dart';
import '../services/auth_service.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isVisible;
  
  const ProfileScreen({super.key, this.isVisible = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            final user = provider.currentUser;
            final categories = provider.categories;
            
            // Charger les catégories et budgets quand l'écran devient visible
            if (isVisible && user != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.loadCategoriesIfNeeded();
              });
            }

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // User Info Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _UserInfoCard(user: user),
                  ),
                ),

                // Budgets Section
                SliverToBoxAdapter(
                  child: _BudgetsSection(
                    provider: provider,
                    isVisible: isVisible,
                  ),
                ),

                // Categories Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mes catégories',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddCategoryModal(),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categories[index];
                        return _CategoryCard(
                          category: category,
                          provider: provider,
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),

                // Settings Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text(
                      'Paramètres',
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
                    child: _SettingsCard(),
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

class _UserInfoCard extends StatelessWidget {
  final User? user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Utilisateur',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: AppTheme.primaryColor,
            onPressed: () {
              // Edit user info
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetsSection extends StatefulWidget {
  final BudgetProvider provider;
  final bool isVisible;

  const _BudgetsSection({
    required this.provider,
    required this.isVisible,
  });

  @override
  State<_BudgetsSection> createState() => _BudgetsSectionState();
}

class _BudgetsSectionState extends State<_BudgetsSection> {
  DateTime _selectedMonth = DateTime.now();
  String? _selectedMonthString;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _updateSelectedMonth();
    // Ne pas charger ici, attendre que l'écran soit visible
  }

  @override
  void didUpdateWidget(_BudgetsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Charger les budgets quand l'écran devient visible pour la première fois
    if (widget.isVisible && !oldWidget.isVisible && !_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible && !_hasLoaded) {
          _loadBudgets();
        }
      });
    }
  }

  void _updateSelectedMonth() {
    _selectedMonthString = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBudgets() async {
    if (!_hasLoaded) {
      _hasLoaded = true;
    }
    await widget.provider.loadBudgetsIfNeeded(month: _selectedMonthString);
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _updateSelectedMonth();
      });
      await _loadBudgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgets = widget.provider.budgets;
    final filteredBudgets = budgets.where((budget) {
      // Ignorer les budgets sans dates
      if (budget.startDate == null || budget.endDate == null) {
        return false;
      }
      final budgetStart = DateTime(budget.startDate!.year, budget.startDate!.month);
      final budgetEnd = DateTime(budget.endDate!.year, budget.endDate!.month);
      final selected = DateTime(_selectedMonth.year, _selectedMonth.month);
      return selected.isAfter(budgetStart.subtract(const Duration(days: 1))) &&
          selected.isBefore(budgetEnd.add(const Duration(days: 1)));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title "Mes Budgets"
              Expanded(
                child: Text(
                  'Mes Budgets',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Month Selector with Chevrons: "< décembre, 2025 >"
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                        _updateSelectedMonth();
                      });
                      _loadBudgets();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _selectMonth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        DateFormat('MMMM, yyyy', 'fr_FR').format(_selectedMonth),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                        _updateSelectedMonth();
                      });
                      _loadBudgets();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Budgets List
        if (widget.provider.isLoadingBudgets)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredBudgets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
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
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun budget pour ce mois',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Button "Ajouter un budget" at the bottom
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddBudgetModal(),
                    ).then((_) => _loadBudgets());
                  },
                  icon: Icon(
                    Icons.add_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'Ajouter un budget',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ...filteredBudgets.map((budget) {
                  return _BudgetCard(
                    budget: budget,
                    provider: widget.provider,
                    onUpdated: _loadBudgets,
                  );
                }).toList(),
                const SizedBox(height: 20),
                // Button "Ajouter un budget" at the bottom
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddBudgetModal(),
                    ).then((_) => _loadBudgets());
                  },
                  icon: Icon(
                    Icons.add_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'Ajouter un budget',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final BudgetProvider provider;
  final VoidCallback onUpdated;

  const _BudgetCard({
    required this.budget,
    required this.provider,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final category = provider.categories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () => Category(
        id: budget.categoryId ?? '',
        name: 'Catégorie supprimée',
        icon: '📦',
        color: '#9E9E9E',
      ),
    );
    final categoryColor = category.color ?? '#9E9E9E';
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2);
    
    final spent = budget.spent;
    final total = budget.amount;
    final percentage = budget.percentageUsed;
    
    // Déterminer le statut et la couleur
    Color statusColor;
    IconData statusIcon;
    if (percentage >= 100) {
      statusColor = Colors.red;
      statusIcon = Icons.error_rounded;
    } else if (percentage >= 80) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorUtils.parseColor(categoryColor).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorUtils.parseColor(categoryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.icon ?? '📦',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Budget Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Name and Status Icon on the same row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Status Icon aligned to the right
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Amount Spent and "sur MAD X.XX" on the same line
                Row(
                  children: [
                    Text(
                      formatter.format(spent),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'sur ${formatter.format(total)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 100
                          ? Colors.red
                          : percentage >= 80
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Percentage
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final BudgetProvider provider;

  const _CategoryCard({
    required this.category,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = category.color ?? '#999999';
    final categoryIcon = category.icon ?? '📦';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorUtils.parseColor(categoryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorUtils.parseColor(categoryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorUtils.parseColor(categoryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              categoryIcon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorUtils.parseColor(categoryColor),
              ),
            ),
          ),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: ColorUtils.parseColor(categoryColor),
              size: 20,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'color',
                child: Row(
                  children: [
                    Icon(Icons.palette_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Personnaliser la couleur'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'color') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => EditCategoryColorModal(category: category),
                );
              } else if (value == 'delete') {
                try {
                  await provider.deleteCategory(category.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Catégorie supprimée avec succès'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          _SettingItem(
            icon: Icons.language_rounded,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {},
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Activées',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.info_outline_rounded,
            title: 'À propos',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.logout_rounded,
            title: 'Déconnexion',
            subtitle: 'Se déconnecter de votre compte',
            onTap: () async {
              // Afficher une boîte de dialogue de confirmation
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Déconnexion',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Êtes-vous sûr de vouloir vous déconnecter ?',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  final provider = Provider.of<BudgetProvider>(context, listen: false);
                  
                  // Nettoyer les données du provider
                  provider.clearAllData();
                  
                  // Déconnexion Google et suppression de la session
                  await AuthService.logout();
                  
                  // Naviguer vers l'écran de connexion
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon, 
                color: isDestructive ? Colors.red : AppTheme.primaryColor, 
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

