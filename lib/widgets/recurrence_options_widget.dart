import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RecurrenceOptionsWidget extends StatefulWidget {
  final String? frequency; // DAILY, WEEKLY, MONTHLY, YEARLY
  final Function(DateTime?) onEndDateChanged;
  final Function(List<int>?) onDaysOfWeekChanged;
  final Function(int?) onDayOfMonthChanged;
  final Function(int?) onDayOfYearChanged;
  final DateTime? initialEndDate;
  final List<int>? initialDaysOfWeek;
  final int? initialDayOfMonth;
  final int? initialDayOfYear;
  /// Message d'erreur affiché au-dessus de la liste des jours (ex: "Veuillez sélectionner au moins un jour")
  final String? weeklyDaysErrorText;

  const RecurrenceOptionsWidget({
    super.key,
    required this.frequency,
    required this.onEndDateChanged,
    required this.onDaysOfWeekChanged,
    required this.onDayOfMonthChanged,
    required this.onDayOfYearChanged,
    this.initialEndDate,
    this.initialDaysOfWeek,
    this.initialDayOfMonth,
    this.initialDayOfYear,
    this.weeklyDaysErrorText,
  });

  @override
  State<RecurrenceOptionsWidget> createState() => _RecurrenceOptionsWidgetState();
}

class _RecurrenceOptionsWidgetState extends State<RecurrenceOptionsWidget> {
  late String _recurrenceType; // 'always' ou 'until'
  DateTime? _endDate;
  late List<int> _selectedDaysOfWeek; // 1=Monday, 7=Sunday
  late int _dayOfMonth;
  late int _dayOfYear;

