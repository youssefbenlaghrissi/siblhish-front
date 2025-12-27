import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/goal.dart';
import '../models/category.dart' as models;
import '../theme/app_theme.dart';
import 'custom_snackbar.dart';

class EditGoalModal extends StatefulWidget {
  final Goal goal;

  const EditGoalModal({super.key, required this.goal});

  @override
  State<EditGoalModal> createState() => _EditGoalModalState();
}

class _EditGoalModalState extends State<EditGoalModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentAmountController;
  DateTime? _targetDate;
  models.Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _descriptionController = TextEditingController(text: widget.goal.description ?? '');
    _targetAmountController = TextEditingController(text: widget.goal.targetAmount.toString());
    _currentAmountController = TextEditingController(text: widget.goal.currentAmount.toString());
    _targetDate = widget.goal.targetDate;
    // La catégorie sera chargée dans le build via Consumer
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<BudgetProvider>();
      final newCurrentAmount = double.parse(_currentAmountController.text);
      debugPrint('📝 EditGoalModal - currentAmount saisi: $newCurrentAmount');
      debugPrint('📝 EditGoalModal - currentAmount original: ${widget.goal.currentAmount}');
      final updatedGoal = Goal(
        id: widget.goal.id,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: newCurrentAmount,
        targetDate: _targetDate,
        isAchieved: widget.goal.isAchieved,
        userId: widget.goal.userId,
        categoryId: _selectedCategory?.id,
      );
      await provider.updateGoal(updatedGoal);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Objectif modifié avec succès',
            description: 'Votre objectif a été mis à jour',
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
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Modifier l\'objectif',
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
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'objectif',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Category Selection (optional)
                    Consumer<BudgetProvider>(
                      builder: (context, provider, child) {
                        // Charger les catégories si nécessaire
                        if (!provider.categoriesLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            provider.loadCategoriesIfNeeded();
                          });
                        }
                        
                        final categories = provider.categories;
                        // Trouver la catégorie sélectionnée si elle existe (une seule fois)
                        models.Category? currentSelectedCategory = _selectedCategory;
                        if (currentSelectedCategory == null && widget.goal.categoryId != null && categories.isNotEmpty) {
                          try {
                            final foundCategory = categories.firstWhere(
                              (cat) => cat.id == widget.goal.categoryId,
                            );
                            currentSelectedCategory = foundCategory;
                            // Initialiser _selectedCategory dans un postFrameCallback pour éviter setState pendant build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _selectedCategory == null) {
                                setState(() {
                                  _selectedCategory = foundCategory;
                                });
                              }
                            });
                          } catch (e) {
                            // Catégorie non trouvée, garder null
                          }
                        }
                        
                        return DropdownButtonFormField<models.Category?>(
                          decoration: const InputDecoration(
                            labelText: 'Catégorie (optionnel)',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          value: currentSelectedCategory ?? _selectedCategory,
                          items: [
                            const DropdownMenuItem<models.Category?>(
                              value: null,
                              child: Text('Aucune catégorie'),
                            ),
                            ...categories.map((category) {
                              return DropdownMenuItem<models.Category?>(
                                value: category,
                                child: Row(
                                  children: [
                                    Text(category.icon ?? '📦'),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: _isSubmitting ? null : (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Current Amount
                    TextFormField(
                      controller: _currentAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant actuel',
                        prefixText: 'MAD ',
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un montant';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) < 0) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Target Amount
                    TextFormField(
                      controller: _targetAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant cible',
                        prefixText: 'MAD ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un montant';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Target Date
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date cible (optionnel)',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          _targetDate != null
                              ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                              : 'Sélectionner une date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFF6B6B),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Enregistrer',
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

