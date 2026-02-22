import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_item.dart';
import '../widgets/skeleton_loader.dart';

class TransactionsScreen extends StatefulWidget {
  final bool isVisible;
  final String? initialType;
  final String? initialDateRange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final String? initialCategoryId;

  const TransactionsScreen({
    super.key,
    this.isVisible = false,
    this.initialType,
    this.initialDateRange,
    this.initialStartDate,
    this.initialEndDate,
    this.initialMinAmount,
    this.initialMaxAmount,
    this.initialCategoryId,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Filtres
  String? _filterType;
  String? _filterDateRange;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  double? _filterMinAmount;
  double? _filterMaxAmount;
  String? _filterCategoryId;
  bool _hasActiveFilters = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les filtres avec les valeurs passées
    _filterType = widget.initialType;
    _filterDateRange = widget.initialDateRange;
    _filterStartDate = widget.initialStartDate;
    _filterEndDate = widget.initialEndDate;
    _filterMinAmount = widget.initialMinAmount;
    _filterMaxAmount = widget.initialMaxAmount;
    _filterCategoryId = widget.initialCategoryId;
    _hasActiveFilters = _filterType != null ||
        _filterDateRange != null ||
        _filterMinAmount != null ||
        _filterMaxAmount != null ||
        _filterCategoryId != null;

    // OPTIMISATION : Ne charger que si l'écran est visible (évite le double appel API)
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible) {
          // Marquer TransactionsScreen comme actif
          context.read<BudgetProvider>().setActiveScreen('transactions');
          _loadTransactions();
        }
      });
    }
  }


  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Charger les transactions quand l'écran devient visible
    if (widget.isVisible && !oldWidget.isVisible && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isVisible && !_isLoading) {
          // Marquer TransactionsScreen comme actif
          context.read<BudgetProvider>().setActiveScreen('transactions');
          _loadTransactions();
        }
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final provider = context.read<BudgetProvider>();
    
    try {
      // Appeler le backend avec les filtres
      await provider.loadFilteredTransactions(
        limit: 2147483647, // Max int 32-bit
        type: _filterType,
        dateRange: _filterDateRange,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        minAmount: _filterMinAmount,
        maxAmount: _filterMaxAmount,
        categoryId: _filterCategoryId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _applyFilters() {
    // Recharger depuis le backend avec les nouveaux filtres
    _loadTransactions();
  }

  /// Format d'en-tête de groupe : "Lundi 15 Février 2026" (jour + date en français)
  static String _formatDateGroupHeader(DateTime date) {
    final formatted = DateFormat('EEEE d MMMM yyyy', 'fr').format(date);
    if (formatted.isEmpty) return formatted;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  void _showFilterDialog() {
    // Variables temporaires pour les filtres dans le dialogue
    String? tempType = _filterType;
    String? tempDateRange = _filterDateRange;
    DateTime? tempStartDate = _filterStartDate;
    DateTime? tempEndDate = _filterEndDate;
    String? tempCategoryId = _filterCategoryId;
    final minController = TextEditingController(
      text: _filterMinAmount?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _filterMaxAmount?.toString() ?? '',
    );
    // Charger les catégories pour le filtre (backend n'applique categoryId que pour les dépenses)
    final provider = context.read<BudgetProvider>();
    provider.loadCategoriesIfNeeded();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtrer les transactions',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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

                // Catégorie (pertinent pour "Tous" ou "Dépenses" uniquement)
                if (tempType == null || tempType == 'expense') ...[
                  Text(
                    'Catégorie',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<BudgetProvider>(
                    builder: (context, prov, _) {
                      final categories = prov.categories;
                      return DropdownButtonFormField<String?>(
                        value: tempCategoryId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        hint: Text(
                          'Toutes',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Toutes',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          ...categories.map((c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  style: GoogleFonts.poppins(),
                                ),
                              )),
                        ],
                        onChanged: (v) => setModalState(() => tempCategoryId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

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
                      label: 'Mois dernier',
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
                      onTap: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: tempStartDate != null && tempEndDate != null
                              ? DateTimeRange(start: tempStartDate!, end: tempEndDate!)
                              : null,
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempDateRange = 'custom';
                            tempStartDate = picked.start;
                            tempEndDate = picked.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Montant
                Text(
                  'Montant',
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
                          labelText: 'Min (MAD)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max (MAD)',
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
                            _filterCategoryId = null;
                            _hasActiveFilters = false;
                          });
                          Navigator.pop(context);
                          _applyFilters();
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
                            _filterCategoryId = tempCategoryId;
                            _hasActiveFilters = tempType != null ||
                                tempDateRange != null ||
                                _filterMinAmount != null ||
                                _filterMaxAmount != null ||
                                tempCategoryId != null;
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Transactions',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Stack(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: _hasActiveFilters ? AppTheme.primaryColor : Colors.grey[600],
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 8, // Afficher 8 skeletons
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 7 ? 20 : 12),
                  child: const TransactionItemSkeleton(),
                );
              },
            )
          : Consumer<BudgetProvider>(
              builder: (context, provider, child) {
                // Utiliser les transactions chargées depuis le backend avec filtres
                final transactions = provider.filteredTransactions;

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/transaction.png',
                          width: 128,
                          height: 128,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune transaction',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Grouper par date (jour) — clé = date normalisée à minuit
                final Map<DateTime, List<dynamic>> grouped = {};
                for (final t in transactions) {
                  final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
                  grouped.putIfAbsent(dateKey, () => []).add(t);
                }
                // Trier les dates de la plus récente à la plus ancienne
                final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                int itemCount = 0;
                for (final d in sortedDates) {
                  itemCount += 1 + grouped[d]!.length; // 1 en-tête + N transactions
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    int remaining = index;
                    for (final dateKey in sortedDates) {
                      final list = grouped[dateKey]!;
                      if (remaining == 0) {
                        // En-tête de date (jour + date complète)
                        final label = _formatDateGroupHeader(dateKey);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }
                      remaining--;
                      if (remaining < list.length) {
                        final transaction = list[remaining];
                        final isLastItem = (dateKey == sortedDates.last && remaining == list.length - 1);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            isLastItem ? 20 : 8,
                          ),
                          child: TransactionItem(
                            transaction: transaction,
                            category: transaction is Expense
                                ? provider.categories
                                    .where((Category c) => c.id == transaction.categoryId)
                                    .firstOrNull
                                : null,
                          ),
                        );
                      }
                      remaining -= list.length;
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.primaryColor).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.primaryColor)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected
                ? (color ?? AppTheme.primaryColor)
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

