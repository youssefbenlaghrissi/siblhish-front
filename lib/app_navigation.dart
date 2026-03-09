import 'package:flutter/material.dart';
import 'screens/notifications_screen.dart';

/// Clé du navigator racine (MaterialApp), pour navigation depuis des services sans BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Ouvre l'écran Notifications (ex. après clic sur une notif système).
void openNotificationsScreen() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  });
}
