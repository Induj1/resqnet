import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../providers/tracking_providers.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(trackedReportProvider(reportId));
    final unit = ref.watch(trackedUnitProvider(reportId));
    final eta = ref.watch(etaMinutesProvider(reportId));

    if (report == null) {
      return const Scaffold(
        body: Center(child: Text('No active case found for this ID.')),
      );
    }

    final userPoint = LatLng(report.latitude, report.longitude);
    final unitPoint = unit == null
        ? LatLng(report.latitude, report.longitude)
        : LatLng(unit.latitude, unit.longitude);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user'),
        position: userPoint,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      if (unit != null)
        Marker(
          markerId: const MarkerId('unit'),
          position: unitPoint,
          infoWindow: InfoWindow(title: unit.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
    };

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [userPoint, unitPoint],
      width: 5,
      color: Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Live Tracking - ${report.id.substring(0, 8)}')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: userPoint, zoom: 13),
              markers: markers,
              polylines: {polyline},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Case Status: ${report.status.toUpperCase()}'),
                  const SizedBox(height: 6),
                  Text('Assigned Unit: ${unit?.name ?? 'Allocating...'}'),
                  const SizedBox(height: 6),
                  Text('ETA: ${eta == null ? '--' : '$eta min'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
