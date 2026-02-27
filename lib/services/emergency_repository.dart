import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/api_client.dart';
import '../core/network/supabase_provider.dart';
import '../core/utils/geo_math.dart';
import '../models/citizen_report.dart';
import '../models/disaster_event.dart';
import '../models/grid_risk_point.dart';
import '../models/rescue_unit.dart';
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

  Stream<List<SosReport>> streamCurrentUserReports(String userId) {
    return _client
        .from('reports')
        .stream(primaryKey: ['id'])
        .eq('source', 'citizen_mobile')
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((e) => SosReport.fromMap(Map<String, dynamic>.from(e))).toList());
  }

  Future<SosReport> createSosReport({
    required String userId,
    required String disasterId,
    required double latitude,
    required double longitude,
    required int peopleCount,
    required String injuryStatus,
  }) async {
    final row = await _client
        .from('reports')
        .insert({
          'source': 'citizen_mobile',
          'event_id': disasterId,
          'latitude': latitude,
          'longitude': longitude,
          'description': 'people_count=$peopleCount;injury_status=$injuryStatus;user=$userId',
        })
        .select()
        .single();

    return SosReport.fromMap(Map<String, dynamic>.from(row as Map));
  }

  Future<CitizenReport> createCitizenReport({
    required String source,
    required double latitude,
    required double longitude,
    required String description,
    String? eventId,
  }) async {
    final row = await _client
        .from('reports')
        .insert({
          'source': source,
          'event_id': eventId,
          'latitude': latitude,
          'longitude': longitude,
          'description': description,
        })
        .select()
        .single();

    return CitizenReport.fromMap(Map<String, dynamic>.from(row as Map));
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
