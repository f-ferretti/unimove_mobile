import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import 'notifications_controller.dart';
import 'notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Notifiche'),
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          notificationsState.maybeWhen(
            data: (list) => list.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).markAllAsRead(),
                    child: const Text(
                      'Leggi tutte',
                      style: TextStyle(
                        color: AppColors.universityGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.universityGreen),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).fetchNotifications(),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_off_outlined,
                          color: AppColors.textMuted,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Nessuna notifica',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ti avviseremo quando ci saranno novità sul tuo profilo o sui tuoi viaggi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.universityGreen,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).fetchNotifications(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(context, ref, notification);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifica eliminata'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(notification.id);
          }
          // Se la notifica riguarda un'azione in chat o una corsa specifica, puoi reindirizzare qui.
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.surfaceDark.withValues(alpha: 0.4)
                : AppColors.surfaceDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? Colors.white.withValues(alpha: 0.02)
                  : AppColors.universityGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: notification.isRead
                        ? Colors.transparent
                        : AppColors.universityGreen.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  _getIconForType(notification.type),
                  color: notification.isRead
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.universityGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getTitleForType(notification.type),
                            style: TextStyle(
                              color: notification.isRead
                                  ? AppColors.textPrimary.withValues(alpha: 0.6)
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread Dot Indicator
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.universityGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: notification.isRead
                            ? AppColors.textSecondary.withValues(alpha: 0.6)
                            : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'BOOKING_REQUEST':
        return Icons.directions_car_outlined;
      case 'BOOKING_ACCEPTED':
        return Icons.check_circle_outline;
      case 'BOOKING_REJECTED':
        return Icons.cancel_outlined;
      case 'NEW_RIDE_AVAILABLE':
        return Icons.star_outline;
      case 'NEW_REVIEW':
        return Icons.rate_review_outlined;
      case 'RIDE_CANCELLED':
        return Icons.warning_amber_outlined;
      case 'SEAT_FREED':
        return Icons.event_seat_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'BOOKING_REQUEST':
        return 'Richiesta di partecipazione';
      case 'BOOKING_ACCEPTED':
        return 'Passaggio accettato';
      case 'BOOKING_REJECTED':
        return 'Richiesta rifiutata';
      case 'NEW_RIDE_AVAILABLE':
        return 'Nuova corsa sulla tua tratta';
      case 'NEW_REVIEW':
        return 'Nuova recensione ricevuta';
      case 'RIDE_CANCELLED':
        return 'Corsa annullata';
      case 'SEAT_FREED':
        return 'Posto liberato';
      default:
        return 'Notifica';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      if (difference.inMinutes <= 1) {
        return 'Adesso';
      }
      return 'Fa ${difference.inMinutes} minuti';
    } else if (difference.inHours < 24) {
      return 'Fa ${difference.inHours} ore';
    } else if (difference.inDays < 7) {
      return 'Fa ${difference.inDays} giorni';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
