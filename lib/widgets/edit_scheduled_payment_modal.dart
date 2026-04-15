import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/scheduled_payment.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'custom_snackbar.dart';
import 'recurrence_options_widget.dart';
import 'auto_generated_badge.dart';

class EditScheduledPaymentModal extends StatefulWidget {
  final ScheduledPayment payment;
  final Category? category;

  const EditScheduledPaymentModal({
    super.key,
    required this.payment,
    this.category,
  });

  @override
  State<EditScheduledPaymentModal> createState() => _EditScheduledPaymentModalState();
}

class _EditScheduledPaymentModalState extends State<EditScheduledPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _beneficiaryController;

  String? _selectedCategoryId;
  String _selectedPaymentMethod = 'CASH';
  late DateTime _selectedDate;
  bool _isRecurring = false;
  String? _recurrenceFrequency;
  DateTime? _recurrenceEndDate;
  List<int>? _recurrenceDaysOfWeek;
  int? _recurrenceDayOfMonth;
  int? _recurrenceDayOfYear;
  String _notificationOption = 'NONE';
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;
  bool _showWeeklyDaysError = false;

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs avec les valeurs existantes
    _nameController = TextEditingController(text: widget.payment.name);
    _amountController = TextEditingController(text: widget.payment.amount.toString());
    _beneficiaryController = TextEditingController(text: widget.payment.beneficiary ?? '');
    
    _selectedDate = widget.payment.dueDate;
    _selectedPaymentMethod = widget.payment.paymentMethod;
    _isRecurring = widget.payment.isRecurring;
    _recurrenceFrequency = widget.payment.recurrenceFrequency;
    _recurrenceEndDate = widget.payment.recurrenceEndDate;
    _recurrenceDaysOfWeek = widget.payment.recurrenceDaysOfWeek;
    _recurrenceDayOfMonth = widget.payment.recurrenceDayOfMonth;
    _recurrenceDayOfYear = widget.payment.recurrenceDayOfYear;
    _notificationOption = widget.payment.notificationOption;
    _selectedCategoryId = widget.payment.categoryId;

    // Charger les catégories à la demande (utilise le cache si déjà chargé)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await context.read<BudgetProvider>().loadCategoriesIfNeeded();
        // Une fois les catégories chargées, s'assurer que la catégorie sélectionnée est toujours valide
        if (mounted) {
          final provider = context.read<BudgetProvider>();
          if (provider.categories.isNotEmpty && _selectedCategoryId != null) {
            // Vérifier que la catégorie existe toujours dans la liste
            final categoryExists = provider.categories.any((cat) => cat.id == _selectedCategoryId);
            if (!categoryExists) {
              // Si la catégorie n'existe pas, essayer de la retrouver par ID
              final matchingCategory = provider.categories.firstWhere(
                (cat) => cat.id.toString() == _selectedCategoryId.toString(),
                orElse: () => provider.categories.first,
              );
              setState(() {
                _selectedCategoryId = matchingCategory.id;
              });
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // En modification, autoriser les dates passées pour garder ou changer la date d'échéance
    final firstDate = today.subtract(const Duration(days: 365 * 2));
    final lastDate = today.add(const Duration(days: 365 * 5));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(firstDate)
          ? firstDate
          : _selectedDate.isAfter(lastDate)
              ? lastDate
              : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

  Future<void> _submit() async {
    setState(() {
      _hasAttemptedSubmit = true;
    });
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    if (_isRecurring && _recurrenceFrequency == 'WEEKLY' &&
        (_recurrenceDaysOfWeek == null || _recurrenceDaysOfWeek!.isEmpty)) {
      setState(() {
        _showWeeklyDaysError = true;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showWeeklyDaysError = false;
    });

    try {
      final provider = context.read<BudgetProvider>();
      
      // Utiliser la date sélectionnée avec l'heure actuelle si pas d'heure spécifique
      DateTime finalDate = _selectedDate;
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
      

      final payment = ScheduledPayment(
        id: widget.payment.id,
        name: _nameController.text,
        categoryId: _selectedCategoryId!,
        autoGenerated: widget.payment.autoGenerated,
        paymentMethod: _selectedPaymentMethod,
        amount: double.parse(_amountController.text),
        beneficiary: _beneficiaryController.text.isEmpty ? null : _beneficiaryController.text,
        dueDate: finalDate,
        isRecurring: _isRecurring,
        recurrenceFrequency: _isRecurring ? _recurrenceFrequency : null,
        recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        recurrenceDaysOfWeek: _isRecurring && _recurrenceFrequency == 'WEEKLY' ? _recurrenceDaysOfWeek : null,
        recurrenceDayOfMonth: _isRecurring && _recurrenceFrequency == 'MONTHLY' ? _recurrenceDayOfMonth : null,
        recurrenceDayOfYear: _isRecurring && _recurrenceFrequency == 'YEARLY' ? _recurrenceDayOfYear : null,
        notificationOption: _notificationOption,
        userId: provider.currentUser!.id,
        isPaid: widget.payment.isPaid, // Préserver le statut de paiement
      );


      await provider.updateScheduledPayment(payment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Paiement planifié modifié avec succès',
            description: 'Le paiement planifié a été mis à jour',
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
    final provider = context.watch<BudgetProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                        'Modifier le paiement planifié',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.payment.autoGenerated) ...[
                        const SizedBox(height: 10),
                        const AutoGeneratedBadge(),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: _hasAttemptedSubmit ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du paiement *',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Montant
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant *',
                        prefixText: 'MAD ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: TextInputType.number,
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
                    const SizedBox(height: 16),

                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId != null &&
                              provider.categories.any((cat) => cat.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: provider.categories.map<DropdownMenuItem<String>>((Category category) {
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
                    const SizedBox(height: 16),

                    // Bénéficiaire
                    TextFormField(
                      controller: _beneficiaryController,
                      decoration: const InputDecoration(
                        labelText: 'Bénéficiaire (optionnel)',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Méthode de paiement
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Moyen de paiement',
                        prefixIcon: Icon(Icons.payment_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Espèces')),
                        DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Carte bancaire')),
                        DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Virement')),
                        DropdownMenuItem(value: 'MOBILE_PAYMENT', child: Text('Mobile')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date d'échéance
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'échéance',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Heure
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
                    const SizedBox(height: 16),

                    // Récurrent
                    CheckboxListTile(
                      title: const Text('Paiement récurrent'),
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
                      DropdownButtonFormField<String>(
                        value: _recurrenceFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Fréquence *',
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
                            if (value != 'WEEKLY') _recurrenceDaysOfWeek = null;
                            if (value != 'MONTHLY') _recurrenceDayOfMonth = null;
                            if (value != 'YEARLY') _recurrenceDayOfYear = null;
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
                          startDate: _selectedDate,
                          initialEndDate: _recurrenceEndDate,
                          initialDaysOfWeek: _recurrenceDaysOfWeek,
                          initialDayOfMonth: _recurrenceDayOfMonth,
                          initialDayOfYear: _recurrenceDayOfYear,
                          weeklyDaysErrorText: _showWeeklyDaysError ? 'Veuillez sélectionner au moins un jour' : null,
                          onEndDateChanged: (date) {
                            setState(() {
                              _recurrenceEndDate = date;
                            });
                          },
                          onDaysOfWeekChanged: (days) {
                            setState(() {
                              _recurrenceDaysOfWeek = days;
                              _showWeeklyDaysError = false;
                              if (_hasAttemptedSubmit) _formKey.currentState?.validate();
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
                      const SizedBox(height: 16),
                    ],

                    // Notification
                    DropdownButtonFormField<String>(
                      value: _notificationOption,
                      decoration: const InputDecoration(
                        labelText: 'Rappel',
                        prefixIcon: Icon(Icons.notifications_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NONE', child: Text('Aucun')),
                        DropdownMenuItem(value: 'ON_DUE_DATE', child: Text('À la date d\'échéance')),
                        DropdownMenuItem(value: 'ONE_DAY_BEFORE', child: Text('1 jour avant')),
                        DropdownMenuItem(value: 'THREE_DAYS_BEFORE', child: Text('3 jours avant')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _notificationOption = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    // Bouton Enregistrer
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
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

