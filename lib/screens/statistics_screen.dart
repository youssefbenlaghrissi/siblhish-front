import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/statistics/bar_chart_widget.dart';
import '../widgets/statistics/pie_chart_widget.dart';
import '../widgets/statistics/select_cards_modal.dart';
import '../widgets/statistics/statistics_card_widgets.dart';
import '../widgets/statistics/budget_vs_actual_chart_widget.dart';
import '../widgets/statistics/top_budget_categories_card_widget.dart';
import '../widgets/statistics/budget_efficiency_card_widget.dart';
import '../widgets/statistics/budget_distribution_pie_chart_widget.dart';
import '../models/statistics_card.dart';
import '../services/favorite_service.dart';
import '../widgets/custom_snackbar.dart';

class StatisticsScreen extends StatefulWidget {
  final bool isVisible;
  
  const StatisticsScreen({super.key, this.isVisible = false});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _statisticsDataLoaded = false;
  bool _isLoadingStatistics = false;
  bool _isLoadingCharts = false;
  List<Map<String, dynamic>> _cardFavorites = [];
  String _selectedPeriod = 'monthly'; // Période par défaut : mensuel
  DateTime _selectedDate = DateTime.now(); // Date sélectionnée pour la navigation

  @override
  void initState() {
    super.initState();
    // Si l'écran est visible au démarrage, charger les données
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible && !_statisticsDataLoaded && !_isLoadingStatistics) {
          _loadStatisticsDataIfNeeded();
        }
      });
    }
  }

  @override
  void didUpdateWidget(StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'écran vient de devenir visible, recharger les données
    if (widget.isVisible && !oldWidget.isVisible) {
      // Réinitialiser les flags pour forcer le rechargement
      _statisticsDataLoaded = false;
      _isLoadingCharts = false;
      _cardFavorites = []; // Réinitialiser les favoris
      if (!_isLoadingStatistics && mounted) {
        // Utiliser addPostFrameCallback pour éviter d'appeler setState pendant le build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isLoadingStatistics && !_statisticsDataLoaded) {
            _loadStatisticsDataIfNeeded();
          }
        });
      }
    }
  }

  Future<void> _loadStatisticsDataIfNeeded() async {
    // Éviter les appels multiples
    if (_isLoadingStatistics) return;
    
    final provider = context.read<BudgetProvider>();
    if (!_statisticsDataLoaded && provider.currentUser != null) {
      _isLoadingStatistics = true;
      try {
        // Utiliser les favoris déjà chargés dans le provider
        _cardFavorites = provider.cardFavorites;
        
        // Obtenir les cartes sélectionnées pour charger les données nécessaires
        final selectedCardIds = provider.statisticsCardsPreferences;
        
        // Charger les données nécessaires pour les cartes sélectionnées
        await provider.loadStatisticsData(requiredCardIds: selectedCardIds);
        
        // Charger les graphiques sélectionnés
        await _loadChartsDataIfNeeded(provider);
        
        if (mounted) {
          setState(() {
            _statisticsDataLoaded = true;
            _isLoadingStatistics = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingStatistics = false);
        }
      }
    }
  }

  Future<void> _loadChartsDataIfNeeded(BudgetProvider provider) async {
    if (_isLoadingCharts) return;
    
    _isLoadingCharts = true;
    setState(() {}); // Mettre à jour l'UI pour afficher les skeletons
    
    try {
      // Calculer startDate et endDate selon la période et la date sélectionnée
      final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
      final startDate = dateRange['startDate']!;
      final endDate = dateRange['endDate']!;
      
      // Charger TOUTES les statistiques en une seule requête optimisée
      // Réduit les appels API de 6 à 1 pour améliorer les performances
      await provider.loadAllStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCharts = false;
        });
      }
    }
  }

  Future<void> _onPeriodChanged(String period, BudgetProvider provider) async {
    if (_selectedPeriod == period) return;
    
    setState(() {
      _selectedPeriod = period;
      // Réinitialiser la date à aujourd'hui lors du changement de période
      _selectedDate = DateTime.now();
    });
    
    // Recharger tous les graphiques sélectionnés avec la nouvelle période
    await _loadChartsDataIfNeeded(provider);
  }

  // Calculer startDate et endDate selon la période et la date sélectionnée
  Map<String, DateTime> _calculateDateRange(String period, DateTime selectedDate) {
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'daily':
        // Pour daily : afficher uniquement le jour sélectionné
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        break;
      
      case 'weekly':
        // Pour weekly : afficher la semaine de la date sélectionnée (lundi à dimanche)
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = startDate.add(const Duration(days: 6));
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        break;
      
      case 'monthly':
        // Pour monthly : afficher le mois de la date sélectionnée (1er au dernier jour)
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        break;
      
      case '3months':
        // Pour 3months : afficher les 3 derniers mois à partir de la date sélectionnée
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        startDate = DateTime(selectedDate.year, selectedDate.month - 2, 1);
        break;
      
      case '6months':
        // Pour 6months : afficher les 6 derniers mois à partir de la date sélectionnée
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        startDate = DateTime(selectedDate.year, selectedDate.month - 5, 1);
        break;
      
      default:
        // Par défaut : mois actuel
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  void _showPeriodMenu(BuildContext context) {
    final periods = [
      {'value': 'daily', 'label': 'Quotidien'},
      {'value': 'weekly', 'label': 'Hebdomadaire'},
      {'value': 'monthly', 'label': 'Mensuel'},
      {'value': '3months', 'label': '3 Mois'},
      {'value': '6months', 'label': '6 Mois'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Sélectionner une période',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Divider(),
            ...periods.map((period) {
              final isSelected = _selectedPeriod == period['value'];
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                ),
                title: Text(
                  period['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (period['value'] != _selectedPeriod) {
                    _onPeriodChanged(period['value']!, context.read<BudgetProvider>());
                  }
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelectCards() async {
    final provider = context.read<BudgetProvider>();
    final selectedCards = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectCardsModal(
        selectedCardIds: provider.statisticsCardsPreferences,
      ),
    );

    if (selectedCards != null && selectedCards.isNotEmpty) {
      // Afficher un spinner pendant la mise à jour
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      try {
        await provider.updateStatisticsCardsPreferences(selectedCards);
        
        // Fermer le spinner
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Recharger les favoris depuis le provider (qui les mettra à jour)
        // Le provider mettra à jour les favoris après updateStatisticsCardsPreferences
        _cardFavorites = provider.cardFavorites;
        
        // Si les favoris ne sont pas encore chargés, les charger maintenant
        if (_cardFavorites.isEmpty && provider.currentUser != null) {
          try {
            _cardFavorites = await FavoriteService.getFavoritesByType(
              provider.currentUser!.id,
              'CARD',
            );
            // Mettre à jour le provider avec les nouveaux favoris
            // Note: Le provider devrait normalement les avoir déjà après updateStatisticsCardsPreferences
          } catch (e) {
          }
        }
        
        // Recharger les données des graphiques seulement si les cartes ont changé
        // Comparer les nouvelles cartes avec les anciennes pour éviter les rechargements inutiles
        final previousCards = provider.statisticsCardsPreferences;
        final cardsChanged = selectedCards.length != previousCards.length ||
            !selectedCards.every((id) => previousCards.contains(id)) ||
            !previousCards.every((id) => selectedCards.contains(id));
        
        if (cardsChanged) {
          await _loadChartsDataIfNeeded(provider);
        } else {
        }
        
        if (mounted) {
          setState(() {}); // Rafraîchir l'UI
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.success(
              title: 'Cartes mises à jour avec succès',
              description: 'Vos préférences ont été enregistrées',
            ),
          );
        }
      } catch (e) {
        // Fermer le spinner en cas d'erreur
        if (mounted) {
          Navigator.of(context).pop(); // Fermer le spinner
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

  Widget _buildCardWidget(StatisticsCardType cardType, BudgetProvider provider) {
    switch (cardType) {
      case StatisticsCardType.barChart:
        // Graphique ID 1 : Revenus vs Dépenses
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _isLoadingCharts
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : provider.monthlySummary.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune donnée disponible',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : BarChartWidget(monthlyData: provider.monthlySummary),
        );

      case StatisticsCardType.pieChart:
        final categoryData = provider.categoryExpenses;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _isLoadingCharts
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : PieChartWidget(
                  categoryData: categoryData,
                  period: _selectedPeriod,
                ),
        );

      case StatisticsCardType.savingsCard:
        // Utiliser le champ balance directement depuis l'API (calculé côté backend)
        // Pour la période sélectionnée, sommer les balances de toutes les périodes
        double savings = 0.0;
        if (provider.monthlySummary.isNotEmpty) {
          // Somme de toutes les balances pour la période sélectionnée
          savings = provider.monthlySummary.fold<double>(
            0.0,
            (sum, item) => sum + item.balance,
          );
        }
        // Si pas de données, afficher 0 (les données seront chargées si nécessaire)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SavingsCardWidget(
            savings: savings,
            period: _selectedPeriod,
          ),
        );

      case StatisticsCardType.averageExpenseCard:
        // Calculer la moyenne des dépenses pour la période sélectionnée
        // Utiliser les données du monthlySummary qui sont filtrées par période
        double averageExpense = 0.0;
        int numberOfPeriods = 0;
        if (provider.monthlySummary.isNotEmpty) {
          // Calculer le total des dépenses
          final totalExpenses = provider.monthlySummary.fold<double>(
            0.0,
            (sum, item) => sum + item.totalExpenses,
          );
          
          // Calculer startDate et endDate pour déterminer le nombre réel de périodes
          final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
          final startDate = dateRange['startDate']!;
          final endDate = dateRange['endDate']!;
          
          // Calculer le nombre de périodes selon la période sélectionnée
          switch (_selectedPeriod) {
            case 'daily':
              // Pour daily : moyenne par jour (1 jour dans la période)
              numberOfPeriods = 1;
              averageExpense = totalExpenses;
              break;
              
            case 'weekly':
              // Pour weekly : moyenne par jour dans la semaine (7 jours)
              numberOfPeriods = endDate.difference(startDate).inDays + 1;
              averageExpense = numberOfPeriods > 0 ? totalExpenses / numberOfPeriods : 0.0;
              break;
              
            case 'monthly':
              // Pour monthly : moyenne par jour dans le mois
              numberOfPeriods = endDate.difference(startDate).inDays + 1;
              averageExpense = numberOfPeriods > 0 ? totalExpenses / numberOfPeriods : 0.0;
              break;
              
            case '3months':
              // Pour 3months : moyenne par mois
              // Calculer le nombre réel de mois entre startDate et endDate
              final monthsDiff = (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month) + 1;
              numberOfPeriods = monthsDiff.clamp(1, 3); // Au minimum 1, au maximum 3
              averageExpense = numberOfPeriods > 0 ? totalExpenses / numberOfPeriods : 0.0;
              break;
              
            case '6months':
              // Pour 6months : moyenne par mois
              // Calculer le nombre réel de mois entre startDate et endDate
              final monthsDiff = (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month) + 1;
              numberOfPeriods = monthsDiff.clamp(1, 6); // Au minimum 1, au maximum 6
              averageExpense = numberOfPeriods > 0 ? totalExpenses / numberOfPeriods : 0.0;
              break;
              
            default:
              // Par défaut : utiliser le nombre réel de périodes avec données
              numberOfPeriods = provider.monthlySummary.length;
              averageExpense = numberOfPeriods > 0 ? totalExpenses / numberOfPeriods : 0.0;
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: AverageExpenseCardWidget(
            averageExpense: averageExpense,
            period: _selectedPeriod,
            numberOfPeriods: numberOfPeriods,
            selectedDate: _selectedDate,
          ),
        );

      // Carte "Dépense la Plus Élevée" supprimée

      case StatisticsCardType.averageIncomeCard:
        // Calculer la moyenne des revenus pour la période sélectionnée
        // Utiliser les données du monthlySummary qui sont filtrées par période
        double averageIncome = 0.0;
        int numberOfPeriods = 0;
        if (provider.monthlySummary.isNotEmpty) {
          // Calculer le total des revenus
          final totalIncome = provider.monthlySummary.fold<double>(
            0.0,
            (sum, item) => sum + item.totalIncome,
          );
          
          // Calculer startDate et endDate pour déterminer le nombre réel de périodes
          final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
          final startDate = dateRange['startDate']!;
          final endDate = dateRange['endDate']!;
          
          // Calculer le nombre de périodes selon la période sélectionnée
          switch (_selectedPeriod) {
            case 'daily':
              // Pour daily : moyenne par jour (1 jour dans la période)
              numberOfPeriods = 1;
              averageIncome = totalIncome;
              break;
              
            case 'weekly':
              // Pour weekly : moyenne par jour dans la semaine (7 jours)
              numberOfPeriods = endDate.difference(startDate).inDays + 1;
              averageIncome = numberOfPeriods > 0 ? totalIncome / numberOfPeriods : 0.0;
              break;
              
            case 'monthly':
              // Pour monthly : moyenne par jour dans le mois
              numberOfPeriods = endDate.difference(startDate).inDays + 1;
              averageIncome = numberOfPeriods > 0 ? totalIncome / numberOfPeriods : 0.0;
              break;
              
            case '3months':
              // Pour 3months : moyenne par mois
              // Calculer le nombre réel de mois entre startDate et endDate
              final monthsDiff = (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month) + 1;
              numberOfPeriods = monthsDiff.clamp(1, 3); // Au minimum 1, au maximum 3
              averageIncome = numberOfPeriods > 0 ? totalIncome / numberOfPeriods : 0.0;
              break;
              
            case '6months':
              // Pour 6months : moyenne par mois
              // Calculer le nombre réel de mois entre startDate et endDate
              final monthsDiff = (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month) + 1;
              numberOfPeriods = monthsDiff.clamp(1, 6); // Au minimum 1, au maximum 6
              averageIncome = numberOfPeriods > 0 ? totalIncome / numberOfPeriods : 0.0;
              break;
              
            default:
              // Par défaut : utiliser le nombre réel de périodes avec données
              numberOfPeriods = provider.monthlySummary.length;
              averageIncome = numberOfPeriods > 0 ? totalIncome / numberOfPeriods : 0.0;
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: AverageIncomeCardWidget(
            averageIncome: averageIncome,
            period: _selectedPeriod,
            numberOfPeriods: numberOfPeriods,
            selectedDate: _selectedDate,
          ),
        );

      case StatisticsCardType.transactionCountCard:
        // Calculer startDate et endDate pour filtrer les transactions
        final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        
        // Normaliser les dates pour la comparaison (sans heures)
        final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
        final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);
        
        // Filtrer les transactions selon la période sélectionnée
        final filteredExpenses = provider.expenses.where((expense) {
          final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
          return expenseDate.compareTo(startDateNormalized) >= 0 && 
                 expenseDate.compareTo(endDateNormalized) <= 0;
        }).toList();
        
        final filteredIncomes = provider.incomes.where((income) {
          final incomeDate = DateTime(income.date.year, income.date.month, income.date.day);
          return incomeDate.compareTo(startDateNormalized) >= 0 && 
                 incomeDate.compareTo(endDateNormalized) <= 0;
        }).toList();
        
        final expenseCount = filteredExpenses.length;
        final incomeCount = filteredIncomes.length;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TransactionCountCardWidget(
            incomeCount: incomeCount,
            expenseCount: expenseCount,
            period: _selectedPeriod,
            selectedDate: _selectedDate,
          ),
        );

      case StatisticsCardType.topCategoryCard:
        // Graphique désactivé - retourner un widget vide
        return const SizedBox.shrink();

      case StatisticsCardType.scheduledPaymentsCard:
        // Graphique désactivé - retourner un widget vide
        return const SizedBox.shrink();

      case StatisticsCardType.budgetVsActualChart:
        final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: BudgetVsActualChartWidget(
            data: provider.budgetVsActual,
            isLoading: _isLoadingCharts,
          ),
        );

      case StatisticsCardType.topBudgetCategoriesCard:
        final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TopBudgetCategoriesCardWidget(
            data: provider.topBudgetCategories,
            isLoading: _isLoadingCharts,
          ),
        );

      case StatisticsCardType.budgetEfficiencyCard:
        final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: BudgetEfficiencyCardWidget(
            data: provider.budgetEfficiency,
            isLoading: _isLoadingCharts,
          ),
        );


      case StatisticsCardType.budgetDistributionPieChart:
        final dateRange = _calculateDateRange(_selectedPeriod, _selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: BudgetDistributionPieChartWidget(
            data: provider.budgetDistribution,
            isLoading: _isLoadingCharts,
          ),
        );

      case StatisticsCardType.topExpenseCard:
        // Graphique désactivé - retourner un widget vide
        return const SizedBox.shrink();

      case StatisticsCardType.balanceCard:
        // Graphique désactivé - retourner un widget vide
        return const SizedBox.shrink();

      case StatisticsCardType.goalsProgressCard:
        // Graphique désactivé - retourner un widget vide
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            final isLoading = _isLoadingStatistics || !_statisticsDataLoaded;
            
            // Charger les données statistiques à la demande (lazy loading strict)
            if (widget.isVisible && !_statisticsDataLoaded && !_isLoadingStatistics && provider.currentUser != null) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted && widget.isVisible && !_statisticsDataLoaded && !_isLoadingStatistics) {
                  _loadStatisticsDataIfNeeded();
                }
              });
            }
            
            // Si l'écran n'est pas visible ou en cours de chargement, afficher les skeletons
            if (!widget.isVisible || isLoading) {
              // Afficher les skeletons pour les cartes par défaut si disponibles
              final defaultCardIds = provider.statisticsCardsPreferences;
              final hasBarChart = defaultCardIds.contains('1') || defaultCardIds.contains('bar_chart');
              final hasPieChart = defaultCardIds.contains('2') || defaultCardIds.contains('pie_chart');
              
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                  // Summary Cards Skeletons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: const [
                          Expanded(child: SummaryCardSkeleton()),
                          SizedBox(width: 12),
                          Expanded(child: SummaryCardSkeleton()),
                        ],
                      ),
                    ),
                  ),
                  // Graph skeletons selon les cartes par défaut
                  if (hasBarChart)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 350,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (hasPieChart)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 350,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Si aucune carte par défaut, afficher un skeleton générique
                  if (!hasBarChart && !hasPieChart)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            // Obtenir les cartes sélectionnées et les trier par ordre (value)
            final selectedCardIds = provider.statisticsCardsPreferences;
            
            // Utiliser les favoris du provider (chargés en arrière-plan après loadHomeData)
            final cardFavoritesToUse = provider.cardFavorites.isNotEmpty 
                ? provider.cardFavorites 
                : _cardFavorites;
            
            // Créer une map pour accéder rapidement à l'ordre de chaque carte
            final cardOrderMap = <String, int>{};
            for (var fav in cardFavoritesToUse) {
              final targetEntity = fav['targetEntity']?.toString() ?? '';
              final value = fav['value']?.toString() ?? '0';
              final order = int.tryParse(value) ?? 999;
              cardOrderMap[targetEntity] = order;
            }

            // Convertir les IDs numériques en codes en utilisant les cartes disponibles depuis le backend
            // Dédupliquer d'abord les IDs pour éviter les doublons
            final uniqueCardIds = selectedCardIds.toSet().toList();
            
            // Convertir les IDs numériques en codes en utilisant les cartes disponibles
            final cardIdToCodeMap = <String, String>{};
            if (provider.availableCardsLoaded && provider.availableCards.isNotEmpty) {
              for (var card in provider.availableCards) {
                cardIdToCodeMap[card.id.toString()] = card.code;
              }
            }
            
            final selectedCardTypes = uniqueCardIds
                .map((id) {
                  // Convertir l'ID numérique en code si nécessaire
                  final cardCode = cardIdToCodeMap[id] ?? id;
                  
                  // Chercher le type correspondant au code
                  final cardType = StatisticsCardTypeExtension.fromId(cardCode);
                  if (cardType == null) {
                    return null;
                  }
                  
                  // Utiliser l'ID numérique pour chercher dans cardOrderMap
                  final numericId = id;
                  final order = cardOrderMap[numericId] ?? 999;
                  return MapEntry(cardType, order);
                })
                .whereType<MapEntry<StatisticsCardType, int>>()
                .toList();
            
            // Dédupliquer par type de carte pour éviter les doublons
            final seenTypes = <StatisticsCardType>{};
            final deduplicatedCardTypes = selectedCardTypes
                .where((entry) => seenTypes.add(entry.key))
                .toList();
            
            // Trier par ordre
            deduplicatedCardTypes.sort((a, b) => a.value.compareTo(b.value));

            final sortedCardTypes = deduplicatedCardTypes.map((e) => e.key).toList();

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Summary Cards (toujours visibles)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Solde global en premier avec background coloré
                        _BalanceSummaryCard(
                          balance: provider.balance,
                        ),
                        const SizedBox(height: 12),
                        // Revenus et Dépenses au-dessus du solde
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'Revenus totaux',
                                amount: provider.totalIncome,
                                color: AppTheme.incomeColor,
                                icon: Icons.trending_up_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Dépenses totales',
                                amount: provider.totalExpenses,
                                color: AppTheme.expenseColor,
                                icon: Icons.trending_down_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Filtre de période avec icône de filtre fixe à droite
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _PeriodFilterDropdown(
                          selectedPeriod: _selectedPeriod,
                          selectedDate: _selectedDate,
                          onPeriodChanged: (period) => _onPeriodChanged(period, provider),
                          onDateChanged: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                            _loadChartsDataIfNeeded(provider);
                          },
                        ),
                        const Spacer(),
                        // Icône de filtre fixe à droite
                        Builder(
                          builder: (context) => IconButton(
                            onPressed: () => _showPeriodMenu(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Afficher toutes les cartes sélectionnées dans l'ordre
                ...sortedCardTypes.map((cardType) => SliverToBoxAdapter(
                      child: _buildCardWidget(cardType, provider),
                    )),

                // Bouton "Ajouter d'autres cartes"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: OutlinedButton.icon(
                      onPressed: _handleSelectCards,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ajouter d\'autres cartes'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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

class _BalanceSummaryCard extends StatelessWidget {
  final double balance;

  const _BalanceSummaryCard({
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    final balanceColor = balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: balance >= 0 
            ? AppTheme.incomeColor.withOpacity(0.2) 
            : AppTheme.expenseColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: balanceColor,
          width: 2.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: balanceColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: balanceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Solde global',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: balanceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(balance),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isBalance;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBalance 
            ? (amount >= 0 ? AppTheme.incomeColor.withOpacity(0.2) : AppTheme.expenseColor.withOpacity(0.2))
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBalance 
              ? (amount >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor)
              : color.withOpacity(0.3),
          width: isBalance ? 2.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(amount),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodFilterDropdown extends StatelessWidget {
  final String selectedPeriod;
  final DateTime selectedDate;
  final Function(String) onPeriodChanged;
  final Function(DateTime) onDateChanged;

  const _PeriodFilterDropdown({
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
  });

  String _formatDate(DateTime date, String period) {
    switch (period) {
      case 'daily':
        // Format: "15 décembre, 2025"
        return DateFormat('d MMMM, yyyy', 'fr').format(date);
      case 'weekly':
        // Format: "29 déc. 2025 - 4 janv. 2026" (format court avec abréviations et années)
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final startMonthAbbr = DateFormat('MMM', 'fr').format(startOfWeek);
        final endMonthAbbr = DateFormat('MMM', 'fr').format(endOfWeek);
        
        if (startOfWeek.month == endOfWeek.month && startOfWeek.year == endOfWeek.year) {
          // Même mois et même année : "29-4 déc. 2025"
          return '${startOfWeek.day}-${endOfWeek.day} $startMonthAbbr ${startOfWeek.year}';
        } else if (startOfWeek.year == endOfWeek.year) {
          // Même année mais mois différents : "29 déc. 2025 - 4 janv. 2025"
          return '${startOfWeek.day} $startMonthAbbr ${startOfWeek.year} - ${endOfWeek.day} $endMonthAbbr ${endOfWeek.year}';
        } else {
          // Années différentes : "29 déc. 2025 - 4 janv. 2026"
          return '${startOfWeek.day} $startMonthAbbr ${startOfWeek.year} - ${endOfWeek.day} $endMonthAbbr ${endOfWeek.year}';
        }
      case 'monthly':
        // Format: "décembre, 2025"
        return DateFormat('MMMM, yyyy', 'fr').format(date);
      case '3months':
        // Format: "octobre - décembre, 2025" (3 derniers mois)
        // Calculer le mois de début (2 mois avant le mois actuel)
        int startMonthNum = date.month - 2;
        int startYear = date.year;
        if (startMonthNum <= 0) {
          startMonthNum += 12;
          startYear -= 1;
        }
        final startMonth = DateTime(startYear, startMonthNum, 1);
        final endMonth = DateTime(date.year, date.month, 1);
        if (startMonth.year == endMonth.year) {
          return '${DateFormat('MMMM', 'fr').format(startMonth)} - ${DateFormat('MMMM', 'fr').format(endMonth)}, ${date.year}';
        } else {
          return '${DateFormat('MMMM', 'fr').format(startMonth)}, ${startMonth.year} - ${DateFormat('MMMM', 'fr').format(endMonth)}, ${endMonth.year}';
        }
      case '6months':
        // Format: "juillet - décembre, 2025" (6 derniers mois)
        // Calculer le mois de début (5 mois avant le mois actuel)
        int startMonthNum = date.month - 5;
        int startYear = date.year;
        if (startMonthNum <= 0) {
          startMonthNum += 12;
          startYear -= 1;
        }
        final startMonth = DateTime(startYear, startMonthNum, 1);
        final endMonth = DateTime(date.year, date.month, 1);
        if (startMonth.year == endMonth.year) {
          return '${DateFormat('MMMM', 'fr').format(startMonth)} - ${DateFormat('MMMM', 'fr').format(endMonth)}, ${date.year}';
        } else {
          return '${DateFormat('MMMM', 'fr').format(startMonth)}, ${startMonth.year} - ${DateFormat('MMMM', 'fr').format(endMonth)}, ${endMonth.year}';
        }
      default:
        return DateFormat('MMMM, yyyy', 'fr').format(date);
    }
  }

  void _previousPeriod() {
    DateTime newDate;
    switch (selectedPeriod) {
      case 'daily':
        newDate = selectedDate.subtract(const Duration(days: 1));
        break;
      case 'weekly':
        newDate = selectedDate.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        newDate = DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day);
        break;
      case '3months':
        newDate = DateTime(selectedDate.year, selectedDate.month - 3, selectedDate.day);
        break;
      case '6months':
        newDate = DateTime(selectedDate.year, selectedDate.month - 6, selectedDate.day);
        break;
      default:
        newDate = DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day);
    }
    onDateChanged(newDate);
  }

  void _nextPeriod() {
    DateTime newDate;
    switch (selectedPeriod) {
      case 'daily':
        newDate = selectedDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        newDate = selectedDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        newDate = DateTime(selectedDate.year, selectedDate.month + 1, selectedDate.day);
        break;
      case '3months':
        newDate = DateTime(selectedDate.year, selectedDate.month + 3, selectedDate.day);
        break;
      case '6months':
        newDate = DateTime(selectedDate.year, selectedDate.month + 6, selectedDate.day);
        break;
      default:
        newDate = DateTime(selectedDate.year, selectedDate.month + 1, selectedDate.day);
    }
    onDateChanged(newDate);
  }

  void _showPeriodMenu(BuildContext context) {
    final periods = [
      {'value': 'daily', 'label': 'Quotidien'},
      {'value': 'weekly', 'label': 'Hebdomadaire'},
      {'value': 'monthly', 'label': 'Mensuel'},
      {'value': '3months', 'label': '3 Mois'},
      {'value': '6months', 'label': '6 Mois'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Sélectionner une période',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Divider(),
            ...periods.map((period) {
              final isSelected = selectedPeriod == period['value'];
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                ),
                title: Text(
                  period['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (period['value'] != selectedPeriod) {
                    onPeriodChanged(period['value']!);
                  }
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chevron gauche
          InkWell(
            onTap: _previousPeriod,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Texte de la date formatée selon la période
          Text(
            _formatDate(selectedDate, selectedPeriod),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          // Chevron droite
          InkWell(
            onTap: _nextPeriod,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
