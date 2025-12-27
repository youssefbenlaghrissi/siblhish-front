import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../services/favorite_service.dart';
import '../utils/color_utils.dart';
import 'custom_snackbar.dart';

class EditCategoryColorModal extends StatefulWidget {
  final Category category;

  const EditCategoryColorModal({super.key, required this.category});

  @override
  State<EditCategoryColorModal> createState() => _EditCategoryColorModalState();
}

class _EditCategoryColorModalState extends State<EditCategoryColorModal> {
  late String _selectedColor;

  final List<String> _colors = [
    // Rouges et roses
    '#FF6B6B', '#FF5252', '#FF1744', '#E91E63', '#F06292', '#F48FB1', '#EC407A', '#C2185B',
    // Oranges
    '#FF9800', '#FF5722', '#FF7043', '#FF8A65', '#FF9F43', '#FFA502', '#FF6348', '#FF6F00',
    // Jaunes
    '#FFC107', '#FFD54F', '#FFE082', '#FFEAA7', '#F7DC6F', '#FDD835', '#FBC02D', '#F9A825',
    // Verts
    '#4CAF50', '#66BB6A', '#81C784', '#A5D6A7', '#C8E6C9', '#2ED573', '#00E676', '#00C853',
    // Verts clairs
    '#96CEB4', '#98D8C8', '#A8E6CF', '#B8E6B8', '#C8E6C8', '#D4EDDA', '#E8F5E9', '#F1F8E9',
    // Bleus clairs
    '#4ECDC4', '#26A69A', '#00BCD4', '#00ACC1', '#0097A7', '#00838F', '#00695C', '#004D40',
    // Bleus
    '#2196F3', '#42A5F5', '#64B5F6', '#90CAF9', '#BBDEFB', '#54A0FF', '#1E90FF', '#0D47A1',
    // Bleus foncés
    '#45B7D1', '#00D2D3', '#00BCD4', '#0097A7', '#00838F', '#006064', '#01579B', '#0277BD',
    // Violets et pourpres
    '#9C27B0', '#BA68C8', '#CE93D8', '#E1BEE7', '#F3E5F5', '#DDA0DD', '#DA70D6', '#BA55D3',
    // Violets foncés
    '#5F27CD', '#673AB7', '#7E57C2', '#9575CD', '#B39DDB', '#9C88FF', '#8E24AA', '#6A1B9A',
    // Gris
    '#9E9E9E', '#BDBDBD', '#E0E0E0', '#F5F5F5', '#757575', '#616161', '#424242', '#212121',
    // Marrons
    '#795548', '#8D6E63', '#A1887F', '#BCAAA4', '#D7CCC8', '#6D4C41', '#5D4037', '#4E342E',
    // Indigo
    '#3F51B5', '#5C6BC0', '#7986CB', '#9FA8DA', '#C5CAE9', '#283593', '#1A237E', '#0D47A1',
    // Cyan
    '#00BCD4', '#26C6DA', '#4DD0E1', '#80DEEA', '#B2EBF2', '#00ACC1', '#0097A7', '#00838F',
    // Teal
    '#009688', '#26A69A', '#4DB6AC', '#80CBC4', '#B2DFDB', '#00796B', '#00695C', '#004D40',
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.category.color ?? '#FF6B6B';
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<BudgetProvider>();
      if (provider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Mettre à jour la couleur via les favoris (CATEGORY_COLOR)
      await FavoriteService.updateCategoryColor(
        provider.currentUser!.id,
        widget.category.id,
        _selectedColor,
      );

      // Invalider le cache des couleurs pour forcer le rechargement
      provider.invalidateCategoryColorsCache();
      
      // Recharger les catégories pour avoir la couleur mise à jour
      await provider.reloadCategories();
      
      // Vider les categoryExpenses pour forcer un rechargement avec les nouvelles couleurs
      // lors du prochain accès à l'écran statistiques
      provider.clearCategoryExpenses();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Couleur modifiée avec succès',
            description: 'La couleur de la catégorie a été mise à jour',
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
      height: MediaQuery.of(context).size.height * 0.5,
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
                Expanded(
                  child: Text(
                    'Personnaliser la couleur de catégorie ${widget.category.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Color Selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionner une couleur',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colors.map((color) {
                      final isSelected = color == _selectedColor;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: ColorUtils.parseColor(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey[300],
                minimumSize: const Size(double.infinity, 50),
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
          ),
        ],
      ),
    );
  }
}

