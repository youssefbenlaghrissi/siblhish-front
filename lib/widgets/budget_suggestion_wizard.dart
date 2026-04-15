import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/color_utils.dart';
import '../services/budget_suggestion_service.dart';
import '../screens/budget_suggestion_results_screen.dart';
import 'package:intl/intl.dart';

class BudgetSuggestionWizard extends StatefulWidget {
  const BudgetSuggestionWizard({super.key});

  @override
  State<BudgetSuggestionWizard> createState() => _BudgetSuggestionWizardState();
}

class _BudgetSuggestionWizardState extends State<BudgetSuggestionWizard> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  void _log(String message) {
    if (kDebugMode) debugPrint('[BudgetSuggestionWizard] $message');
  }

  // Step 1: Revenu et situation
  final TextEditingController _incomeController = TextEditingController();
  String? _selectedSituation;
  String? _selectedLocation; // 'ville' ou 'campagne'
  
  // Erreurs de validation
  String? _incomeError;
  String? _situationError;
  String? _locationError;
  String? _categoriesError;
  bool _hasAttemptedSubmit = false;

  // Step 2: Catégories
  final Set<String> _selectedCategories = {};
  
  // État de chargement
  bool _isLoading = false;

  @override
  void dispose() {
    _incomeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _validateStep1() {
    setState(() {
      _hasAttemptedSubmit = true;
      _incomeError = null;
      _situationError = null;
      _locationError = null;

      if (_incomeController.text.trim().isEmpty) {
        _incomeError = 'Le revenu mensuel est requis';
      } else {
        final income = double.tryParse(_incomeController.text.trim());
        if (income == null || income <= 0) {
          _incomeError = 'Veuillez entrer un montant valide';
        }
      }

      if (_selectedSituation == null) {
        _situationError = 'Veuillez sélectionner votre situation';
      }

      if (_selectedLocation == null) {
        _locationError = 'Veuillez sélectionner votre localisation';
      }
    });
  }

  void _validateStep2() {
    setState(() {
      _hasAttemptedSubmit = true;
      _categoriesError = null;

      if (_selectedCategories.isEmpty) {
        _categoriesError = 'Veuillez sélectionner au moins une catégorie';
      }
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      _validateStep1();
      if (_incomeError != null || 
          _situationError != null || 
          _locationError != null) {
        return;
      }
    } else if (_currentStep == 1) {
      _validateStep2();
      if (_categoriesError != null) {
        return;
      }
    }

    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
        _hasAttemptedSubmit = false; // Réinitialiser pour le step suivant
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    _log('_submit() appelé');
    
    if (_isLoading) {
      _log('Déjà en cours de chargement');
      return;
    }
    
    _log('Données: revenu=${_incomeController.text}, situation=$_selectedSituation, localisation=$_selectedLocation, categories=${_selectedCategories.length}');
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final income = double.tryParse(_incomeController.text.trim());
      if (income == null || income <= 0) {
        _log('Revenu invalide');
        throw Exception('Veuillez entrer un revenu valide');
      }
      
      if (_selectedSituation == null || _selectedLocation == null) {
        _log('Situation ou localisation manquante');
        throw Exception('Veuillez sélectionner votre situation et localisation');
      }
      
      if (_selectedCategories.isEmpty) {
        _log('Aucune catégorie sélectionnée');
        throw Exception('Veuillez sélectionner au moins une catégorie');
      }
      
      // Convertir les IDs de String à int
      final categoryIds = _selectedCategories
          .map((id) {
            try {
              return int.parse(id);
            } catch (e) {
              _log('Erreur parsing ID: $id');
              throw Exception('Erreur lors de la conversion des catégories');
            }
          })
          .toList();
      
      _log('Appel API avec ${categoryIds.length} catégories: $categoryIds');
      
      // Appeler l'API
      final result = await BudgetSuggestionService.suggestBudgets(
        monthlyIncome: income,
        situation: _selectedSituation!,
        location: _selectedLocation!,
        categoryIds: categoryIds,
      );
      
      _log('Réponse API reçue: ${result.keys}');
      
      if (mounted) {
        _log('Navigation vers l\'écran de résultats');
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetSuggestionResultsScreen(
              result: result,
              monthlyIncome: income,
            ),
          ),
        );
      } else {
        _log('Widget non monté, navigation annulée');
      }
    } catch (e, stackTrace) {
      _log('ERREUR: $e');
      _log('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _log('État de chargement réinitialisé');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final categories = provider.categories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

          // Header with steps indicator
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes catégories',
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
                const SizedBox(height: 20),
                // Steps indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStepIndicator(0, 'Situation'),
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: _currentStep > 0 
                            ? AppTheme.primaryColor 
                            : Colors.grey[300],
                      ),
                    ),
                    _buildStepIndicator(1, 'Catégories'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(categories),
              ],
            ),
          ),

          // Footer buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Précédent',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentStep > 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentStep == 1 ? 'Terminer' : 'Suivant',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? AppTheme.primaryColor
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppTheme.primaryColor : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenu mensuel
          Text(
            'Revenu mensuel *',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_hasAttemptedSubmit) {
                setState(() {
                  if (_incomeController.text.trim().isEmpty) {
                    _incomeError = 'Le revenu mensuel est requis';
                  } else {
                    final income = double.tryParse(_incomeController.text.trim());
                    if (income == null || income <= 0) {
                      _incomeError = 'Veuillez entrer un montant valide';
                    } else {
                      _incomeError = null;
                    }
                  }
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Ex: 10000',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Align(
                  widthFactor: 1.0,
                  child: Text(
                    'MAD',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 50),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _incomeError != null ? Colors.red : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _incomeError != null ? Colors.red : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _incomeError != null ? Colors.red : AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              errorText: _hasAttemptedSubmit ? _incomeError : null,
            ),
          ),
          const SizedBox(height: 24),

          // Situation
          Text(
            'Situation *',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSituationChip('Célibataire', Icons.person_outline_rounded),
              _buildSituationChip('En couple', Icons.people_outline),
              _buildSituationChip('Famille', Icons.family_restroom_rounded),
              _buildSituationChip('Étudiant', Icons.school_outlined),
            ],
          ),
          if (_hasAttemptedSubmit && _situationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _situationError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Localisation
          Text(
            'Localisation *',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildLocationOption('Ville', Icons.location_city),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLocationOption('Campagne', Icons.nature),
              ),
            ],
          ),
          if (_hasAttemptedSubmit && _locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSituationChip(String situation, IconData icon) {
    final isSelected = _selectedSituation == situation;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(situation),
          const SizedBox(width: 6),
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSituation = selected ? situation : null;
          if (_hasAttemptedSubmit && _selectedSituation != null) {
            _situationError = null;
          }
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      showCheckmark: true,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? AppTheme.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
    );
  }

  Widget _buildLocationOption(String label, IconData icon) {
    final isSelected = _selectedLocation == label.toLowerCase();
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocation = label.toLowerCase();
          if (_hasAttemptedSubmit && _selectedLocation != null) {
            _locationError = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(List<Category> categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez vos catégories de dépense *',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cochez les catégories pour lesquelles vous souhaitez créer un budget',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (_hasAttemptedSubmit && _categoriesError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _categoriesError!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune catégorie disponible',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...categories.map((category) {
              final isSelected = _selectedCategories.contains(category.id);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category.id);
                      } else {
                        _selectedCategories.add(category.id);
                      }
                      if (_hasAttemptedSubmit && _selectedCategories.isNotEmpty) {
                        _categoriesError = null;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Checkbox circulaire
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Icône de catégorie
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.icon ?? '📦',
                            style: TextStyle(
                              fontSize: 24,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nom de la catégorie
                        Expanded(
                          child: Text(
                            category.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

