import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.signInWithGoogle();
      
      if (result != null && mounted) {
        // Initialiser les données directement ici
        final provider = Provider.of<BudgetProvider>(context, listen: false);
        final userId = result['id']?.toString();
        
        if (userId != null && userId.isNotEmpty) {
          try {
            await provider.initialize(userId);
            
            // Naviguer directement vers l'écran principal
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/main');
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Erreur: ID utilisateur invalide';
              _isLoading = false;
            });
          }
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Connexion annulée';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Logo / Image
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/splash_image.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.monetization_on_rounded,
                      size: 100,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Siblhish',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Gérez votre budget intelligemment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              
              const Spacer(),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(),
              
              // Google Sign In Button
              _SocialButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: 'G',
                iconColor: Colors.red,
                label: 'Continuer avec Google',
                backgroundColor: Colors.white,
                textColor: AppTheme.textPrimary,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ou',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 24),
              
              // Continue as Guest
              TextButton(
                onPressed: _isLoading ? null : _continueAsGuest,
                child: Text(
                  'Continuer sans compte',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),
              
              const Spacer(),
              
              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(),
                ),
              
              // Terms
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'En continuant, vous acceptez nos conditions d\'utilisation',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String icon;
  final Color iconColor;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Colors.grey[300]!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: icon == 'G' ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

