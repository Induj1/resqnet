import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/api_client.dart';
import '../core/network/supabase_provider.dart';
import '../core/utils/geo_math.dart';
import '../models/citizen_report.dart';
import '../models/disaster_event.dart';
import '../models/grid_risk_point.dart';
import '../models/news_article.dart';
import '../models/rescue_unit.dart';
import '../models/social_feed_item.dart';
import '../models/sos_report.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(
    ref.read(supabaseClientProvider),
    ApiClient(),
  );
});

class EmergencyRepository {
  EmergencyRepository(this._client, this._api);

  final SupabaseClient _client;
  final ApiClient _api;

  Stream<List<DisasterEvent>> streamDisasterEvents() {
    // Dashboard events feed from REST API `/events`.
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final list = await _api.getList('/events');
      return list
          .map(
            (e) => DisasterEvent.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<GridRiskPoint>> streamGridRisk() {
    // Heatmap grid from `/grid`.
    return Stream.periodic(const Duration(seconds: 7)).asyncMap((_) async {
      final list = await _api.getList('/grid');
      return list
          .map(
            (e) => GridRiskPoint.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<RescueUnit>> streamRescueUnits() {
    // Rescue units from `/rescue/units`.
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final list = await _api.getList('/rescue/units');
      return list
          .map(
            (e) => RescueUnit.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<CitizenReport>> streamReports() {
    // Reports feed from `/reports`.
    return Stream.periodic(const Duration(seconds: 6)).asyncMap((_) async {
      final list = await _api.getList('/reports', query: {'limit': 100});
      return list
          .map(
            (e) => CitizenReport.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<SocialFeedItem>> streamSocialFeed({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) {
    return Stream.periodic(const Duration(seconds: 6)).asyncMap((_) async {
      final list = await _api.getList(
        '/social/feed',
        query: {'lat': latitude, 'lng': longitude, 'radius_km': radiusKm},
      );
      return list
          .map(
            (e) => SocialFeedItem.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Future<Map<String, dynamic>> confirmSocialEvent({
    required String eventId,
    required double latitude,
    required double longitude,
    String? userId,
  }) async {
    return _api.postJson(
      '/social/events/$eventId/confirm',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<Map<String, dynamic>> postSocialObservation({
    required double latitude,
    required double longitude,
    required String disasterType,
    required String observation,
    String? userId,
  }) async {
    return _api.postJson(
      '/social/observe',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': disasterType,
        'observation': observation,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<EventConfirmationsResponse> getEventConfirmations(String eventId) async {
    final json = await _api.getJson('/social/events/$eventId/confirmations');
    return EventConfirmationsResponse.fromMap(json);
  }

  Future<NewsResponse> getNews({String? disasterType}) async {
    final json = await _api.getJson(
      '/news',
      query: disasterType == null ? null : {'disaster_type': disasterType},
    );
    return NewsResponse.fromMap(json);
  }

  Future<Map<String, dynamic>> getMediaList({
    String? disasterType,
    int limit = 50,
  }) async {
    return _api.getJson(
      '/media/list',
      query: {
        'limit': limit,
        if (disasterType != null) 'disaster_type': disasterType,
      },
    );
  }

  Future<Map<String, dynamic>> uploadMedia({
    required Uint8List bytes,
    required String filename,
    required double latitude,
    required double longitude,
    String disasterType = 'other',
    String? reportId,
    String? userId,
  }) async {
    return _api.postMultipart(
      '/media/upload',
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
      fields: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'disaster_type': disasterType,
        if (reportId != null) 'report_id': reportId,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Stream<List<SosReport>> streamCurrentUserReports(String userId) {
    // Use backend API instead of direct Supabase table stream because auth is
    // currently handled by backend OTP and may not create a Supabase session.
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final list = await _api.getList('/reports', query: {'limit': 100});
      final reports = list
          .map((e) => SosReport.fromMap(Map<String, dynamic>.from(e as Map)))
          .where(
            (r) =>
                (r.description ?? '').contains('user=$userId') &&
                (r.description ?? '').contains('people_count='),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Future<SosReport> createSosReport({
    required String userId,
    required String disasterId,
    required double latitude,
    required double longitude,
    required int peopleCount,
    required String injuryStatus,
  }) async {
    final row = await _api.postJson(
      '/reports',
      body: {
        'source': 'citizen_mobile',
        'event_id': disasterId,
        'latitude': latitude,
        'longitude': longitude,
        'description': 'people_count=$peopleCount;injury_status=$injuryStatus;user=$userId',
      },
    );

    return SosReport.fromMap(row);
  }

  Future<CitizenReport> createCitizenReport({
    required String source,
    required double latitude,
    required double longitude,
    required String description,
    String? eventId,
  }) async {
    final row = await _api.postJson(
      '/reports',
      body: {
        'source': source,
        'event_id': eventId,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      },
    );

    return CitizenReport.fromMap(row);
  }

  Future<void> markRescueUnitBusy(String unitId) async {
    await _client.from('rescue_units').update({'status': 'busy'}).eq('id', unitId);
  }

  Future<RescueUnit?> nearestAvailableUnit({
    required double latitude,
    required double longitude,
  }) async {
    final rows = await _client
        .from('rescue_units')
        .select()
        .eq('status', 'available') as List<dynamic>;

    if (rows.isEmpty) return null;

    final units = rows
        .map((e) => RescueUnit.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    units.sort((a, b) {
      final d1 = GeoMath.haversineKm(
        lat1: latitude,
        lon1: longitude,
        lat2: a.latitude,
        lon2: a.longitude,
      );
      final d2 = GeoMath.haversineKm(
        lat1: latitude,
        lon1: longitude,
        lat2: b.latitude,
        lon2: b.longitude,
      );
      return d1.compareTo(d2);
    });

    return units.first;
  }
}
