import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    
    // Main animation controller (réduit pour plus de performance)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Image animations (séquence 1 : 0-55% - amélioré pour plus de fluidité)
    _imageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut), // Plus fluide au début
      ),
    );

    _imageScaleAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic), // Plus fluide, moins de rebond
      ),
    );

    // Title animations (séquence 2 : 60-85% - commence après l'image avec petit délai)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut), // Plus fluide
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25), // Légèrement plus de mouvement
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle animations (séquence 3 : 85-100% - commence vers la fin du titre)
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut), // Plus fluide
      ),
    );

    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Légèrement plus de mouvement
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to main screen after splash
    // TODO: Après implémentation OAuth2, vérifier si l'utilisateur est connecté
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });

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

