import 'package:equatable/equatable.dart';

/// Entité de base pour toutes les notifications WebSocket
abstract class WebSocketNotificationEntity extends Equatable {
  final String type;
  final String message;
  final DateTime timestamp;

  const WebSocketNotificationEntity({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [type, message, timestamp];
}

// ==================== NOTIFICATIONS D'ÉVÉNEMENTS ====================

/// Notification pour un nouvel événement
class NewEventNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> eventData;

  const NewEventNotificationEntity({
    required this.eventData,
    required super.message,
    required super.timestamp,
  }) : super(type: 'new_event');

  @override
  List<Object?> get props => [...super.props, eventData];
}

/// Notification pour un événement modifié
class EventUpdatedNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> eventData;

  const EventUpdatedNotificationEntity({
    required this.eventData,
    required super.message,
    required super.timestamp,
  }) : super(type: 'event_updated');

  @override
  List<Object?> get props => [...super.props, eventData];
}

/// Notification pour un événement annulé
class EventCancelledNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> eventData;

  const EventCancelledNotificationEntity({
    required this.eventData,
    required super.message,
    required super.timestamp,
  }) : super(type: 'event_cancelled');

  @override
  List<Object?> get props => [...super.props, eventData];
}

/// Notification pour un événement à proximité
class ProximityEventNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> eventData;
  final double? distance;

  const ProximityEventNotificationEntity({
    required this.eventData,
    this.distance,
    required super.message,
    required super.timestamp,
  }) : super(type: 'proximity_event');

  @override
  List<Object?> get props => [...super.props, eventData, distance];
}

/// Notification de rappel d'événement
class EventReminderNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> eventData;
  final String reminderTime;

  const EventReminderNotificationEntity({
    required this.eventData,
    required this.reminderTime,
    required super.message,
    required super.timestamp,
  }) : super(type: 'event_reminder');

  @override
  List<Object?> get props => [...super.props, eventData, reminderTime];
}

// ==================== NOTIFICATIONS DE LIEUX ====================

/// Notification pour un nouveau lieu
class NewPlaceNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> placeData;

  const NewPlaceNotificationEntity({
    required this.placeData,
    required super.message,
    required super.timestamp,
  }) : super(type: 'new_place');

  @override
  List<Object?> get props => [...super.props, placeData];
}

// ==================== NOTIFICATIONS PERSONNELLES ====================

/// Notification personnelle générique
class PersonalNotificationEntity extends WebSocketNotificationEntity {
  final Map<String, dynamic> notificationData;

  const PersonalNotificationEntity({
    required this.notificationData,
    required super.message,
    required super.timestamp,
  }) : super(type: 'personal_notification');

  @override
  List<Object?> get props => [...super.props, notificationData];
}

/// Notification de notifications non lues
class UnreadNotificationsEntity extends Equatable {
  final int count;
  final List<Map<String, dynamic>> notifications;
  final DateTime timestamp;

  const UnreadNotificationsEntity({
    required this.count,
    required this.notifications,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [count, notifications, timestamp];
}

// ==================== MESSAGES SYSTÈME ====================

/// Message de connexion établie
class ConnectionEstablishedEntity extends Equatable {
  final String message;
  final DateTime timestamp;

  const ConnectionEstablishedEntity({
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, timestamp];
}

/// Confirmation d'abonnement
class SubscriptionConfirmedEntity extends Equatable {
  final String subscriptionType;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  const SubscriptionConfirmedEntity({
    required this.subscriptionType,
    required this.details,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [subscriptionType, details, timestamp];
}

// ==================== ERREURS ====================

/// Erreur WebSocket
class WebSocketErrorEntity extends Equatable {
  final String message;
  final DateTime timestamp;

  const WebSocketErrorEntity({
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, timestamp];
}

// ==================== FACTORY ====================

/// Factory pour créer les entités à partir des messages JSON
class WebSocketEntityFactory {
  static WebSocketNotificationEntity? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final message = json['message'] as String? ?? '';
    final timestamp = json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now();

    switch (type) {
      case 'new_event':
        return NewEventNotificationEntity(
          eventData: json['event'] as Map<String, dynamic>? ?? {},
          message: message,
          timestamp: timestamp,
        );

      case 'event_updated':
        return EventUpdatedNotificationEntity(
          eventData: json['event'] as Map<String, dynamic>? ?? {},
          message: message,
          timestamp: timestamp,
        );

      case 'event_cancelled':
        return EventCancelledNotificationEntity(
          eventData: json['event'] as Map<String, dynamic>? ?? {},
          message: message,
          timestamp: timestamp,
        );

      case 'proximity_event':
        return ProximityEventNotificationEntity(
          eventData: json['event'] as Map<String, dynamic>? ?? {},
          distance: json['distance'] as double?,
          message: message,
          timestamp: timestamp,
        );

      case 'event_reminder':
        return EventReminderNotificationEntity(
          eventData: json['event'] as Map<String, dynamic>? ?? {},
          reminderTime: json['reminder_time'] as String? ?? '',
          message: message,
          timestamp: timestamp,
        );

      case 'new_place':
        return NewPlaceNotificationEntity(
          placeData: json['place'] as Map<String, dynamic>? ?? {},
          message: message,
          timestamp: timestamp,
        );

      case 'personal_notification':
        return PersonalNotificationEntity(
          notificationData: json['notification'] as Map<String, dynamic>? ?? {},
          message: message,
          timestamp: timestamp,
        );

      default:
        return null;
    }
  }

  static ConnectionEstablishedEntity? connectionEstablishedFromJson(
    Map<String, dynamic> json,
  ) {
    if (json['type'] != 'connection_established') return null;

    return ConnectionEstablishedEntity(
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  static SubscriptionConfirmedEntity? subscriptionConfirmedFromJson(
    Map<String, dynamic> json,
  ) {
    if (json['type'] != 'subscription_confirmed') return null;

    return SubscriptionConfirmedEntity(
      subscriptionType: json['subscription_type'] as String? ?? '',
      details: Map<String, dynamic>.from(json)
        ..remove('type')
        ..remove('subscription_type'),
      timestamp: DateTime.now(),
    );
  }

  static UnreadNotificationsEntity? unreadNotificationsFromJson(
    Map<String, dynamic> json,
  ) {
    if (json['type'] != 'unread_notifications') return null;

    return UnreadNotificationsEntity(
      count: json['count'] as int? ?? 0,
      notifications: (json['notifications'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      timestamp: DateTime.now(),
    );
  }

  static WebSocketErrorEntity errorFromJson(Map<String, dynamic> json) {
    return WebSocketErrorEntity(
      message: json['message'] as String? ?? 'Erreur inconnue',
      timestamp: DateTime.now(),
    );
  }
}