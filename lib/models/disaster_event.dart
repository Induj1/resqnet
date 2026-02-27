class DisasterEvent {
  DisasterEvent({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.confidenceScore,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final double confidenceScore;
  final DateTime createdAt;

  factory DisasterEvent.fromMap(Map<String, dynamic> map) {
    return DisasterEvent(
      id: map['id'] as String,
      type: map['type'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      confidenceScore: ((map['confidence'] ?? map['confidence_score'] ?? 0) as num)
          .toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
