import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/notification.dart' as models;
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/custom_snackbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<models.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<BudgetProvider>();
      final userId = provider.currentUser?.id;
      if (userId != null) {
        // Charger les deux appels en parallèle pour optimiser
        final results = await Future.wait([
          NotificationService.getNotifications(userId),
          NotificationService.getUnreadCount(userId),
        ]);
        
        if (mounted) {
          setState(() {
            _notifications = results[0] as List<models.Notification>;
            _unreadCount = results[1] as int;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _markAsRead(models.Notification notification) async {
    if (notification.isRead) return;
    
    // Mise à jour optimiste : mettre à jour l'UI immédiatement
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        // Créer une nouvelle notification avec isRead = true
        final updatedNotification = models.Notification(
          id: notification.id,
          title: notification.title,
          description: notification.description,
          isRead: true,
          type: notification.type,
          transactionType: notification.transactionType,
          creationDate: notification.creationDate,
        );
        _notifications[index] = updatedNotification;
        // Décrémenter le compteur si nécessaire
        if (_unreadCount > 0) {
          _unreadCount--;
        }
      }
    });
    
    // Faire l'appel API en arrière-plan (non-bloquant)
    NotificationService.markAsRead(notification.id).then((_) {
      // Mettre à jour uniquement le compteur de notifications non lues (sans recharger toute la liste)
      _updateUnreadCount();
    }).catchError((e) {
      // En cas d'erreur, restaurer l'état précédent
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification;
          _unreadCount++;
        }
      });
      
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.error(
            message: 'Erreur lors du marquage de la notification comme lue',
          ),
        );
      }
    });
  }

  // Mettre à jour uniquement le compteur de notifications non lues
  Future<void> _updateUnreadCount() async {
    try {
      final provider = context.read<BudgetProvider>();
      final userId = provider.currentUser?.id;
      if (userId == null) return;

      final count = await NotificationService.getUnreadCount(userId);
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement pour le compteur
    }
  }

  Future<void> _markAllAsRead() async {
    final provider = context.read<BudgetProvider>();
    final userId = provider.currentUser?.id;
    if (userId == null) return;

    // Afficher le skeleton immédiatement au tap (avant tout await)
    if (mounted) setState(() => _isLoading = true);

    try {
      await NotificationService.markAllAsRead(userId);
      await _loadNotifications();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(models.Notification notification) async {
    // Sauvegarder l'index de la notification pour pouvoir la restaurer en cas d'erreur
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1) return;
    
    // Sauvegarder le compteur actuel
    final previousUnreadCount = _unreadCount;
    
    // Mise à jour optimiste : supprimer la notification de la liste immédiatement
    setState(() {
      _notifications.removeAt(index);
      // Décrémenter le compteur si la notification n'était pas lue
      if (!notification.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
    });
    
    // Faire l'appel API en arrière-plan (non-bloquant)
    NotificationService.deleteNotification(notification.id).then((_) {
      // Mettre à jour uniquement le compteur de notifications non lues (sans recharger toute la liste)
      _updateUnreadCount();
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success(
            title: 'Notification supprimée',
            description: 'La notification a été supprimée avec succès',
          ),
        );
      }
    }).catchError((e) {
      // En cas d'erreur, restaurer la notification à sa position précédente
      setState(() {
        _notifications.insert(index, notification);
        _unreadCount = previousUnreadCount;
      });
      
      // Afficher un message d'erreur avec le message du backend si disponible
      String errorMessage = 'Erreur lors de la suppression de la notification';
      if (e.toString().contains('Exception:')) {
        // Extraire le message du backend
        final messageMatch = RegExp(r'Exception:\s*(.+)').firstMatch(e.toString());
        if (messageMatch != null) {
          errorMessage = messageMatch.group(1) ?? errorMessage;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.error(
            message: errorMessage,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Tout marquer lu',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 5, // Afficher 5 skeletons
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == 4 ? 20 : 12),
                          child: const NotificationCardSkeleton(),
                        );
                      },
                    )
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune notification',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return _NotificationCard(
                                notification: notification,
                                onTap: () => _markAsRead(notification),
                                onDelete: () => _deleteNotification(notification),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final models.Notification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMM yyyy à HH:mm', 'fr');
    final isRecurring = notification.type == 'RECURRING_TRANSACTION';
    
    // Utiliser directement le champ transactionType du backend
    final isIncome = notification.transactionType == 'INCOME';
    final isExpense = notification.transactionType == 'EXPENSE';
    
    // Couleur selon le type : vert pour revenu, rouge pour dépense, par défaut primary
    Color notificationColor;
    Color backgroundColor;
    IconData iconData;
    
    if (isIncome) {
      notificationColor = AppTheme.incomeColor; // Vert
      backgroundColor = AppTheme.incomeColor.withOpacity(0.1);
      iconData = Icons.trending_up_rounded;
    } else if (isExpense) {
      notificationColor = AppTheme.expenseColor; // Rouge
      backgroundColor = AppTheme.expenseColor.withOpacity(0.1);
      iconData = Icons.trending_down_rounded;
    } else {
      notificationColor = isRecurring ? AppTheme.primaryColor : Colors.blue;
      backgroundColor = notificationColor.withOpacity(0.1);
      iconData = isRecurring ? Icons.repeat_rounded : Icons.notifications_rounded;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification.isRead ? Colors.white : backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notification.isRead 
                      ? Colors.grey[200]! 
                      : notificationColor.withOpacity(0.3),
                  width: notification.isRead ? 1 : 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: notificationColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormatter.format(notification.creationDate),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu à trois points positionné en haut à droite
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else if (value == 'mark_read') {
                    onTap();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'mark_read',
                    enabled: !notification.isRead,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Opacity(
                      opacity: notification.isRead ? 0.5 : 1.0,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: notification.isRead
                                  ? Colors.grey[200]
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: notification.isRead
                                  ? Colors.grey[400]!
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Marquer comme lu',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: notification.isRead 
                                  ? Colors.grey[400]!
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Supprimer',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

