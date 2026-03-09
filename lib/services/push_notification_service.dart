import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import '../app_navigation.dart';

/// Service pour gérer les notifications push Firebase Cloud Messaging (FCM)
class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _currentUserId;
  static Function(String)? _onNotificationsEnabledChanged;
  
  // Subscriptions Firebase pour pouvoir les annuler explicitement
  static StreamSubscription<RemoteMessage>? _onMessageSubscription;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  static StreamSubscription<String>? _onTokenRefreshSubscription;

  /// Initialiser Firebase Messaging et les notifications locales
  /// [notificationsEnabledFromDB] : statut depuis la base de données (table users)
  /// [isNewUser] : true si c'est un nouvel utilisateur (première connexion), false si utilisateur existant
  static Future<void> initialize({bool? notificationsEnabledFromDB, bool isNewUser = false}) async {
    try {
      // 1. Si notificationsEnabledFromDB est false, ne pas initialiser les notifications
      if (notificationsEnabledFromDB == false) {
        debugPrint('⚠️ Notifications désactivées dans la base de données, initialisation annulée');
        return;
      }

      // 2. Vérifier le statut actuel des permissions système
      NotificationSettings currentSettings = await _firebaseMessaging.getNotificationSettings();
      
      // Si utilisateur existant, utiliser le statut de la DB (ne pas redemander les permissions)
      if (!isNewUser && notificationsEnabledFromDB == true) {
        debugPrint('📱 Utilisateur existant avec notificationsEnabled=true, utilisation du statut existant');
        
        // Vérifier que les permissions système sont toujours accordées
        if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
            currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
          // Permissions OK, continuer l'initialisation
        } else {
          // Permissions refusées, mettre à jour la DB
          debugPrint('⚠️ Permissions système refusées, mise à jour notificationsEnabled à false');
          await _syncNotificationsEnabledToDB(false);
          return;
        }
      }

      // 3. Initialiser les notifications locales
      await _initializeLocalNotifications();

      // 4. Obtenir le token FCM
      await _getFCMToken();

      // 5. Configurer les handlers pour les notifications
      _setupMessageHandlers();

      debugPrint('✅ Service de notifications push initialisé');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Synchroniser le statut des notifications avec la base de données
  /// Seulement si les permissions système ont changé (refusées)
  static Future<void> _syncNotificationsEnabledToDB(bool enabled) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ UserId non défini, impossible de synchroniser notificationsEnabled');
      return;
    }

    try {
      // Mettre à jour directement via l'API
      await ApiService.put(
        '/users/$_currentUserId/profile',
        {'notificationsEnabled': enabled},
      );
      debugPrint('✅ notificationsEnabled synchronisé avec la base de données: $enabled');
      
      // Appeler le callback pour mettre à jour via BudgetProvider (après la mise à jour API)
      if (_onNotificationsEnabledChanged != null) {
        _onNotificationsEnabledChanged!(enabled.toString());
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation de notificationsEnabled: $e');
    }
  }

  /// Initialiser les notifications locales (pour afficher les notifications quand l'app est ouverte)
  static Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Gérer le clic sur une notification
        debugPrint('📬 Notification cliquée: ${details.payload}');
      },
    );
  }

  /// Obtenir le token FCM et l'envoyer au backend
  static Future<void> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('📱 Token FCM obtenu: ${token.substring(0, 20)}...');
        await _sendTokenToBackend(token);
      } else {
        debugPrint('⚠️ Token FCM non disponible');
      }

      // Annuler l'ancienne subscription si elle existe
      await _onTokenRefreshSubscription?.cancel();
      
      // Écouter les changements de token (rafraîchissement automatique)
      _onTokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 Token FCM rafraîchi: ${newToken.substring(0, 20)}...');
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du token FCM: $e');
    }
  }

  /// Envoyer le token FCM au backend
  static Future<void> _sendTokenToBackend(String token) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ UserId non défini, token FCM non envoyé');
      return;
    }

    try {
      await ApiService.post(
        '/users/$_currentUserId/fcm-token',
        {'fcmToken': token},
      );
      debugPrint('✅ Token FCM envoyé au backend');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du token FCM: $e');
    }
  }

  /// Configurer les handlers pour les notifications
  static void _setupMessageHandlers() {
    // Annuler les anciennes subscriptions si elles existent
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    
    // Notification reçue quand l'app est au premier plan (ouverte)
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notification reçue au premier plan: ${message.messageId}');
      // Si le message contient un payload "notification", Firebase ne l'affiche pas automatiquement au premier plan
      // On doit donc toujours afficher une notification locale au premier plan
      _showLocalNotification(message);
    });

    // Notification qui a ouvert l'app (app était en arrière-plan ou fermée)
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification qui a ouvert l\'app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Vérifier si l'app a été ouverte depuis une notification (app était fermée)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📬 App ouverte depuis une notification: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Afficher une notification locale quand l'app est au premier plan
  /// BigTextStyle permet d'étendre la notification pour consulter tout le détail
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Nouvelle notification';
    final body = message.notification?.body ?? '';

    final androidDetails = AndroidNotificationDetails(
      'siblhish_channel',
      'Siblhish Notifications',
      channelDescription: 'Notifications pour l\'application Siblhish',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
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
      title,
      body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Gérer le clic sur une notification (app en arrière-plan ou fermée)
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📬 Données de la notification: ${message.data}');
    openNotificationsScreen();
  }

  /// Définir l'ID utilisateur actuel (appelé avant initialize() pour que le token FCM soit envoyé au backend)
  static void setUserId(String userId, {Function(String)? onNotificationsEnabledChanged}) {
    _currentUserId = userId;
    _onNotificationsEnabledChanged = onNotificationsEnabledChanged;
  }

  /// S'abonner à un topic (pour recevoir des notifications groupées)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Abonné au topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'abonnement au topic: $e');
    }
  }

  /// Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Désabonné du topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur lors du désabonnement du topic: $e');
    }
  }

  /// Redemander les permissions de notifications (même si elles ont été refusées précédemment)
  /// Retourne true si les permissions sont accordées, false sinon
  static Future<bool> requestPermissionAgain() async {
    try {
      debugPrint('📱 Redemande des permissions de notifications...');
      
      // Redemander les permissions (fonctionne sur Android même si précédemment refusées)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
                          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        debugPrint('✅ Permissions de notifications accordées');
        
        // Initialiser les notifications si elles sont maintenant autorisées
        await _initializeLocalNotifications();
        await _getFCMToken();
        _setupMessageHandlers();
        
        return true;
      } else {
        debugPrint('❌ Permissions de notifications refusées');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la redemande des permissions: $e');
      return false;
    }
  }

  /// Obtenir le statut actuel des permissions système
  static Future<AuthorizationStatus> getAuthorizationStatus() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du statut des permissions: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  /// Annuler toutes les subscriptions Firebase pour éviter les fuites mémoire
  /// À appeler lors de la déconnexion ou du nettoyage des ressources
  static Future<void> dispose() async {
    debugPrint('🔄 Annulation des subscriptions Firebase...');
    
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
    
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
    _onTokenRefreshSubscription = null;
    
    _currentUserId = null;
    _onNotificationsEnabledChanged = null;
    
    debugPrint('✅ Subscriptions Firebase annulées');
  }
}

