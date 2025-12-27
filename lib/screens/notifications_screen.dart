import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/notification.dart' as models;
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';

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
      debugPrint('❌ Erreur chargement notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _markAsRead(models.Notification notification) async {
    if (notification.isRead) return;
    
    try {
      await NotificationService.markAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      debugPrint('❌ Erreur marquer comme lu: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final provider = context.read<BudgetProvider>();
      final userId = provider.currentUser?.id;
      if (userId == null) return;

      await NotificationService.markAllAsRead(userId);
      await _loadNotifications();
    } catch (e) {
      debugPrint('❌ Erreur marquer tout comme lu: $e');
    }
  }

  Future<void> _deleteNotification(models.Notification notification) async {
    try {
      await NotificationService.deleteNotification(notification.id);
      await _loadNotifications();
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
    }
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
        child: Container(
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
      ),
    );
  }
}

