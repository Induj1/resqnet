class SocialFeedItem {
  SocialFeedItem({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.severity,
    required this.active,
    required this.createdAt,
    required this.distanceKm,
    required this.confirmations,
  });

  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final double confidence;
  final String severity;
  final bool active;
  final DateTime createdAt;
  final double distanceKm;
  final int confirmations;

  factory SocialFeedItem.fromMap(Map<String, dynamic> map) {
    return SocialFeedItem(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      severity: (map['severity'] ?? '').toString(),
      active: (map['active'] as bool?) ?? true,
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      confirmations: (map['confirmations'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventConfirmationPoint {
  EventConfirmationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  factory EventConfirmationPoint.fromMap(Map<String, dynamic> map) {
    return EventConfirmationPoint(
      id: (map['id'] ?? '').toString(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
    );
  }
}

class EventConfirmationsResponse {
  EventConfirmationsResponse({
    required this.eventId,
    required this.confirmationCount,
    required this.confirmations,
  });

  final String eventId;
  final int confirmationCount;
  final List<EventConfirmationPoint> confirmations;

  factory EventConfirmationsResponse.fromMap(Map<String, dynamic> map) {
    final raw = (map['confirmations'] as List?) ?? const [];
    return EventConfirmationsResponse(
      eventId: (map['event_id'] ?? '').toString(),
      confirmationCount: (map['confirmation_count'] as num?)?.toInt() ?? 0,
      confirmations: raw
          .map((e) => EventConfirmationPoint.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