  final List<String> _weekDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  static int _defaultDayOfYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return now.difference(startOfYear).inDays + 1;
  }

  @override
  void initState() {
    super.initState();
    _recurrenceType = widget.initialEndDate != null ? 'until' : 'always';
    _endDate = widget.initialEndDate;
    _selectedDaysOfWeek = widget.initialDaysOfWeek ?? [];
    _dayOfMonth = widget.initialDayOfMonth ?? DateTime.now().day;
    if (widget.initialDayOfYear != null) {
      _dayOfYear = widget.initialDayOfYear!;
    } else {
      _dayOfYear = _defaultDayOfYear();
    }
    // Synchroniser les valeurs affichées avec le parent pour qu'elles soient envoyées à l'API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.frequency) {
        case 'WEEKLY':
          widget.onDaysOfWeekChanged(
            _selectedDaysOfWeek.isEmpty ? null : _selectedDaysOfWeek,
          );
          break;
        case 'MONTHLY':
          widget.onDayOfMonthChanged(_dayOfMonth);
          break;
        case 'YEARLY':
          widget.onDayOfYearChanged(_dayOfYear);
          break;
      }
    });
  }

  @override
  void didUpdateWidget(RecurrenceOptionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frequency != widget.frequency) {
      switch (widget.frequency) {
        case 'WEEKLY':
          _selectedDaysOfWeek = widget.initialDaysOfWeek ?? [];
          break;
        case 'MONTHLY':
          _dayOfMonth = widget.initialDayOfMonth ?? DateTime.now().day;
          break;
        case 'YEARLY':
          _dayOfYear = widget.initialDayOfYear ?? _defaultDayOfYear();
          break;
      }
      // Différer les callbacks au prochain frame pour éviter setState pendant la mise à jour (assertion referenceBox.attached)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (widget.frequency) {
          case 'WEEKLY':
            widget.onDaysOfWeekChanged(
              _selectedDaysOfWeek.isEmpty ? null : _selectedDaysOfWeek,
            );
            break;
          case 'MONTHLY':
            widget.onDayOfMonthChanged(_dayOfMonth);
            break;
          case 'YEARLY':
            widget.onDayOfYearChanged(_dayOfYear);
            break;
        }
      });
    }
  }

  String _formatDayOfYear(int dayOfYear) {
    final currentYear = DateTime.now().year;
    final date = DateTime(currentYear, 1, 1).add(Duration(days: dayOfYear - 1));
    return '${date.day}/${date.month}';
  }

  String _getRecurrenceDescription() {
    if (widget.frequency == null) return '';
    
    String description = '';
    
    switch (widget.frequency) {
      case 'DAILY':
        description = 'Cette transaction sera créée automatiquement chaque jour';
        break;
      case 'WEEKLY':
        if (_selectedDaysOfWeek.isEmpty) {
          description = 'Cette transaction sera créée automatiquement chaque semaine';
        } else {
          final days = _selectedDaysOfWeek.map((d) => _weekDays[d - 1]).join(', ');
          description = 'Cette transaction sera créée automatiquement chaque $days';
        }
        break;
      case 'MONTHLY':
        description = 'Cette transaction sera créée automatiquement le $_dayOfMonth de chaque mois';
        break;
      case 'YEARLY':
        description = 'Cette transaction sera créée automatiquement le ${_formatDayOfYear(_dayOfYear)} de chaque année';
        break;
      default:
        return '';
    }
    
    if (_recurrenceType == 'until' && _endDate != null) {
      description += ' jusqu\'au ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
    } else if (_recurrenceType == 'always') {
      description += ' indéfiniment';
    }
    
    description += '.';
    
    return description;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frequency == null) return const SizedBox.shrink();

    final description = _getRecurrenceDescription();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alerte descriptive du comportement
        if (description.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                    description,
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
        
        // Type de récurrence (Toujours / Jusqu'à une date)
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Toujours'),
                value: 'always',
                groupValue: _recurrenceType,
                onChanged: (value) {
                  setState(() {
                    _recurrenceType = value!;
                    _endDate = null;
                    widget.onEndDateChanged(null);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Jusqu\'à une date'),
                value: 'until',
                groupValue: _recurrenceType,
                onChanged: (value) {
                  setState(() {
                    _recurrenceType = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        // Sélecteur de date si "Jusqu'à une date"
        if (_recurrenceType == 'until') ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                  widget.onEndDateChanged(picked);
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date limite',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(
                _endDate != null
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'Sélectionner une date',
              ),
            ),
          ),
        ],

        // Options spécifiques selon la fréquence
        if (widget.frequency == 'WEEKLY') ...[
          const SizedBox(height: 20),
          if (widget.weeklyDaysErrorText != null) ...[
            Text(
              widget.weeklyDaysErrorText!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Jours de la semaine',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1=Monday, 7=Sunday
              final isSelected = _selectedDaysOfWeek.contains(dayIndex);
              return FilterChip(
                label: Text(_weekDays[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDaysOfWeek.add(dayIndex);
                    } else {
                      _selectedDaysOfWeek.remove(dayIndex);
                    }
                    _selectedDaysOfWeek.sort();
                    widget.onDaysOfWeekChanged(
                      _selectedDaysOfWeek.isEmpty ? null : _selectedDaysOfWeek,
                    );
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],

        if (widget.frequency == 'MONTHLY') ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_dayOfMonth',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _dayOfMonth > 1
                          ? () {
                              setState(() {
                                _dayOfMonth = _dayOfMonth - 1;
                                widget.onDayOfMonthChanged(_dayOfMonth);
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _dayOfMonth < 31
                          ? () {
                              setState(() {
                                _dayOfMonth = _dayOfMonth + 1;
                                widget.onDayOfMonthChanged(_dayOfMonth);
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (widget.frequency == 'YEARLY') ...[
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              // Convertir le jour de l'année en date pour le sélecteur
              final currentYear = DateTime.now().year;
              final selectedDate = DateTime(currentYear, 1, 1)
                  .add(Duration(days: _dayOfYear - 1));
              
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(currentYear, 1, 1),
                lastDate: DateTime(currentYear, 12, 31),
              );
              if (picked != null) {
                final startOfYear = DateTime(picked.year, 1, 1);
                final newDayOfYear = picked.difference(startOfYear).inDays + 1;
                setState(() {
                  _dayOfYear = newDayOfYear;
                  widget.onDayOfYearChanged(_dayOfYear);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDayOfYear(_dayOfYear),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

