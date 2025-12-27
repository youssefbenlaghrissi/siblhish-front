import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomSnackBar {
  static SnackBar success({
    required String title,
    String? description,
    Duration duration = const Duration(seconds: 2),
  }) {
    return SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), // Fond vert clair
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor, // Bordure verte foncée
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icône à gauche
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9), // Fond vert plus clair pour l'icône
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Texte en deux lignes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: duration,
    );
  }

  static SnackBar error({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: duration,
    );
  }
}

