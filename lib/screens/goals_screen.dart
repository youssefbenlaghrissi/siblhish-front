import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/budget_provider.dart';
import '../models/goal.dart';
import '../models/category.dart' as models;
import '../theme/app_theme.dart';
import '../widgets/add_goal_modal.dart';
import '../widgets/edit_goal_modal.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/date_formatter.dart';

class GoalsScreen extends StatefulWidget {
  final bool isVisible;
  
  const GoalsScreen({super.key, this.isVisible = false});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _goalsLoaded = false;
  bool _isLoadingGoals = false;

  @override
  void initState() {
    super.initState();
    // Charger les goals si l'écran est déjà visible au démarrage
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible) {
          _reloadGoals();
        }
      });
    }
  }

  @override
  void didUpdateWidget(GoalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Charger les goals uniquement quand l'écran devient visible (lazy loading strict)
    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible) {
          _reloadGoals();
        }
      });
    }
  }

  Future<void> _loadGoalsIfNeeded() async {
    if (_isLoadingGoals) return;
    
    final provider = context.read<BudgetProvider>();
    if (!_goalsLoaded && provider.currentUser != null) {
      _isLoadingGoals = true;
      try {
        await provider.loadGoals();
        if (mounted) {
          setState(() {
            _goalsLoaded = true;
            _isLoadingGoals = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingGoals = false);
        }
      }
    }
  }

  Future<void> _reloadGoals() async {
    if (_isLoadingGoals) return;
    
    final provider = context.read<BudgetProvider>();
    if (provider.currentUser != null) {
      // Réinitialiser _goalsLoaded pour afficher le skeleton pendant le rechargement
      setState(() {
        _isLoadingGoals = true;
        _goalsLoaded = false; // Important : réinitialiser pour afficher le skeleton
      });
      
      try {
        // Recharger toujours les goals depuis le backend
        await provider.loadGoals();
        if (mounted) {
          setState(() {
            _goalsLoaded = true;
            _isLoadingGoals = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingGoals = false;
            // Garder _goalsLoaded = false en cas d'erreur pour permettre un nouveau chargement
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser AutomaticKeepAliveClientMixin pour contrôler quand l'écran est actif
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            final isLoading = _isLoadingGoals || !_goalsLoaded;
            
            // Charger les objectifs à la demande (lazy loading strict)
            // Ne charger QUE si l'écran est visible ET que les données ne sont pas déjà chargées
            if (widget.isVisible && !_goalsLoaded && !_isLoadingGoals && provider.currentUser != null && mounted) {
              // Utiliser SchedulerBinding pour charger après le premier frame
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted && widget.isVisible && !_goalsLoaded && !_isLoadingGoals) {
                  _loadGoalsIfNeeded();
                }
              });
            }
            
            // Si l'écran n'est pas visible, ne pas charger et afficher un loader
            if (!widget.isVisible || isLoading) {
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                  // Tips Card Skeleton
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 150,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 200,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Goals Header Skeleton
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Goals List Skeletons
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            index == 2 ? 20 : 12,
                          ),
                          child: const GoalCardSkeleton(),
                        );
                      },
                      childCount: 3, // Afficher 3 skeletons
                    ),
                  ),
                ],
              );
            }

            final goals = provider.goals;

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Tips Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _TipsCard(),
                  ),
                ),

                // Goals Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mes objectifs',
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
                              builder: (context) => const AddGoalModal(),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nouveau'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Goals List
                goals.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.savings_rounded,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun objectif',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Créez votre premier objectif d\'épargne',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final goal = goals[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                index == goals.length - 1 ? 20 : 12,
                              ),
                              child: _GoalCard(goal: goal)
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
                          childCount: goals.length,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<String> tips = [
    'Épargnez au moins 20% de vos revenus chaque mois',
    'Créez un fonds d\'urgence équivalent à 3-6 mois de dépenses',
    'Automatisez vos épargnes pour ne pas oublier',
    'Fixez-vous des objectifs SMART (Spécifiques, Mesurables, Atteignables)',
    'Réduisez les dépenses non essentielles',
  ];

  @override
  Widget build(BuildContext context) {
    final randomTip = tips[(DateTime.now().millisecondsSinceEpoch % tips.length)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseil du jour',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  randomTip,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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

class _GoalCard extends StatelessWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    final progress = goal.progress;
    final remaining = goal.targetAmount - goal.currentAmount;
    final isAchieved = goal.isAchieved || progress >= 1.0;
    
    // Trouver la catégorie si elle existe
    models.Category? category;
    if (goal.categoryId != null) {
      category = provider.categories.firstWhere(
        (cat) => cat.id == goal.categoryId,
        orElse: () => models.Category(
          id: goal.categoryId!,
          name: 'Catégorie inconnue',
          icon: '📦',
          color: '#9E9E9E',
        ),
      );
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _parseColor(category.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _parseColor(category.color).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.icon ?? '📦',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: _parseColor(category.color),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            goal.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (goal.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Atteint',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatter.format(goal.currentAmount),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                formatter.format(goal.targetAmount),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}% complété',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (!isAchieved)
                Text(
                  '${formatter.format(remaining)} restant',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Objectif: ${DateFormat('dd MMM yyyy', 'fr').format(goal.targetDate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Icônes modifier et supprimer à droite (seulement pour les objectifs non atteints)
                if (!isAchieved)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        color: AppTheme.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => EditGoalModal(goal: goal),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        color: AppTheme.expenseColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showDeleteConfirmationDialog(context, goal, provider),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Ligne d'actions pour les objectifs atteints
          if (isAchieved && goal.achievedDate != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Atteint le ${DateFormatter.formatDate(goal.achievedDate!)} à ${DateFormat('HH:mm', 'fr').format(goal.achievedDate!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 20),
                  color: AppTheme.expenseColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeleteConfirmationDialog(context, goal, provider),
                ),
              ],
            )
          else if (!isAchieved)
            // Ligne avec boutons "Ajouter" et "Marquer atteint" centrés
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Add amount to goal
                    _showAddAmountDialog(context, goal, provider);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ajouter'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // Mark goal as achieved
                    _showAchieveConfirmationDialog(context, goal, provider);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Marquer atteint'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showAddAmountDialog(BuildContext context, Goal goal, BudgetProvider provider) {
    final amountController = TextEditingController();
    bool isAdding = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'Ajouter à l\'objectif',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  enabled: !isAdding,
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    prefixText: 'MAD ',
                  ),
                  onChanged: (value) {
                    // Effacer l'erreur quand l'utilisateur modifie le montant
                    if (errorMessage != null) {
                      setDialogState(() {
                        errorMessage = null;
                      });
                    }
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isAdding ? null : () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isAdding ? null : () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    // Vérifier que le montant à ajouter ne dépasse pas le montant cible
                    final remainingAmount = goal.targetAmount - goal.currentAmount;
                    if (amount > remainingAmount) {
                      setDialogState(() {
                        errorMessage = 'Le montant à ajouter (${amount.toStringAsFixed(2)} MAD) dépasse le montant restant nécessaire (${remainingAmount.toStringAsFixed(2)} MAD) pour atteindre l\'objectif.';
                      });
                      return;
                    }
                    
                    setDialogState(() {
                      isAdding = true;
                      errorMessage = null; // Effacer l'erreur précédente
                    });
                    try {
                      // Utiliser addAmountToGoal au lieu de updateGoal pour être cohérent avec l'API
                      await provider.addAmountToGoal(goal.id, amount);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar.success(
                            title: 'Montant ajouté avec succès',
                            description: 'Le montant a été ajouté à votre objectif',
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setDialogState(() {
                          isAdding = false;
                          errorMessage = 'Erreur: ${e.toString()}';
                        });
                      }
                    }
                  } else {
                    setDialogState(() {
                      errorMessage = 'Veuillez entrer un montant valide';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Goal goal, BudgetProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteConfirmationDialog(
        goal: goal,
        provider: provider,
      ),
    );
  }

  void _showAchieveConfirmationDialog(BuildContext context, Goal goal, BudgetProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AchieveConfirmationDialog(
        goal: goal,
        provider: provider,
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final Goal goal;
  final BudgetProvider provider;

  const _DeleteConfirmationDialog({
    required this.goal,
    required this.provider,
  });

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  bool _isDeleting = false;

  Future<void> _deleteGoal() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.provider.deleteGoal(widget.goal.id);
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Objectif supprimé avec succès',
            description: 'L\'objectif a été supprimé',
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Supprimer l\'objectif',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: _isDeleting
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Suppression en cours...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            )
          : Text(
              'Êtes-vous sûr de vouloir supprimer l\'objectif "${widget.goal.name}" ?',
              style: GoogleFonts.poppins(),
            ),
      actions: _isDeleting
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: _deleteGoal,
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
    );
  }
}

class _AchieveConfirmationDialog extends StatefulWidget {
  final Goal goal;
  final BudgetProvider provider;

  const _AchieveConfirmationDialog({
    required this.goal,
    required this.provider,
  });

  @override
  State<_AchieveConfirmationDialog> createState() => _AchieveConfirmationDialogState();
}

class _AchieveConfirmationDialogState extends State<_AchieveConfirmationDialog> {
  bool _isAchieving = false;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Préserver l'heure existante lors du changement de date
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _achieveGoal() async {
    setState(() {
      _isAchieving = true;
    });

    try {
      await widget.provider.achieveGoal(
        widget.goal.id,
        achievedDate: _selectedDateTime,
      );
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Objectif marqué comme atteint',
            description: 'L\'objectif "${widget.goal.name}" a été marqué comme atteint',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAchieving = false;
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

  @override
  Widget build(BuildContext context) {
    // Dialogue de confirmation avec sélecteur de date/heure
    final dateFormatter = DateFormat('dd MMMM yyyy', 'fr');
    final timeFormatter = DateFormat('HH:mm', 'fr');

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Confirmer l\'atteinte',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: _isAchieving
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Marquage en cours...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marquer cet objectif comme atteint ?',
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Date et heure d\'atteinte :',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dateFormatter.format(_selectedDateTime),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time
                  InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              timeFormatter.format(_selectedDateTime),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      actions: _isAchieving
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: _achieveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirmer',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
    );
  }
}

