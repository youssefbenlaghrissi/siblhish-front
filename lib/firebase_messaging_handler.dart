import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Instance globale des notifications locales (initialisée une seule fois)
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
bool _isLocalNotificationsInitialized = false;

/// Initialiser les notifications locales (appelé une seule fois)
Future<void> _initializeLocalNotifications() async {
  if (_isLocalNotificationsInitialized) return;
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await _localNotifications.initialize(initSettings);

  // Créer le canal Android (Oreo+) avec importance haute pour que les notifs s'affichent
  final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'siblhish_channel',
        'Siblhish Notifications',
        description: 'Notifications pour l\'application Siblhish',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  _isLocalNotificationsInitialized = true;
  debugPrint('✅ Notifications locales initialisées en arrière-plan');
}

/// Handler pour les notifications Firebase en arrière-plan
/// Cette fonction doit être une fonction top-level (pas une méthode de classe)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Cette fonction est appelée quand l'app est fermée ou en arrière-plan et qu'une notification est reçue
  debugPrint('📬 Notification reçue en arrière-plan: ${message.messageId}');
  debugPrint('📬 Titre: ${message.notification?.title ?? message.data['title']}');
  debugPrint('📬 Corps: ${message.notification?.body ?? message.data['body']}');
  debugPrint('📬 Data: ${message.data}');
  
  // Si le message contient un payload "notification", Firebase l'affiche automatiquement
  // avec le style système (souvent une ligne, pas d'extension pour voir tout le détail).
  // Pour que TOUTES les notifications soient extensibles (BigTextStyle), le backend doit
  // envoyer des messages "data-only" (sans bloc "notification"), afin que ce handler
  // les affiche avec BigTextStyleInformation.
  if (message.notification != null) {
    debugPrint('✅ Notification affichée par Firebase (payload notification) → style système, pas BigTextStyle');
    return;
  }
  
  // Si le message contient uniquement des "data", on doit afficher une notification locale
  // Mais seulement si le message contient des données valides (titre ou corps)
  final String? title = message.data['title'] as String?;
  final String? body = message.data['body'] as String?;
  
  // Ignorer les messages vides ou sans contenu
  if ((title == null || title.trim().isEmpty) && (body == null || body.trim().isEmpty)) {
    debugPrint('⚠️ Message ignoré: pas de titre ni de corps dans les données');
    return;
  }
  
  try {
    // Initialiser les notifications locales si pas déjà fait
    await _initializeLocalNotifications();
    
    final notifTitle = title ?? body ?? 'Nouvelle notification';
    final notifBody = body ?? '';

    // BigTextStyle permet à l'utilisateur d'étendre la notification pour voir tout le détail
    final androidDetails = AndroidNotificationDetails(
      'siblhish_channel',
      'Siblhish Notifications',
      channelDescription: 'Notifications pour l\'application Siblhish',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        notifBody,
        contentTitle: notifTitle,
      ),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      notifTitle,
      notifBody,
      notificationDetails,
      payload: message.data.toString(),
    );

    debugPrint('✅ Notification locale affichée en arrière-plan');
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'affichage de la notification en arrière-plan: $e');
  }
}

