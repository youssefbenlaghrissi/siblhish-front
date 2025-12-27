import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';
import 'recurrence_options_widget.dart';
import 'custom_snackbar.dart';

class EditTransactionModal extends StatefulWidget {
  final dynamic transaction;
  final Category? category;

  const EditTransactionModal({
    super.key,
    required this.transaction,
    this.category,
  });

  @override
  State<EditTransactionModal> createState() => _EditTransactionModalState();
}

class _EditTransactionModalState extends State<EditTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sourceController;
  late final TextEditingController _locationController;
  
  String? _selectedCategoryId;
  String _selectedPaymentMethod = 'CASH';
  late DateTime _selectedDate;
  bool _isRecurring = false;
  String? _recurrenceFrequency;
  DateTime? _recurrenceEndDate;
  List<int>? _recurrenceDaysOfWeek;
  int? _recurrenceDayOfMonth;
  int? _recurrenceDayOfYear;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final isIncome = widget.transaction is Income;
    final expense = !isIncome ? widget.transaction as Expense : null;
    final income = isIncome ? widget.transaction as Income : null;

    // Initialiser les contrôleurs avec les valeurs existantes
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _descriptionController = TextEditingController(text: expense?.description ?? income?.description ?? '');
    _sourceController = TextEditingController(text: income?.source ?? '');
    _locationController = TextEditingController(text: expense?.location ?? '');
    
    _selectedDate = widget.transaction.date;
    _selectedPaymentMethod = widget.transaction.paymentMethod;
    _isRecurring = widget.transaction.isRecurring;
    _recurrenceFrequency = widget.transaction.recurrenceFrequency;
    _recurrenceEndDate = widget.transaction.recurrenceEndDate;
    _recurrenceDaysOfWeek = widget.transaction.recurrenceDaysOfWeek;
    _recurrenceDayOfMonth = widget.transaction.recurrenceDayOfMonth;
    _recurrenceDayOfYear = widget.transaction.recurrenceDayOfYear;

    // Pour les dépenses, définir la catégorie sélectionnée en utilisant effectiveCategoryId
    if (!isIncome && expense != null) {
      _selectedCategoryId = expense.effectiveCategoryId.isNotEmpty 
          ? expense.effectiveCategoryId 
          : null;
    }

    // Charger les catégories à la demande (utilise le cache si déjà chargé)
    if (!isIncome) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await context.read<BudgetProvider>().loadCategoriesIfNeeded();
          // Une fois les catégories chargées, s'assurer que la catégorie sélectionnée est toujours valide
          if (mounted && expense != null) {
            final provider = context.read<BudgetProvider>();
            final effectiveId = expense.effectiveCategoryId;
            
            debugPrint('🔍 Recherche catégorie pour modification: effectiveId=$effectiveId, categoryName=${expense.category?.name}');
            debugPrint('📋 Catégories disponibles: ${provider.categories.map((c) => '${c.id}:${c.name}').join(', ')}');
            
            if (provider.categories.isNotEmpty) {
              Category? matchingCategory;
              
              // D'abord, essayer de trouver par ID
              if (effectiveId.isNotEmpty) {
                try {
                  matchingCategory = provider.categories.firstWhere(
                    (cat) => cat.id.toString() == effectiveId.toString(),
                  );
                } catch (e) {
                  // Si pas trouvé par ID, chercher par nom
                  if (expense.category != null) {
                    try {
                      matchingCategory = provider.categories.firstWhere(
                        (cat) => cat.name.toLowerCase() == expense.category!.name.toLowerCase(),
                      );
                    } catch (e) {
                      matchingCategory = null;
                    }
                  }
                }
              } else if (expense.category != null) {
                // Si pas d'ID, chercher par nom
                try {
                  matchingCategory = provider.categories.firstWhere(
                    (cat) => cat.name.toLowerCase() == expense.category!.name.toLowerCase(),
                  );
                } catch (e) {
                  matchingCategory = null;
                }
              }
              
              // Mettre à jour la catégorie sélectionnée si on a trouvé une correspondance
              if (mounted) {
                if (matchingCategory != null) {
                  final categoryId = matchingCategory.id;
                  if (_selectedCategoryId != categoryId) {
                    setState(() {
                      _selectedCategoryId = categoryId;
                    });
                  }
                } else {
                }
              }
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Preserve the time component from the current selected date
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
          _selectedDate.second,
        );
        debugPrint('📅 Date sélectionnée: $_selectedDate');
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        debugPrint('🕐 Heure sélectionnée: $_selectedDate');
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<BudgetProvider>();
      final amount = double.parse(_amountController.text);
      final isIncome = widget.transaction is Income;

      // Utiliser la date sélectionnée (avec l'heure actuelle si pas d'heure spécifique)
      DateTime finalDate = _selectedDate;
      
      // Si la date sélectionnée n'a pas d'heure (00:00:00), utiliser l'heure actuelle
      if (_selectedDate.hour == 0 && _selectedDate.minute == 0 && _selectedDate.second == 0) {
        final now = DateTime.now();
        finalDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          now.hour,
          now.minute,
          now.second,
        );
      }
      
      debugPrint('📅 Date sélectionnée: $_selectedDate');
      debugPrint('📅 Date originale transaction: ${widget.transaction.date}');
      debugPrint('📅 Date finale utilisée: $finalDate');
      debugPrint('📅 Date formatée pour JSON: ${finalDate.toIso8601String().split('.')[0]}');

      if (isIncome) {
        final income = Income(
          id: widget.transaction.id,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          date: finalDate,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          source: _sourceController.text.isEmpty ? null : _sourceController.text,
          isRecurring: _isRecurring,
          recurrenceFrequency: _recurrenceFrequency,
          recurrenceEndDate: _recurrenceEndDate,
          recurrenceDaysOfWeek: _recurrenceDaysOfWeek,
          recurrenceDayOfMonth: _recurrenceDayOfMonth,
          recurrenceDayOfYear: _recurrenceDayOfYear,
          userId: provider.currentUser!.id,
        );
        
        debugPrint('   ID: ${income.id}');
        debugPrint('   Montant: ${income.amount}');
        debugPrint('   Date: ${income.date}');
        debugPrint('   Source: ${income.source}');
        debugPrint('   Méthode de paiement: ${income.paymentMethod}');
        debugPrint('   Description: ${income.description}');
        debugPrint('   Récurrent: ${income.isRecurring}');
        debugPrint('   Fréquence récurrence: ${income.recurrenceFrequency}');
        debugPrint('   Date fin récurrence: ${income.recurrenceEndDate}');
        debugPrint('   Jours de la semaine: ${income.recurrenceDaysOfWeek}');
        debugPrint('   Jour du mois: ${income.recurrenceDayOfMonth}');
        debugPrint('   Jour de l\'année: ${income.recurrenceDayOfYear}');
        debugPrint('   User ID: ${income.userId}');
        debugPrint('   📋 JSON complet envoyé: ${income.toJson()}');
        
        await provider.updateIncome(income);
      } else {
        if (_selectedCategoryId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
        final expense = Expense(
          id: widget.transaction.id,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          date: finalDate,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          location: _locationController.text.isEmpty
              ? null
              : _locationController.text,
          isRecurring: _isRecurring,
          recurrenceFrequency: _recurrenceFrequency,
          recurrenceEndDate: _recurrenceEndDate,
          recurrenceDaysOfWeek: _recurrenceDaysOfWeek,
          recurrenceDayOfMonth: _recurrenceDayOfMonth,
          recurrenceDayOfYear: _recurrenceDayOfYear,
          categoryId: _selectedCategoryId!,
          userId: provider.currentUser!.id,
        );
        
        debugPrint('   ID: ${expense.id}');
        debugPrint('   Montant: ${expense.amount}');
        debugPrint('   Date: ${expense.date}');
        debugPrint('   Catégorie ID: ${expense.categoryId}');
        debugPrint('   Lieu: ${expense.location}');
        debugPrint('   Méthode de paiement: ${expense.paymentMethod}');
        debugPrint('   Description: ${expense.description}');
        debugPrint('   Récurrent: ${expense.isRecurring}');
        debugPrint('   Fréquence récurrence: ${expense.recurrenceFrequency}');
        debugPrint('   Date fin récurrence: ${expense.recurrenceEndDate}');
        debugPrint('   Jours de la semaine: ${expense.recurrenceDaysOfWeek}');
        debugPrint('   Jour du mois: ${expense.recurrenceDayOfMonth}');
        debugPrint('   Jour de l\'année: ${expense.recurrenceDayOfYear}');
        debugPrint('   User ID: ${expense.userId}');
        debugPrint('   📋 JSON complet envoyé: ${expense.toJson()}');
        
        await provider.updateExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: isIncome
                ? 'Revenu modifié avec succès'
                : 'Dépense modifiée avec succès',
            description: isIncome
                ? 'Votre revenu a été mis à jour'
                : 'Votre dépense a été mise à jour',
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
    final isIncome = widget.transaction is Income;
    final provider = context.watch<BudgetProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                  isIncome ? 'Modifier le revenu' : 'Modifier la dépense',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
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
                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
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

                    // Category (only for expenses)
                    if (!isIncome) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId != null &&
                                provider.categories.any((cat) => cat.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: provider.categories
                            .map<DropdownMenuItem<String>>((Category category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Text(category.icon ?? '📦'),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une catégorie';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Source (only for income)
                    if (isIncome) ...[
                      TextFormField(
                        controller: _sourceController,
                        decoration: const InputDecoration(
                          labelText: 'Source',
                          prefixIcon: Icon(Icons.source_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Payment Method
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Méthode de paiement',
                        prefixIcon: Icon(Icons.payment_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Espèces')),
                        DropdownMenuItem(
                            value: 'CREDIT_CARD', child: Text('Carte bancaire')),
                        DropdownMenuItem(
                            value: 'BANK_TRANSFER', child: Text('Virement')),
                        DropdownMenuItem(
                            value: 'MOBILE_PAYMENT', child: Text('Mobile')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Time
                    InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        child: Text(
                          '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
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

                    // Location (only for expenses)
                    if (!isIncome) ...[
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lieu (optionnel)',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Recurring
                    CheckboxListTile(
                      title: const Text('Transaction récurrente'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value ?? false;
                          if (!_isRecurring) {
                            _recurrenceFrequency = null;
                            _recurrenceEndDate = null;
                            _recurrenceDaysOfWeek = null;
                            _recurrenceDayOfMonth = null;
                            _recurrenceDayOfYear = null;
                          }
                        });
                      },
                    ),

                    if (_isRecurring) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _recurrenceFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Fréquence',
                          prefixIcon: Icon(Icons.repeat_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'DAILY', child: Text('Quotidien')),
                          DropdownMenuItem(value: 'WEEKLY', child: Text('Hebdomadaire')),
                          DropdownMenuItem(value: 'MONTHLY', child: Text('Mensuel')),
                          DropdownMenuItem(value: 'YEARLY', child: Text('Annuel')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _recurrenceFrequency = value;
                            _recurrenceEndDate = null;
                            _recurrenceDaysOfWeek = null;
                            _recurrenceDayOfMonth = null;
                            _recurrenceDayOfYear = null;
                          });
                        },
                        validator: (value) {
                          if (_isRecurring && value == null) {
                            return 'Veuillez sélectionner une fréquence';
                          }
                          return null;
                        },
                      ),
                      if (_recurrenceFrequency != null) ...[
                        const SizedBox(height: 20),
                        RecurrenceOptionsWidget(
                          frequency: _recurrenceFrequency,
                          initialEndDate: _recurrenceEndDate,
                          initialDaysOfWeek: _recurrenceDaysOfWeek,
                          initialDayOfMonth: _recurrenceDayOfMonth,
                          initialDayOfYear: _recurrenceDayOfYear,
                          onEndDateChanged: (date) {
                            setState(() {
                              _recurrenceEndDate = date;
                            });
                          },
                          onDaysOfWeekChanged: (days) {
                            setState(() {
                              _recurrenceDaysOfWeek = days;
                            });
                          },
                          onDayOfMonthChanged: (day) {
                            setState(() {
                              _recurrenceDayOfMonth = day;
                            });
                          },
                          onDayOfYearChanged: (day) {
                            setState(() {
                              _recurrenceDayOfYear = day;
                            });
                          },
                        ),
                      ],
                    ],

                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isIncome
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
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

