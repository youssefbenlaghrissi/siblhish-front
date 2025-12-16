import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/add_category_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            final user = provider.currentUser;
            final categories = provider.categories;

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

                // Monthly Salary Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MonthlySalaryCard(user: user, provider: provider),
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.type ?? 'EMPLOYEE',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
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

class _MonthlySalaryCard extends StatelessWidget {
  final User? user;
  final BudgetProvider provider;

  const _MonthlySalaryCard({
    required this.user,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Salaire mensuel',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: AppTheme.primaryColor,
                onPressed: () {
                  _showSalaryDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.monthlySalary != null
                ? formatter.format(user!.monthlySalary)
                : 'Non défini',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: user?.monthlySalary != null
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryDialog(BuildContext context) {
    final salaryController = TextEditingController(
      text: user?.monthlySalary?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Modifier le salaire mensuel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: salaryController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Salaire mensuel',
            prefixText: 'MAD ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final salary = double.tryParse(salaryController.text);
              if (salary != null && salary >= 0) {
                try {
                  final updatedUser = User(
                    id: user!.id,
                    firstName: user!.firstName,
                    lastName: user!.lastName,
                    email: user!.email,
                    password: user!.password,
                    type: user!.type,
                    language: user!.language,
                    monthlySalary: salary,
                  );
                  await provider.updateUser(updatedUser);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Salaire mis à jour avec succès'),
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
            child: const Text('Enregistrer'),
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
        color: _parseColor(categoryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _parseColor(categoryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _parseColor(categoryColor).withOpacity(0.2),
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
                color: _parseColor(categoryColor),
              ),
            ),
          ),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: _parseColor(categoryColor),
              size: 20,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Modifier'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
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
            onTap: () {},
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.backup_rounded,
            title: 'Sauvegarde',
            subtitle: 'Automatique',
            onTap: () {},
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.help_outline_rounded,
            title: 'Aide et support',
            subtitle: 'FAQ et contact',
            onTap: () {},
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
            onTap: () {
              // TODO: Implémenter la déconnexion après OAuth2
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Déconnexion à implémenter avec OAuth2'),
                  backgroundColor: Colors.orange,
                ),
              );
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

