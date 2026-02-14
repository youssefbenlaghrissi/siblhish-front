import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../widgets/custom_snackbar.dart';

class BudgetSuggestionResultsScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final double monthlyIncome;

  const BudgetSuggestionResultsScreen({
    super.key,
    required this.result,
    required this.monthlyIncome,
  });

  @override
  State<BudgetSuggestionResultsScreen> createState() => _BudgetSuggestionResultsScreenState();
}

class _BudgetSuggestionResultsScreenState extends State<BudgetSuggestionResultsScreen> {
  bool _isCreating = false;
  List<TextEditingController> _amountControllers = [];
  List<Map<String, dynamic>> _modifiedBudgets = [];
  List<bool> _isRecurringList = []; // Liste pour gérer isRecurring pour chaque budget

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final budgets = (widget.result['budgets'] as List<dynamic>?) ?? [];
    _modifiedBudgets = budgets.map((budget) => Map<String, dynamic>.from(budget)).toList();
    _amountControllers = [];
    _isRecurringList = [];
    for (int i = 0; i < _modifiedBudgets.length; i++) {
      final budget = _modifiedBudgets[i];
      final amount = (budget['amount'] as num?)?.toDouble() ?? 0.0;
      final controller = TextEditingController(text: amount.toStringAsFixed(0));
      final index = i; // Capturer l'index dans la closure
      controller.addListener(() => _onAmountChanged(index));
      _amountControllers.add(controller);
      // Initialiser isRecurring à true par défaut
      _isRecurringList.add(true);
      _modifiedBudgets[i]['isRecurring'] = true;
    }
  }

  void _onAmountChanged(int index) {
    if (index >= 0 && index < _amountControllers.length && index < _modifiedBudgets.length) {
      final controller = _amountControllers[index];
      final text = controller.text.replaceAll(RegExp(r'[^\d.]'), '');
      if (text.isNotEmpty) {
        final newAmount = double.tryParse(text) ?? 0.0;
        _modifiedBudgets[index]['amount'] = newAmount;
        // Recalculer le pourcentage
        final newPercentage = (newAmount / widget.monthlyIncome) * 100;
        _modifiedBudgets[index]['percentage'] = newPercentage;
        setState(() {}); // Mettre à jour l'affichage
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgets = _modifiedBudgets;
    final totalBudget = budgets.fold<double>(0.0, (sum, budget) => sum + ((budget['amount'] as num?)?.toDouble() ?? 0.0));
    final suggestedSavings = widget.monthlyIncome - totalBudget;
    final situation = widget.result['situation'] as String? ?? '';
    final location = widget.result['location'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Suggestions de Budget',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec résumé
            _buildHeader(context, totalBudget, suggestedSavings, situation, location),
            
            const SizedBox(height: 24),
            
            // Liste des budgets suggérés
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détail par catégorie',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...budgets.asMap().entries.map((entry) => _buildBudgetCard(entry.value, entry.key)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton d'action
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createBudgets,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Créer ces budgets',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBudgets() async {
    if (_isCreating) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Récupérer l'ID de l'utilisateur
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Vous devez être connecté pour créer des budgets');
      }

      // Récupérer le provider
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      
      // Récupérer les budgets suggérés
      final budgets = (widget.result['budgets'] as List<dynamic>?) ?? [];
      
      if (budgets.isEmpty) {
        throw Exception('Aucun budget à créer');
      }

      // Date du début du mois actuel
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0); // Dernier jour du mois
      final monthString = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Charger les budgets existants pour ce mois (uniquement si nécessaire pour vérifier les doublons)
      // On charge seulement si on veut vérifier les budgets existants
      List<String> budgetsToDelete = [];
      int replacedCount = 0;
      double previousTotalAmount = 0.0; // Total des budgets existants pour détecter changement de revenu
      
      // Utiliser les budgets modifiés par l'utilisateur
      final budgetsToUse = _modifiedBudgets;
      
      // Vérifier s'il y a des budgets existants à supprimer (charger seulement si nécessaire)
      // On charge les budgets pour vérifier les doublons
      await budgetProvider.loadBudgets(month: monthString, forceReload: true);
      
      // Récupérer tous les budgets du mois actuel
      final allBudgetsForMonth = budgetProvider.budgets.where((budget) {
        if (budget.startDate == null) return false;
        return budget.startDate!.year == now.year && 
               budget.startDate!.month == now.month;
      }).toList();
      
      // Collecter les IDs des catégories des nouvelles suggestions
      final newCategoryIds = budgetsToUse
          .map((b) => (b['categoryId'] as num?)?.toInt())
          .where((id) => id != null)
          .toSet();
      
      // Supprimer tous les budgets récurrents du mois actuel
      // (ceux créés via suggestions sont récurrents par défaut)
      // Cela permet de gérer le cas où l'utilisateur change le nombre de catégories
      for (var existingBudget in allBudgetsForMonth) {
        // Supprimer si le budget est récurrent (créé via suggestions)
        // OU si sa catégorie est dans les nouvelles suggestions (remplacement)
        if (existingBudget.isRecurring || 
            (existingBudget.categoryId != null && 
             newCategoryIds.contains(int.tryParse(existingBudget.categoryId!)))) {
          budgetsToDelete.add(existingBudget.id);
          previousTotalAmount += existingBudget.amount;
          replacedCount++;
        }
      }
      
      // Calculer le nouveau total pour détecter un changement de revenu
      final newTotalAmount = budgetsToUse.fold<double>(0.0, (sum, budget) => 
        sum + ((budget['amount'] as num?)?.toDouble() ?? 0.0));
      // Détecter un changement significatif (> 100 MAD) qui indique probablement un changement de revenu
      final hasIncomeChanged = replacedCount > 0 && 
                               previousTotalAmount > 0 && 
                               (newTotalAmount - previousTotalAmount).abs() > 100;
      
      // Supprimer les budgets existants en une seule transaction
      if (budgetsToDelete.isNotEmpty) {
        try {
          await BudgetService.deleteBudgetsBatch(budgetsToDelete);
        } catch (e) {
          // Si la suppression batch échoue, essayer de supprimer un par un (fallback)
          print('Erreur lors de la suppression batch, tentative individuelle: $e');
          for (var budgetId in budgetsToDelete) {
            try {
              await budgetProvider.deleteBudget(budgetId);
            } catch (e2) {
              // Ignorer les erreurs de suppression (peut-être déjà supprimé)
              print('Erreur lors de la suppression du budget $budgetId: $e2');
            }
          }
        }
      }
      
      // Préparer tous les budgets à créer
      List<Map<String, dynamic>> budgetsToCreate = [];
      
      for (var budgetData in budgetsToUse) {
        final categoryId = (budgetData['categoryId'] as num?)?.toInt();
        final amount = (budgetData['amount'] as num?)?.toDouble();
        
        if (categoryId == null || amount == null) {
          continue;
        }

        // Récupérer isRecurring depuis _modifiedBudgets ou utiliser la valeur par défaut
        final isRecurring = (budgetData['isRecurring'] as bool?) ?? true;

        budgetsToCreate.add({
          'userId': int.tryParse(userId) ?? userId,
          'amount': amount,
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          'categoryId': categoryId,
          'isRecurring': isRecurring, // Utiliser la valeur modifiée par l'utilisateur
        });
      }

      if (budgetsToCreate.isEmpty) {
        throw Exception('Aucun budget valide à créer');
      }

      // Créer tous les budgets en une seule transaction
      List<Budget> createdBudgets;
      try {
        createdBudgets = await BudgetService.createBudgetsBatch(budgetsToCreate);
        
        // OPTIMISATION : Recharger seulement si nécessaire
        // Si on a supprimé des budgets, on doit recharger pour avoir les données à jour
        // Sinon, on pourrait éviter le rechargement, mais il est préférable de recharger
        // pour avoir les données complètes (spent, percentageUsed, etc.) depuis le backend
        if (budgetProvider.currentUser != null) {
          // Toujours recharger avec le même paramètre de mois pour éviter de charger tous les budgets
          await budgetProvider.loadBudgets(month: monthString, forceReload: true);
          budgetProvider.notifyListeners();
        }
      } catch (e) {
        // En cas d'erreur transactionnelle, tous les budgets sont annulés
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.error(
              message: 'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          );
        }
        return; // Sortir de la fonction en cas d'erreur
      }

      if (mounted) {
        int successCount = createdBudgets.length;
        int errorCount = budgets.length - successCount;
        
        if (successCount > 0) {
          String description;
          if (replacedCount > 0) {
            if (hasIncomeChanged) {
              description = '$successCount budget(s) recalculé(s) et créé(s). $replacedCount budget(s) existant(s) remplacé(s) avec les nouveaux montants.';
            } else {
              description = '$successCount budget(s) créé(s). $replacedCount budget(s) existant(s) remplacé(s).';
            }
            if (errorCount > 0) {
              description += ' $errorCount erreur(s) rencontrée(s).';
            }
          } else {
            description = errorCount > 0
                ? '$errorCount erreur(s) rencontrée(s)'
                : 'Vos budgets ont été enregistrés';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.success(
              title: errorCount > 0
                  ? '$successCount budget(s) créé(s) avec succès'
                  : '$successCount budget(s) créé(s) avec succès',
              description: description,
            ),
          );
          
          // Attendre un peu avant de fermer pour que l'utilisateur voie le message
          await Future.delayed(const Duration(seconds: 1));
          
          // Fermer l'écran
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.error(
              message: 'Erreur: Impossible de créer les budgets. ${errorCount > 0 ? "$errorCount erreur(s)." : ""}',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Widget _buildHeader(
    BuildContext context,
    double totalBudget,
    double suggestedSavings,
    String situation,
    String location,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Revenu mensuel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenu mensuel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0).format(widget.monthlyIncome),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSituationIcon(situation),
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      situation,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Barre de progression
          _buildProgressBar(totalBudget, suggestedSavings),
          
          const SizedBox(height: 20),
          
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Budget total',
                  totalBudget,
                  AppTheme.primaryColor,
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Épargne',
                  suggestedSavings,
                  Colors.green,
                  Icons.savings_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double totalBudget, double suggestedSavings) {
    final budgetPercentage = (totalBudget / widget.monthlyIncome) * 100;
    final savingsPercentage = (suggestedSavings / widget.monthlyIncome) * 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Répartition',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${budgetPercentage.toStringAsFixed(1)}% / ${savingsPercentage.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                // Fond
                Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                ),
                // Budget
                FractionallySizedBox(
                  widthFactor: budgetPercentage / 100,
                  child: Container(
                    color: AppTheme.primaryColor,
                  ),
                ),
                // Épargne
                Positioned(
                  right: 0,
                  child: FractionallySizedBox(
                    widthFactor: savingsPercentage / 100,
                    child: Container(
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0).format(amount),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> budget, int index) {
    final categoryName = budget['categoryName'] as String? ?? '';
    final amount = (budget['amount'] as num?)?.toDouble() ?? 0.0;
    final percentage = (budget['percentage'] as num?)?.toDouble() ?? 0.0;
    final icon = budget['icon'] as String? ?? '📦';
    final colorHex = budget['color'] as String? ?? '#95A5A6';
    final color = _hexToColor(colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Icône
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Montant éditable et case à cocher récurrent
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _amountControllers[index],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    suffixText: 'MAD',
                    suffixStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 8),
              // Case à cocher pour isRecurring
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: index < _isRecurringList.length ? _isRecurringList[index] : true,
                    onChanged: (value) {
                      setState(() {
                        if (index < _isRecurringList.length) {
                          _isRecurringList[index] = value ?? true;
                          _modifiedBudgets[index]['isRecurring'] = value ?? true;
                        }
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'Récurrent',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getSituationIcon(String situation) {
    switch (situation) {
      case 'Célibataire':
        return Icons.person_outline_rounded;
      case 'En couple':
        return Icons.people_outline;
      case 'Famille':
        return Icons.family_restroom_rounded;
      case 'Étudiant':
        return Icons.school_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

