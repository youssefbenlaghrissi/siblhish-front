import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../providers/budget_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';
import 'recurrence_options_widget.dart';
import 'custom_snackbar.dart';

class AddTransactionModal extends StatefulWidget {
  final bool? isIncome;

  const AddTransactionModal({super.key, this.isIncome});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _selectedCategoryId;
  String _selectedPaymentMethod = 'CASH';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String? _recurrenceFrequency;
  DateTime? _recurrenceEndDate;
  List<int>? _recurrenceDaysOfWeek;
  int? _recurrenceDayOfMonth;
  int? _recurrenceDayOfYear;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Charger les catégories à la demande (utilise le cache si déjà chargé)
    if (widget.isIncome != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BudgetProvider>().loadCategoriesIfNeeded();
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
        // Préserver l'heure existante lors du changement de date
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
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
      final amount = double.parse(_amountController.text);

      if (widget.isIncome == true) {
        final income = Income(
          id: _uuid.v4(),
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          date: _selectedDate,
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
        await provider.addIncome(income);
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
          id: _uuid.v4(),
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          date: _selectedDate,
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
        await provider.addExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: widget.isIncome == true
                ? 'Revenu ajouté avec succès'
                : 'Dépense ajoutée avec succès',
            description: widget.isIncome == true
                ? 'Votre revenu a été enregistré'
                : 'Votre dépense a été enregistrée',
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
    final isIncome = widget.isIncome ?? false;
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
                  isIncome ? 'Nouveau revenu' : 'Nouvelle dépense',
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
                            // Réinitialiser les options spécifiques lors du changement de fréquence
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
                              'Ajouter',
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

