import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../models/category.dart' as models;
import '../theme/app_theme.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/date_formatter.dart';

class AddBudgetModal extends StatefulWidget {
  const AddBudgetModal({super.key});

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  models.Category? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false; // Flag pour savoir si l'utilisateur a déjà cliqué sur "Ajouter"

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    // Initialiser avec le mois en cours par défaut
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non sélectionnée';
    return DateFormatter.formatDate(date);
  }

  Future<void> _submit() async {
    // Marquer que l'utilisateur a tenté de soumettre
    setState(() {
      _hasAttemptedSubmit = true;
    });
    
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
      if (provider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Conserver les dates choisies par l'utilisateur (ne pas les remplacer par le mois courant)
      final DateTime finalStartDate = _startDate!;
      final DateTime finalEndDate = _endDate!;

      final budget = Budget(
        id: '', // Sera généré par le backend
        userId: provider.currentUser!.id,
        categoryId: _selectedCategory!.id,
        amount: double.parse(_amountController.text),
        startDate: finalStartDate,
        endDate: finalEndDate,
        isRecurring: _isRecurring,
      );

      await provider.addBudget(budget);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Budget créé avec succès',
            description: 'Le budget pour ${_selectedCategory!.name} a été créé',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nouveau Budget',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                autovalidateMode: _hasAttemptedSubmit ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Selection
                    Consumer<BudgetProvider>(
                      builder: (context, provider, child) {
                        final categories = provider.categories;
                        final budgets = provider.budgets;
                        // Catégories qui ont déjà un budget sur la période sélectionnée
                        final categoryIdsWithBudget = <String>{};
                        if (_startDate != null && _endDate != null) {
                          for (final b in budgets) {
                            if (b.categoryId == null) continue;
                            if (b.startDate == null || b.endDate == null) continue;
                            final overlaps = !b.startDate!.isAfter(_endDate!) && !b.endDate!.isBefore(_startDate!);
                            if (overlaps) categoryIdsWithBudget.add(b.categoryId!);
                          }
                        }
                        // Ne pas garder une catégorie déjà pourvue d'un budget comme sélectionnée
                        final effectiveValue = _selectedCategory != null && categoryIdsWithBudget.contains(_selectedCategory!.id)
                            ? null
                            : _selectedCategory;
                        if (effectiveValue == null && _selectedCategory != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selectedCategory = null);
                          });
                        }
                        return DropdownButtonFormField<models.Category>(
                          decoration: const InputDecoration(
                            labelText: 'Catégorie *',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          value: effectiveValue,
                          items: categories.map((category) {
                            final hasBudget = categoryIdsWithBudget.contains(category.id);
                            return DropdownMenuItem<models.Category>(
                              value: category,
                              enabled: !hasBudget,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxW = constraints.maxWidth;
                                  final width = maxW.isFinite && maxW > 0
                                      ? maxW
                                      : 260.0;
                                  final content = ClipRect(
                                    child: SizedBox(
                                      width: width,
                                      child: Row(
                                        children: [
                                          DefaultTextStyle(
                                            style: DefaultTextStyle.of(context).style.copyWith(
                                              color: hasBudget ? Colors.grey : null,
                                            ),
                                            child: Text(category.icon ?? '📦'),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DefaultTextStyle(
                                              style: DefaultTextStyle.of(context).style.copyWith(
                                                color: hasBudget ? Colors.grey : null,
                                              ),
                                              child: Text(
                                                category.name,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          if (hasBudget) ...[
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Budget déjà créé',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                  return hasBudget
                                      ? Opacity(opacity: 0.7, child: content)
                                      : content;
                                },
                              ),
                            );
                          }).toList(),
                          onChanged: _isSubmitting ? null : (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            if (_hasAttemptedSubmit) {
                              _formKey.currentState?.validate();
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner une catégorie';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date de début (désactivé : mois courant)
                    Opacity(
                      opacity: 0.7,
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
                    const SizedBox(height: 20),

                    // Date de fin (désactivé : mois courant)
                    Opacity(
                      opacity: 0.7,
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
                    const SizedBox(height: 20),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant cible *',
                        prefixText: 'MAD ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                      onChanged: (value) {
                        // Revalider après la saisie si l'utilisateur a déjà tenté de soumettre
                        if (_hasAttemptedSubmit) {
                          _formKey.currentState?.validate();
                        }
                      },
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

                    // Recurring Budget Checkbox (dernier élément avant le bouton)
                    CheckboxListTile(
                      title: const Text('Budget récurrent'),
                      value: _isRecurring,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _isRecurring = value ?? false;
                                // Ne pas modifier les dates : garder celles choisies par l'utilisateur
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

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.incomeColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Créer le budget',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

