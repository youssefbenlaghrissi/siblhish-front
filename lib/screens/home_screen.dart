import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../models/scheduled_payment.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/transaction_item.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_scheduled_payment_modal.dart';
import '../widgets/scheduled_payment_details_modal.dart';
import '../widgets/confirm_payment_dialog.dart';
import '../widgets/skeleton_loader.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import '../main.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/error_message_formatter.dart';
import '../utils/date_formatter.dart';

class HomeScreen extends StatefulWidget {
  final bool isVisible;
  
  const HomeScreen({super.key, this.isVisible = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadNotificationsCount = 0;
  bool _homeDataLoadScheduled = false; // Flag pour éviter les appels multiples
  
  // Filtres (pour l'UI uniquement, le traitement se fait côté backend)
  String? _filterType; // 'income', 'expense', null (tous)
  String? _filterDateRange; // '3days', 'week', 'month', 'custom', null
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  double? _filterMinAmount;
  double? _filterMaxAmount;

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'écran vient de devenir visible, charger les données
    if (widget.isVisible && !oldWidget.isVisible) {
      _homeDataLoadScheduled = false; // Réinitialiser le flag
      _loadHomeDataIfNeeded();
      _loadUnreadCount();
      _startPeriodicNotificationCheck();
    }
    // Si l'écran devient invisible, arrêter la vérification périodique
    if (!widget.isVisible && oldWidget.isVisible) {
      _stopPeriodicNotificationCheck();
    }
  }

  @override
  void initState() {
    super.initState();
    // Si l'écran est visible au démarrage, charger les données
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible) {
          _loadHomeDataIfNeeded();
          _loadUnreadCount();
          _startPeriodicNotificationCheck();
        }
      });
    }
  }

  Future<void> _loadHomeDataIfNeeded() async {
    // Éviter les appels multiples en utilisant le flag du provider
    final provider = context.read<BudgetProvider>();
    if (provider.currentUser != null && !provider.isLoadingHomeData && !_homeDataLoadScheduled) {
      _homeDataLoadScheduled = true;
      try {
        await provider.loadHomeData();
      } finally {
        // Réinitialiser le flag après le chargement (réussi ou échoué)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _homeDataLoadScheduled = false;
          }
        });
      }
    }
  }

  // Fonction pour naviguer vers l'onglet Transactions
  void _navigateToTransactionsTab() {
    // OPTIMISATION : Ne pas charger ici, laisser TransactionsScreen gérer le chargement
    // Cela permet d'afficher le skeleton pendant le chargement
    // Utiliser le GlobalKey pour accéder au MainScreen
    final mainScreenState = MainScreen.navigatorKey.currentState;
    if (mainScreenState != null) {
      // Changer l'onglet vers Transactions (index 1)
      mainScreenState.changeTab(1);
    }
  }

  @override
  void dispose() {
    _stopPeriodicNotificationCheck();
    super.dispose();
  }

  Timer? _notificationCheckTimer;

  void _startPeriodicNotificationCheck() {
    // Vérifier toutes les 30 secondes
    _notificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewNotifications();
    });
  }

  void _stopPeriodicNotificationCheck() {
    _notificationCheckTimer?.cancel();
    _notificationCheckTimer = null;
  }

  Future<void> _loadUnreadCount() async {
    try {
      final provider = context.read<BudgetProvider>();
      final userId = provider.currentUser?.id;
      if (userId == null) return;

      // Vérifier si les notifications sont activées (pour la vérification périodique)
      if (_notificationCheckTimer != null && 
          provider.currentUser?.notificationsEnabled != true) {
        return;
      }

      final count = await NotificationService.getUnreadCount(userId);
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _checkForNewNotifications() async {
    await _loadUnreadCount();
  }

  void _showFilterDialog(BuildContext context) {
    String? tempType = _filterType;
    String? tempDateRange = _filterDateRange;
    DateTime? tempStartDate = _filterStartDate;
    DateTime? tempEndDate = _filterEndDate;
    final minController = TextEditingController(text: _filterMinAmount?.toString() ?? '');
    final maxController = TextEditingController(text: _filterMaxAmount?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtrer les transactions',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Type de transaction
                Text(
                  'Type',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _FilterChip(
                      label: 'Tous',
                      isSelected: tempType == null,
                      onTap: () => setModalState(() => tempType = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Revenus',
                      isSelected: tempType == 'income',
                      onTap: () => setModalState(() => tempType = 'income'),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Dépenses',
                      isSelected: tempType == 'expense',
                      onTap: () => setModalState(() => tempType = 'expense'),
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Période
                Text(
                  'Période',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Toutes',
                      isSelected: tempDateRange == null,
                      onTap: () => setModalState(() {
                        tempDateRange = null;
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                    ),
                    _FilterChip(
                      label: '3 derniers jours',
                      isSelected: tempDateRange == '3days',
                      onTap: () => setModalState(() {
                        tempDateRange = '3days';
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                    ),
                    _FilterChip(
                      label: 'Semaine dernière',
                      isSelected: tempDateRange == 'week',
                      onTap: () => setModalState(() {
                        tempDateRange = 'week';
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                    ),
                    _FilterChip(
                      label: 'Dernier mois',
                      isSelected: tempDateRange == 'month',
                      onTap: () => setModalState(() {
                        tempDateRange = 'month';
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                    ),
                    _FilterChip(
                      label: 'Personnalisé',
                      isSelected: tempDateRange == 'custom',
                      onTap: () => setModalState(() => tempDateRange = 'custom'),
                      color: Colors.purple,
                    ),
                  ],
                ),
                
                // Dates personnalisées
                if (tempDateRange == 'custom') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => tempStartDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  tempStartDate != null
                                      ? DateFormat('dd/MM/yyyy').format(tempStartDate!)
                                      : 'Date début',
                                  style: GoogleFonts.poppins(
                                    color: tempStartDate != null ? Colors.black : Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey[400]),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempEndDate ?? DateTime.now(),
                              firstDate: tempStartDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => tempEndDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  tempEndDate != null
                                      ? DateFormat('dd/MM/yyyy').format(tempEndDate!)
                                      : 'Date fin',
                                  style: GoogleFonts.poppins(
                                    color: tempEndDate != null ? Colors.black : Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // Montant
                Text(
                  'Montant (MAD)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Min',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('-', style: GoogleFonts.poppins(fontSize: 20)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Max',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          setState(() {
                            _filterType = null;
                            _filterDateRange = null;
                            _filterStartDate = null;
                            _filterEndDate = null;
                            _filterMinAmount = null;
                            _filterMaxAmount = null;
                          });
                          Navigator.pop(context);
                          
                          // Recharger les transactions sans filtres depuis le backend
                          final provider = context.read<BudgetProvider>();
                          await provider.loadRecentTransactions(limit: 3);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Réinitialiser',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Appliquer les filtres et appeler le backend
                          setState(() {
                            _filterType = tempType;
                            _filterDateRange = tempDateRange;
                            _filterStartDate = tempStartDate;
                            _filterEndDate = tempEndDate;
                            _filterMinAmount = minController.text.isNotEmpty
                                ? double.tryParse(minController.text)
                                : null;
                            _filterMaxAmount = maxController.text.isNotEmpty
                                ? double.tryParse(maxController.text)
                                : null;
                          });
                          
                          Navigator.pop(context);
                          
                          // Recharger les transactions avec les filtres appliqués
                          final provider = context.read<BudgetProvider>();
                          await provider.loadFilteredTransactions(
                            limit: 3,
                            type: tempType,
                            dateRange: tempDateRange,
                            startDate: tempStartDate,
                            endDate: tempEndDate,
                            minAmount: minController.text.isNotEmpty
                                ? double.tryParse(minController.text)
                                : null,
                            maxAmount: maxController.text.isNotEmpty
                                ? double.tryParse(maxController.text)
                                : null,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Appliquer',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            // Vérifier s'il y a une erreur (uniquement pour les erreurs de chargement initial)
            if (provider.error != null && !provider.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && provider.error != null) {
                  final errorMessage = provider.error;
                  // Effacer l'erreur immédiatement pour éviter qu'elle soit affichée ailleurs
                  provider.clearError();
                  
                  final userFriendlyMessage = ErrorMessageFormatter.formatErrorMessage(errorMessage);
                  final errorTitle = ErrorMessageFormatter.getErrorTitle(errorMessage);
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: Text(errorTitle),
                      content: Text(userFriendlyMessage),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Réessayer le chargement
                            final userId = provider.currentUser?.id;
                            if (userId != null) {
                              provider.initialize(userId);
                            }
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }
              });
            }
            
            // Si pas d'utilisateur chargé, afficher un indicateur de chargement
            if (provider.currentUser == null && provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // Si pas d'utilisateur chargé ou erreur, ne pas afficher les données
            if (provider.currentUser == null || provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Impossible de charger vos données',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (provider.error != null)
                        Text(
                          provider.error!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final userId = await AuthService.getCurrentUserId();
                            if (userId != null) {
                              await provider.initialize(userId);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final userName = provider.currentUser!.firstName;
            final isLoading = provider.isLoadingHomeData;
            
            // Utiliser les transactions récentes de la page d'accueil (toujours limit=3, indépendantes des filtres)
            final recentTransactions = provider.homeRecentTransactions;
            final balance = provider.balance;
            final scheduledPayments = provider.scheduledPayments.take(5).toList();
            final categories = provider.categories;

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
                        Stack(
                          children: [
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
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ),
                                  );
                                  // Recharger le compteur après retour
                                  _loadUnreadCount();
                                },
                              ),
                            ),
                            if (_unreadNotificationsCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    _unreadNotificationsCount > 99 
                                        ? '99+' 
                                        : _unreadNotificationsCount.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Balance Card avec Revenus et Dépenses
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: isLoading 
                        ? const BalanceCardSkeleton()
                        : _BalanceCardWithStats(
                            balance: balance,
                            totalIncome: provider.totalIncome,
                            totalExpenses: provider.totalExpenses,
                          ),
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions récentes',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        // Afficher "Voir plus" s'il y a des transactions (suggère qu'il peut y en avoir plus)
                        if (recentTransactions.isNotEmpty)
                          TextButton(
                            onPressed: () => _navigateToTransactionsTab(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Voir plus',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                isLoading
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                index == 2 ? 20 : 10,
                              ),
                              child: const TransactionItemSkeleton(),
                            );
                          },
                          childCount: 3, // Afficher 3 skeletons
                        ),
                      )
                    : recentTransactions.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.receipt_long_rounded, color: Colors.grey[400], size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Aucune transaction',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
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
                                  ),
                                );
                              },
                              childCount: recentTransactions.length,
                            ),
                          ),

                // Scheduled Payments Section
                SliverToBoxAdapter(
                  child: _ScheduledPaymentsSection(
                    payments: scheduledPayments,
                    categories: categories,
                    isLoading: isLoading,
                    onAddPayment: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddScheduledPaymentModal(),
                      );
                    },
                    onMarkAsPaid: (id) async {
                      final selectedDateTime = await showDialog<DateTime>(
                        context: context,
                        builder: (context) => const ConfirmPaymentDialog(),
                      );
                      if (selectedDateTime != null) {
                        // Afficher un spinner pendant la confirmation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        try {
                          await provider.markScheduledPaymentAsPaid(id, selectedDateTime);
                          if (context.mounted) {
                            Navigator.pop(context); // Fermer le spinner
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Fermer le spinner
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
                    onDelete: (id) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Supprimer le paiement',
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
                        try {
                          await provider.deleteScheduledPayment(id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              CustomSnackBar.success(
                                title: 'Paiement planifié supprimé avec succès',
                                description: 'Le paiement a été supprimé',
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
                ),

                // Bottom spacing
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

class _BalanceCardWithStats extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpenses;

  const _BalanceCardWithStats({
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    final balanceColor = balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Column(
      children: [
        // Solde global en premier avec background coloré
        Container(
          padding: const EdgeInsets.all(20),
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
        // Revenus et Dépenses en dessous
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.incomeColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: AppTheme.incomeColor,
                          size: 24,
                        ),
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
                  border: Border.all(
                    color: AppTheme.expenseColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down_rounded,
                          color: AppTheme.expenseColor,
                          size: 24,
                        ),
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
    );
  }
}

class _ScheduledPaymentsSection extends StatelessWidget {
  final List<ScheduledPayment> payments;
  final List<Category> categories;
  final VoidCallback onAddPayment;
  final Function(String) onMarkAsPaid;
  final Function(String) onDelete;
  final bool isLoading;

  const _ScheduledPaymentsSection({
    required this.payments,
    required this.categories,
    required this.onAddPayment,
    required this.onMarkAsPaid,
    required this.onDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paiements planifiés',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: onAddPayment,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            ...List.generate(3, (index) => const ScheduledPaymentCardSkeleton())
          else if (payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.grey[400], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun paiement planifié',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...payments.map((payment) => _ScheduledPaymentCard(
                  payment: payment,
                  category: categories
                      .where((c) => c.id == payment.categoryId)
                      .firstOrNull,
                  onMarkAsPaid: () => onMarkAsPaid(payment.id),
                  onDelete: () => onDelete(payment.id),
                )),
        ],
      ),
    );
  }
}

class _ScheduledPaymentCard extends StatefulWidget {
  final ScheduledPayment payment;
  final Category? category;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onDelete;

  const _ScheduledPaymentCard({
    required this.payment,
    required this.category,
    required this.onMarkAsPaid,
    required this.onDelete,
  });

  @override
  State<_ScheduledPaymentCard> createState() => _ScheduledPaymentCardState();
}

class _ScheduledPaymentCardState extends State<_ScheduledPaymentCard> {
  bool _isDeleting = false;

  void _handleDelete() async {
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

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = widget.payment.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0 && !widget.payment.isPaid;
    final isDueSoon = daysUntilDue <= 3 && daysUntilDue >= 0 && !widget.payment.isPaid;
    final isPaid = widget.payment.isPaid;

    return Opacity(
      opacity: isPaid ? 0.6 : 1.0,
        child: InkWell(
        onTap: _isDeleting ? null : () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ScheduledPaymentDetailsModal(
              payment: widget.payment,
              category: widget.category,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPaid ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPaid
                  ? Colors.green.withOpacity(0.3)
                  : isOverdue
                      ? Colors.red.withOpacity(0.3)
                      : isDueSoon
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: isPaid
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withOpacity(0.15)
                        : _parseColor(widget.category?.color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.category?.icon ?? '📦',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.payment.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isPaid ? Colors.grey[600] : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Label "Payé" supprimé selon la demande
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                        size: 12,
                        color: isPaid
                            ? Colors.green
                            : isOverdue
                                ? Colors.red
                                : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid
                            ? 'Payé le ${DateFormatter.formatDateWithoutYear(widget.payment.dueDate)}'
                            : isOverdue
                                ? 'En retard'
                                : daysUntilDue == 0
                                    ? "Aujourd'hui"
                                    : daysUntilDue == 1
                                        ? 'Demain'
                                        : 'Dans $daysUntilDue jours',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isPaid
                              ? Colors.green
                              : isOverdue
                                  ? Colors.red
                                  : isDueSoon
                                      ? Colors.orange
                                      : Colors.grey[600],
                        ),
                      ),
                      if (widget.payment.isRecurring && !isPaid) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.repeat_rounded, size: 12, color: Colors.grey[500]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Ne pas afficher le montant si le paiement est payé
                if (!isPaid)
                  Text(
                    '${widget.payment.amount.toStringAsFixed(2)} MAD',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                const SizedBox(height: 4),
                if (!isPaid)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _isDeleting ? null : () {
                          widget.onMarkAsPaid();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_rounded, size: 16, color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _isDeleting ? null : _handleDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                  ),
                                )
                              : const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  )
                else
                  // Pour les paiements payés, afficher seulement le montant (pas de boutons d'action)
                  Text(
                    '${widget.payment.amount.toStringAsFixed(2)} MAD',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ),
        ),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? chipColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
