import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/budget_provider.dart';
import '../utils/error_message_formatter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  
  // Image animations
  late Animation<double> _imageFadeAnimation;
  late Animation<double> _imageScaleAnimation;
  
  // Title animations
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  
  // Subtitle animations
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Animation de 800ms
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Image : 0% → 35%
    _imageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _imageScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Titre : 35% → 65%
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Sous-titre : 65% → 100%
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    final stopwatch = Stopwatch()..start();
    
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (!isLoggedIn) {
      await _waitMinimumTime(stopwatch, 800);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // Charger les données pendant le splash screen
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Aucun utilisateur connecté');
      }
      debugPrint('🔄 Chargement des données pour l\'utilisateur: $userId');
      await provider.initialize(userId);
      debugPrint('✅ Données chargées avec succès');
    } catch (e) {
      debugPrint('❌ Erreur chargement: $e');
      // Attendre minimum 800ms pour voir l'animation complète
      await _waitMinimumTime(stopwatch, 800);
      if (!mounted) return;
      // Afficher une alerte d'erreur
      final userFriendlyMessage = ErrorMessageFormatter.formatErrorMessage(e);
      final errorTitle = ErrorMessageFormatter.getErrorTitle(e);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(errorTitle),
          content: Text(userFriendlyMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Réessayer
                _initializeAndNavigate();
              },
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Se déconnecter
                AuthService.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
      return;
    }

    // Attendre minimum 800ms pour voir l'animation complète
    await _waitMinimumTime(stopwatch, 800);
    if (!mounted) return;
    
    // Vérifier s'il y a une erreur même après le try/catch
    if (provider.error != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final userFriendlyMessage = ErrorMessageFormatter.formatErrorMessage(provider.error);
          final errorTitle = ErrorMessageFormatter.getErrorTitle(provider.error);
          
          return AlertDialog(
            title: Text(errorTitle),
            content: Text(userFriendlyMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeAndNavigate();
                },
                child: const Text('Réessayer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AuthService.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          );
        },
      );
      return;
    }
    
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _waitMinimumTime(Stopwatch stopwatch, int minMs) async {
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < minMs) {
      await Future.delayed(Duration(milliseconds: minMs - elapsed));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.splashBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.splashBackgroundColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image 3D illustration with multiple animations
              AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _imageFadeAnimation,
                    child: Transform.scale(
                      scale: _imageScaleAnimation.value,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                          maxHeight: 300,
                        ),
                        child: Image.asset(
                          'assets/images/splash_image.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.monetization_on_rounded,
                                size: 80,
                                color: AppTheme.primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              // App Name with slide and fade
              SlideTransition(
                position: _titleSlideAnimation,
                child: FadeTransition(
                  opacity: _titleFadeAnimation,
                  child: Text(
                    'Siblhish',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold, // Même que "Mes objectifs"
                      // Pas de couleur explicite = utilise la même couleur par défaut que "Mes objectifs"
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle with slide and fade (delayed)
              SlideTransition(
                position: _subtitleSlideAnimation,
                child: FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: Text(
                    'Gestion de budget intelligente',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

