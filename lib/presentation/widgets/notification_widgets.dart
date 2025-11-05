import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/config/websocket_config.dart';
import 'package:event_flow/core/providers/notification_provider.dart';
import 'package:event_flow/domains/entities/websocket_entity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

// ==================== BADGE DE NOTIFICATIONS ====================

/// Badge montrant le nombre de notifications non lues
class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const NotificationBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        final count = notifProvider.unreadCount;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: onTap ?? () => _showNotificationSheet(context),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSheet(),
    );
  }
}

// ==================== BOTTOM SHEET DES NOTIFICATIONS ====================

/// Bottom Sheet affichant toutes les notifications
class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    if (provider.notifications.isEmpty) return const SizedBox();

                    return TextButton.icon(
                      onPressed: () {
                        provider.clearAllNotifications();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Tout effacer'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste des notifications
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.mediumGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune notification',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return NotificationTile(
                      notification: notification,
                      onTap: () {
                        provider.markAsRead(notification);
                        _handleNotificationTap(context, notification);
                      },
                      onDismiss: () {
                        provider.removeNotification(notification);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WebSocketNotificationEntity notification,
  ) {
    Navigator.pop(context);
    
    // Naviguer selon le type de notification
    if (notification is NewEventNotificationEntity) {
      final eventId = notification.eventData['id'] as String?;
      if (eventId != null) {
        Navigator.pushNamed(context, '/evenement/detail', arguments: eventId);
      }
    } else if (notification is NewPlaceNotificationEntity) {
      final placeId = notification.placeData['id'] as String?;
      if (placeId != null) {
        Navigator.pushNamed(context, '/lieu/detail', arguments: placeId);
      }
    }
  }
}

// ==================== TILE DE NOTIFICATION ====================

/// Widget pour afficher une notification individuelle
class NotificationTile extends StatelessWidget {
  final WebSocketNotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.timestamp.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: _getNotificationColor(notification),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getNotificationTitle(notification),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.timestamp, locale: 'fr'),
                      style: Theme.of(context).textTheme.bodySmall,
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

  Color _getNotificationColor(WebSocketNotificationEntity notification) {
    if (notification is NewEventNotificationEntity ||
        notification is EventUpdatedNotificationEntity ||
        notification is ProximityEventNotificationEntity) {
      return AppColors.eventColor;
    } else if (notification is EventCancelledNotificationEntity) {
      return AppColors.error;
    } else if (notification is NewPlaceNotificationEntity) {
      return AppColors.placeColor;
    } else if (notification is EventReminderNotificationEntity) {
      return AppColors.warning;
    }
    return AppColors.info;
  }

  IconData _getNotificationIcon(WebSocketNotificationEntity notification) {
    if (notification is NewEventNotificationEntity) {
      return Icons.event_available;
    } else if (notification is EventUpdatedNotificationEntity) {
      return Icons.update;
    } else if (notification is EventCancelledNotificationEntity) {
      return Icons.event_busy;
    } else if (notification is ProximityEventNotificationEntity) {
      return Icons.location_on;
    } else if (notification is EventReminderNotificationEntity) {
      return Icons.alarm;
    } else if (notification is NewPlaceNotificationEntity) {
      return Icons.place;
    }
    return Icons.notifications;
  }

  String _getNotificationTitle(WebSocketNotificationEntity notification) {
    if (notification is NewEventNotificationEntity) {
      return 'Nouvel événement';
    } else if (notification is EventUpdatedNotificationEntity) {
      return 'Événement modifié';
    } else if (notification is EventCancelledNotificationEntity) {
      return 'Événement annulé';
    } else if (notification is ProximityEventNotificationEntity) {
      return 'Événement à proximité';
    } else if (notification is EventReminderNotificationEntity) {
      return 'Rappel d\'événement';
    } else if (notification is NewPlaceNotificationEntity) {
      return 'Nouveau lieu';
    }
    return 'Notification';
  }
}

// ==================== INDICATEUR D'ÉTAT DE CONNEXION ====================

/// Widget montrant l'état de connexion WebSocket
class WebSocketStatusIndicator extends StatelessWidget {
  const WebSocketStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final state = provider.connectionState;

        if (state == WebSocketConnectionState.connected) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStateColor(state).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStateColor(state),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: state == WebSocketConnectionState.connecting ||
                        state == WebSocketConnectionState.reconnecting
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _getStateColor(state),
                      )
                    : Icon(
                        _getStateIcon(state),
                        size: 16,
                        color: _getStateColor(state),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                state.description,
                style: TextStyle(
                  color: _getStateColor(state),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (state == WebSocketConnectionState.error)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton(
                    onPressed: () => provider.reconnect(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStateColor(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return AppColors.success;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return AppColors.warning;
      case WebSocketConnectionState.error:
      case WebSocketConnectionState.disconnected:
        return AppColors.error;
    }
  }

  IconData _getStateIcon(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Icons.check_circle;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Icons.sync;
      case WebSocketConnectionState.error:
        return Icons.error;
      case WebSocketConnectionState.disconnected:
        return Icons.cloud_off;
    }
  }
}

// ==================== PANNEAU DE CONTRÔLE WEBSOCKET (DEBUG) ====================

/// Widget de debug pour contrôler les connexions WebSocket
class WebSocketControlPanel extends StatelessWidget {
  const WebSocketControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contrôle WebSocket',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // État
                Row(
                  children: [
                    const Text('État: '),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isConnected
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        provider.connectionState.description,
                        style: TextStyle(
                          color: provider.isConnected
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Boutons de connexion
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isConnected
                          ? null
                          : () => provider.connectToGeneral(),
                      icon: const Icon(Icons.public, size: 18),
                      label: const Text('Général'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: provider.isConnected
                          ? null
                          : () {
                              // Simuler une connexion avec un token
                              provider.connectToPersonal('fake_token');
                            },
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text('Personnel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: provider.isConnected
                          ? null
                          : () {
                              // Position de Lomé par défaut
                              provider.connectToLocation(
                                latitude: 6.1319,
                                longitude: 1.2228,
                                radius: 10,
                              );
                            },
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('Localisation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            provider.isConnected ? provider.disconnect : null,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Déconnecter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: provider.reconnect,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reconnecter'),
                      ),
                    ),
                  ],
                ),

                if (provider.lastError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.lastError!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: provider.clearError,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== PAGE DE TEST COMPLÈTE ====================

/// Page de test pour les notifications WebSocket
class NotificationTestPage extends StatelessWidget {
  const NotificationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        actions: const [
          NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Indicateur d'état
            const WebSocketStatusIndicator(),

            // Panneau de contrôle
            const WebSocketControlPanel(),

            // Statistiques
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiques',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          icon: Icons.notifications,
                          label: 'Total',
                          value: provider.notifications.length.toString(),
                          color: AppColors.primaryBlue,
                        ),
                        _StatRow(
                          icon: Icons.notifications_active,
                          label: 'Non lues',
                          value: provider.unreadCount.toString(),
                          color: AppColors.error,
                        ),
                        _StatRow(
                          icon: Icons.event,
                          label: 'Événements',
                          value: provider.eventNotifications.length.toString(),
                          color: AppColors.eventColor,
                        ),
                        _StatRow(
                          icon: Icons.place,
                          label: 'Lieux',
                          value: provider.placeNotifications.length.toString(),
                          color: AppColors.placeColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}