class CitizenReport {
  CitizenReport({
    required this.id,
    required this.source,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.createdAt,
    this.eventId,
  });

  final String id;
  final String source;
  final String? eventId;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime createdAt;

  factory CitizenReport.fromMap(Map<String, dynamic> map) {
    return CitizenReport(
      id: map['id'] as String,
      source: map['source'] as String,
      eventId: map['event_id'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      description: (map['description'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
