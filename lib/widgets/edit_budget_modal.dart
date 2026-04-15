import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../models/category.dart' as models;
import '../theme/app_theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/auto_generated_badge.dart';
import '../utils/date_formatter.dart';

class EditBudgetModal extends StatefulWidget {
  final Budget budget;
  final VoidCallback? onUpdated;

  const EditBudgetModal({super.key, required this.budget, this.onUpdated});

  @override
  State<EditBudgetModal> createState() => _EditBudgetModalState();
}

class _EditBudgetModalState extends State<EditBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late bool _isRecurring;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.budget.amount.toString());
    _startDate = widget.budget.startDate;
    _endDate = widget.budget.endDate;
    // Utiliser isRecurring directement depuis le backend (calculé dynamiquement à partir des dates)
    _isRecurring = widget.budget.isRecurring;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        // Si la date de fin est avant la nouvelle date de début, mettre à jour la date de fin
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = DateTime(_startDate!.year, _startDate!.month + 1, 0, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non sélectionnée';
    return DateFormatter.formatDate(date);
  }

  /// True si la période du budget est déjà passée (date de fin avant aujourd'hui).
  bool get _isPastBudget {
    final end = widget.budget.endDate;
    if (end == null) return false;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return end.isBefore(today);
  }

  Future<void> _deleteBudget() async {
    // Afficher la boîte de dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le budget',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce budget ? Cette action est irréversible.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final provider = context.read<BudgetProvider>();
      await provider.deleteBudget(widget.budget.id);

      if (mounted) {
        Navigator.pop(context);
        // Appeler le callback pour recharger les budgets avec le mois actuel
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Budget supprimé',
            description: 'Le budget a été supprimé avec succès',
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les dates de début et de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<BudgetProvider>();
      // Conserver les dates du formulaire (ne pas les remplacer par le mois courant)
      final DateTime? finalStartDate = _startDate;
      final DateTime? finalEndDate = _endDate;

      final updatedBudget = Budget(
        id: widget.budget.id,
        userId: widget.budget.userId,
        categoryId: widget.budget.categoryId,
        autoGenerated: widget.budget.autoGenerated,
        amount: double.parse(_amountController.text),
        startDate: finalStartDate,
        endDate: finalEndDate,
        isRecurring: _isRecurring,
      );

      await provider.updateBudget(updatedBudget);

      if (mounted) {
        Navigator.pop(context);
        // Appeler le callback pour recharger les budgets avec le mois actuel
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Budget modifié avec succès',
            description: 'Le budget a été mis à jour',
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modifier le Budget',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.budget.autoGenerated) ...[
                        const SizedBox(height: 10),
                        const AutoGeneratedBadge(),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Message période passée
                    if (_isPastBudget) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ce budget concerne une période passée.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.orange.shade900,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Category (disabled)
                    Consumer<BudgetProvider>(
                      builder: (context, provider, child) {
                        // Charger les catégories si nécessaire
                        if (!provider.categoriesLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            provider.loadCategoriesIfNeeded();
                          });
                        }
                        
                        final categories = provider.categories;
                        models.Category? selectedCategory;
                        
                        debugPrint('🔍 Budget categoryId: ${widget.budget.categoryId}');
                        debugPrint('🔍 Categories count: ${categories.length}');
                        
                        if (widget.budget.categoryId != null && widget.budget.categoryId!.isNotEmpty) {
                          try {
                            selectedCategory = categories.firstWhere(
                              (cat) => cat.id == widget.budget.categoryId,
                            );
                          } catch (e) {
                            // Si la catégorie n'est pas trouvée, créer une catégorie temporaire
                            selectedCategory = models.Category(
                              id: widget.budget.categoryId!,
                              name: 'Catégorie inconnue',
                              icon: '📦',
                              color: '#000000',
                            );
                          }
                        } else {
                        }
                        
                        // Afficher le champ même si les catégories ne sont pas encore chargées
                        return DropdownButtonFormField<models.Category?>(
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          value: selectedCategory,
                          items: selectedCategory != null
                              ? [
                                  DropdownMenuItem<models.Category?>(
                                    value: selectedCategory,
                                    child: Row(
                                      children: [
                                        Text(selectedCategory.icon ?? '📦'),
                                        const SizedBox(width: 8),
                                        Text(selectedCategory.name),
                                      ],
                                    ),
                                  ),
                                ]
                              : [
                                  const DropdownMenuItem<models.Category?>(
                                    value: null,
                                    child: Text('Budget global (sans catégorie)'),
                                  ),
                                ],
                          onChanged: null, // Désactivé
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Start Date (désactivé)
                    Opacity(
                      opacity: 0.6,
                      child: InkWell(
                        onTap: null, // Désactivé
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de début',
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _formatDate(_startDate),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // End Date (désactivé)
                    Opacity(
                      opacity: 0.6,
                      child: InkWell(
                        onTap: null, // Désactivé
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de fin',
                            prefixIcon: Icon(Icons.event_rounded),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _formatDate(_endDate),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        prefixText: 'MAD ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un montant';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Recurring Budget Checkbox (dernier élément avant le bouton) - modifiable
                    CheckboxListTile(
                      title: const Text('Budget récurrent'),
                      subtitle: const Text('Ce budget sera automatiquement recréé chaque mois'),
                      value: _isRecurring,
                      onChanged: _isSubmitting ? null : (value) {
                        setState(() {
                          _isRecurring = value ?? false;
                          // Ne pas modifier les dates à l'édition : garder les dates du budget
                        });
                      },
                    ),

                    // Message informatif quand récurrent est coché
                    if (_isRecurring) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ce budget parcourra automatiquement chaque mois du 1er au dernier jour. Vous n\'aurez plus besoin de le créer manuellement.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),

                    // Action Buttons (même style que transaction_details_modal)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (_isSubmitting || _isDeleting) ? null : _deleteBudget,
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
                            onPressed: (_isSubmitting || _isDeleting) ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.edit_rounded),
                            label: Text(_isSubmitting ? 'Enregistrement...' : 'Modifier'),
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
          ),
        ],
      ),
    );
  }
}

