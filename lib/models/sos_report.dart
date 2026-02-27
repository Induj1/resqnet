class SosReport {
  SosReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.userId,
    this.disasterId,
    this.peopleCount,
    this.injuryStatus,
    this.description,
  });

  final String id;
  final String? userId;
  final String? disasterId;
  final double latitude;
  final double longitude;
  final int? peopleCount;
  final String? injuryStatus;
  final String status;
  final String? description;
  final DateTime createdAt;

  factory SosReport.fromMap(Map<String, dynamic> map) {
    return SosReport(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      disasterId: map['disaster_id'] as String? ?? map['event_id'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      peopleCount: map['people_count'] as int?,
      injuryStatus: map['injury_status'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
