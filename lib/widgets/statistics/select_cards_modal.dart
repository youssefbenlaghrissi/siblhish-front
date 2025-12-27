import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/statistics_card.dart';
import '../../models/card.dart' as models;
import '../../theme/app_theme.dart';
import '../../providers/budget_provider.dart';

class SelectCardsModal extends StatefulWidget {
  final List<String> selectedCardIds;

  const SelectCardsModal({
    super.key,
    required this.selectedCardIds,
  });

  @override
  State<SelectCardsModal> createState() => _SelectCardsModalState();
}

class _SelectCardsModalState extends State<SelectCardsModal> {
  List<String> _selectedCardIds = []; // Liste ordonnée pour préserver l'ordre de sélection
  bool _isSubmitting = false; // État pour gérer le spinner lors de la validation
  bool _hasInitializedSelectedCards = false; // Flag pour savoir si on a déjà initialisé les cartes sélectionnées

  /// Convertir un ID numérique (ex: "1") en code de carte (ex: "bar_chart")
  /// Utilise uniquement la liste dynamique des cartes depuis le backend
  String _convertNumericIdToCode(String id, List<models.Card> availableCards) {
    // Si c'est déjà un code (ne commence pas par un chiffre), le retourner tel quel
    if (int.tryParse(id) == null) {
      return id;
    }
    
    // Utiliser uniquement la liste dynamique des cartes depuis le backend
    final card = availableCards.firstWhere(
      (c) => c.id.toString() == id,
      orElse: () => models.Card(id: -1, code: '', title: ''),
    );
    
    if (card.id <= 0) {
      // Si la carte n'est pas trouvée, retourner l'ID tel quel
      return id;
    }
    
    return card.code;
  }

  @override
  void initState() {
    super.initState();
    // Les cartes seront rechargées dans le build avec le provider
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              children: [
                Text(
                  'Sélectionner les cartes',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choisissez les cartes que vous souhaitez afficher dans vos statistiques',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Liste des cartes
          Consumer<BudgetProvider>(
            builder: (context, provider, _) {
              // Attendre que les cartes soient chargées depuis le backend
              // Les cartes sont chargées en arrière-plan après loadHomeData, utiliser le cache
              if (!provider.availableCardsLoaded) {
                return const Flexible(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              
              // Si aucune carte disponible, afficher un message
              if (provider.availableCards.isEmpty) {
                return Flexible(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        'Aucune carte disponible',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              // Convertir les IDs numériques en codes lors du build avec les cartes disponibles
              if (!_hasInitializedSelectedCards && widget.selectedCardIds.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedCardIds = widget.selectedCardIds
                          .map((id) => _convertNumericIdToCode(id, provider.availableCards))
                          .toList();
                      _hasInitializedSelectedCards = true;
                    });
                  }
                });
              }
              
              // Utiliser uniquement la liste dynamique des cartes depuis le backend
              final cardsToDisplay = provider.availableCards;
              
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: cardsToDisplay.length,
                  itemBuilder: (context, index) {
                    // Utiliser la carte dynamique depuis le backend
                    final card = cardsToDisplay[index];
                    final cardCode = card.code;
                    
                    // Trouver le StatisticsCardType correspondant au code pour l'icône et la description
                    StatisticsCardType? cardType;
                    String cardTitle = card.title;
                    String cardDescription = '';
                    IconData cardIcon = Icons.dashboard; // Icône par défaut
                    
                    // Essayer de trouver le type correspondant pour l'icône et la description
                    cardType = StatisticsCardTypeExtension.fromId(card.code);
                    if (cardType != null) {
                      cardIcon = cardType.icon;
                      cardDescription = cardType.description;
                    }
                    
                    final isSelected = _selectedCardIds.contains(cardCode);

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
                          // Retirer de la liste en préservant l'ordre
                          _selectedCardIds.remove(cardCode);
                        } else {
                          // Ajouter à la fin de la liste pour préserver l'ordre de sélection
                          _selectedCardIds.add(cardCode);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Checkbox
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

                          // Icône
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              cardIcon,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Titre et description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cardTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (cardDescription.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    cardDescription,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Boutons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedCardIds.isEmpty || _isSubmitting)
                        ? null
                        : () async {
                            // Afficher le spinner
                            setState(() {
                              _isSubmitting = true;
                            });
                            
                            // Attendre un court délai pour permettre l'affichage du spinner
                            await Future.delayed(const Duration(milliseconds: 100));
                            
                            // Retourner la liste ordonnée des cartes sélectionnées
                            if (mounted) {
                              Navigator.pop(context, List<String>.from(_selectedCardIds));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Valider',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Espace pour le safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

