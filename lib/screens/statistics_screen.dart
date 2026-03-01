import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/statistics/calendar_chart_widget.dart';
import '../widgets/statistics/pie_chart_widget.dart';
import '../widgets/statistics/select_cards_modal.dart';
import '../widgets/statistics/statistics_card_widgets.dart';
import '../widgets/statistics/top_budget_categories_card_widget.dart';
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
  bool _isUpdatingCards = false; // État pour gérer le spinner lors de la mise à jour des cartes
  List<Map<String, dynamic>> _cardFavorites = [];
  static const String _period = 'monthly'; // Statistiques par mois uniquement
  DateTime _selectedDate = DateTime.now(); // Mois sélectionné pour les statistiques

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
        
        // S'assurer que les cartes nécessitant expenses/incomes sont incluses
        final cardIdsToLoad = <String>[...selectedCardIds];
        if (!cardIdsToLoad.contains('transaction_count_card') && 
            !cardIdsToLoad.contains('8')) {
          cardIdsToLoad.add('transaction_count_card');
        }
        // S'assurer que 'bar_chart' est inclus pour charger les dépenses/revenus (calendrier)
        if (!cardIdsToLoad.contains('bar_chart') && 
            !cardIdsToLoad.contains('1')) {
          cardIdsToLoad.add('bar_chart');
        }
        
        // Charger les données nécessaires pour les cartes sélectionnées
        await provider.loadStatisticsData(requiredCardIds: cardIdsToLoad);
        
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
      // Calculer startDate et endDate pour le mois sélectionné
      final dateRange = _calculateDateRange(_selectedDate);
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

  // Calculer startDate et endDate pour le mois sélectionné
  Map<String, DateTime> _calculateDateRange(DateTime selectedDate) {
    final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
    return {'startDate': startDate, 'endDate': endDate};
  }

  /// Carte solde identique à l'écran d'accueil (solde + revenus + dépenses).
  Widget _buildBalanceCard(BudgetProvider provider) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    final balance = provider.balance;
    final totalIncome = provider.totalIncome;
    final totalExpenses = provider.totalExpenses;
    final balanceColor = balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: balance >= 0
                ? AppTheme.incomeColor.withOpacity(0.2)
                : AppTheme.expenseColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: balanceColor, width: 2.5),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: balanceColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Solde',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: balanceColor,
                  fontWeight: FontWeight.bold,
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.incomeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: AppTheme.incomeColor, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.incomeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Revenus totaux',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.incomeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatter.format(totalIncome),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.incomeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.expenseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.expenseColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_down_rounded, color: AppTheme.expenseColor, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.expenseColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Dépenses totales',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.expenseColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatter.format(totalExpenses),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
      // Afficher le spinner
      setState(() {
        _isUpdatingCards = true;
      });

      try {
        await provider.updateStatisticsCardsPreferences(selectedCards);
        
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
          setState(() {
            _isUpdatingCards = false;
          }); // Rafraîchir l'UI
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.success(
              title: 'Cartes mises à jour avec succès',
              description: 'Vos préférences ont été enregistrées',
            ),
          );
        }
      } catch (e) {
        // Afficher l'erreur
        if (mounted) {
          setState(() {
            _isUpdatingCards = false;
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

  Widget _buildCardWidget(StatisticsCardType cardType, BudgetProvider provider) {
    switch (cardType) {
      case StatisticsCardType.barChart:
        // Calendrier avec revenus et dépenses par jour
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _isLoadingCharts
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : (provider.expenses.isEmpty && provider.incomes.isEmpty)
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
                            const Icon(Icons.calendar_today_rounded, size: 48, color: Colors.grey),
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
                  : CalendarChartWidget(
                      expenses: provider.expenses,
                      incomes: provider.incomes,
                      selectedDate: _selectedDate,
                      period: _period,
                    ),
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
                  period: _period,
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
          final dateRange = _calculateDateRange(_selectedDate);
          final startDate = dateRange['startDate']!;
          final endDate = dateRange['endDate']!;
          
          // Moyenne par jour dans le mois
          numberOfPeriods = endDate.difference(startDate).inDays + 1;
          averageExpense = numberOfPeriods > 0 ? totalExpenses / numberOfPeriods : 0.0;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: AverageExpenseCardWidget(
            averageExpense: averageExpense,
            period: _period,
            numberOfPeriods: numberOfPeriods,
            selectedDate: _selectedDate,
          ),
        );

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
          final dateRange = _calculateDateRange(_selectedDate);
          final startDate = dateRange['startDate']!;
          final endDate = dateRange['endDate']!;
          
          // Moyenne par jour dans le mois
          numberOfPeriods = endDate.difference(startDate).inDays + 1;
          averageIncome = numberOfPeriods > 0 ? totalIncome / numberOfPeriods : 0.0;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: AverageIncomeCardWidget(
            averageIncome: averageIncome,
            period: _period,
            numberOfPeriods: numberOfPeriods,
            selectedDate: _selectedDate,
          ),
        );

      case StatisticsCardType.transactionCountCard:
        // Calculer startDate et endDate pour filtrer les transactions
        final dateRange = _calculateDateRange(_selectedDate);
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
            period: _period,
            selectedDate: _selectedDate,
          ),
        );

      case StatisticsCardType.topBudgetCategoriesCard:
        final dateRange = _calculateDateRange(_selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TopBudgetCategoriesCardWidget(
            data: provider.topBudgetCategories,
            isLoading: _isLoadingCharts,
          ),
        );

      case StatisticsCardType.budgetDistributionPieChart:
        final dateRange = _calculateDateRange(_selectedDate);
        final startDate = dateRange['startDate']!;
        final endDate = dateRange['endDate']!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: BudgetDistributionPieChartWidget(
            data: provider.budgetDistribution,
            isLoading: _isLoadingCharts,
          ),
        );

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

                // Carte solde (même que l'accueil)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildBalanceCard(provider),
                  ),
                ),

                // Sélecteur de mois (largeur minimale = contenu)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _MonthSelector(
                        selectedDate: _selectedDate,
                        onDateChanged: (date) {
                          setState(() => _selectedDate = date);
                          _loadChartsDataIfNeeded(provider);
                        },
                      ),
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
                      onPressed: _isUpdatingCards ? null : _handleSelectCards,
                      icon: _isUpdatingCards
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          : const Icon(Icons.add_rounded),
                      label: Text(_isUpdatingCards ? 'Mise à jour...' : 'Ajouter d\'autres cartes'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                        disabledForegroundColor: Colors.grey[400],
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

/// Sélecteur de mois pour les statistiques (navigation mois précédent / suivant).
class _MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _MonthSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'fr').format(selectedDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onDateChanged(DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day)),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.chevron_left_rounded, color: AppTheme.primaryColor, size: 20),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            monthLabel,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => onDateChanged(DateTime(selectedDate.year, selectedDate.month + 1, selectedDate.day)),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
