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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    // Initialiser avec le mois en cours par défaut
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  void _updateRecurringDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
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

  Future<void> _submit() async {
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

      // Si récurrent, s'assurer que les dates sont du 1er au dernier jour du mois
      DateTime finalStartDate = _startDate!;
      DateTime finalEndDate = _endDate!;
      
      if (_isRecurring) {
        final now = DateTime.now();
        finalStartDate = DateTime(now.year, now.month, 1);
        finalEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Selection
                    Consumer<BudgetProvider>(
                      builder: (context, provider, child) {
                        final categories = provider.categories;
                        return DropdownButtonFormField<models.Category>(
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          value: _selectedCategory,
                          items: categories.map((category) {
                            return DropdownMenuItem<models.Category>(
                              value: category,
                              child: Row(
                                children: [
                                  Text(category.icon ?? '📦'),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isSubmitting ? null : (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            // Revalider le formulaire pour effacer le message d'erreur
                            _formKey.currentState?.validate();
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

                    // Start Date
                    InkWell(
                      onTap: _isSubmitting ? null : _selectStartDate,
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
                            color: _startDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // End Date
                    InkWell(
                      onTap: _isSubmitting ? null : _selectEndDate,
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
                            color: _endDate == null ? Colors.grey : Colors.black,
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
                      onChanged: (value) {
                        // Revalider le formulaire pour effacer le message d'erreur
                        _formKey.currentState?.validate();
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
                                if (_isRecurring) {
                                  _updateRecurringDates();
                                }
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
                        backgroundColor: AppTheme.primaryColor,
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

