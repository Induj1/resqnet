import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/citizen_report.dart';
import '../../../../models/disaster_event.dart';
import '../../../../models/grid_risk_point.dart';
import '../../../../models/rescue_unit.dart';
import '../../../../models/sos_report.dart';
import '../../../../services/notification_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../sos/presentation/widgets/sos_sheet.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _digitalTwinEnabled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactFab = screenWidth < 420;

    final disasterConfidence = ref.watch(currentDisasterConfidenceProvider);
    final weatherSeverity = ref.watch(weatherSeverityProvider);
    final activeAlerts = ref.watch(activeAlertsCountProvider);
    final notifications = ref.watch(notificationServiceProvider).stream;

    final riskPoints = ref.watch(gridRiskProvider).valueOrNull ?? [];
    final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];
    final rescueUnits = ref.watch(rescueUnitsProvider).valueOrNull ?? [];
    final citizenSos = ref.watch(citizenSosReportsProvider);
    final activeReport = ref.watch(activeReportProvider);
    final socialSignals = ref.watch(socialSignalCountProvider);
    final newsHeadlines = ref.watch(newsHeadlinesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF05060A), Color(0xFF020308)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1000;
                final isNarrow = constraints.maxWidth < 700;
                return Column(
                  children: [
                    _TopStatusBar(
                      disasterConfidence: disasterConfidence,
                      weatherSeverity: weatherSeverity,
                      activeAlerts: activeAlerts,
                      compact: isNarrow,
                      onLogout: () =>
                          ref.read(authActionProvider.notifier).logout(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isCompact
                          ? Column(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _MapCommandPane(
                                    compact: true,
                                    notificationsStream: notifications,
                                    riskPoints: riskPoints,
                                    events: events,
                                    rescueUnits: rescueUnits,
                                    citizenSos: citizenSos,
                                    activeReport: activeReport,
                                    digitalTwinEnabled: _digitalTwinEnabled,
                                    pulseAnimation: _pulseController,
                                    onToggleDigitalTwin: (enabled) {
                                      setState(() {
                                        _digitalTwinEnabled = enabled;
                                      });
                                    },
                                    onOpenMap: () => context.go('/map'),
                                    onOpenAlerts: () => context.go('/alerts'),
                                    onOpenReport: () => context.go('/report'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 4,
                                  child: _IntelSidePanel(
                                    compact: true,
                                    newsHeadlines: newsHeadlines,
                                    socialSignals: socialSignals,
                                    weatherSeverity: weatherSeverity,
                                    activeAlerts: activeAlerts,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _MapCommandPane(
                                    compact: false,
                                    notificationsStream: notifications,
                                    riskPoints: riskPoints,
                                    events: events,
                                    rescueUnits: rescueUnits,
                                    citizenSos: citizenSos,
                                    activeReport: activeReport,
                                    digitalTwinEnabled: _digitalTwinEnabled,
                                    pulseAnimation: _pulseController,
                                    onToggleDigitalTwin: (enabled) {
                                      setState(() {
                                        _digitalTwinEnabled = enabled;
                                      });
                                    },
                                    onOpenMap: () => context.go('/map'),
                                    onOpenAlerts: () => context.go('/alerts'),
                                    onOpenReport: () => context.go('/report'),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 3,
                                  child: _IntelSidePanel(
                                    compact: false,
                                    newsHeadlines: newsHeadlines,
                                    socialSignals: socialSignals,
                                    weatherSeverity: weatherSeverity,
                                    activeAlerts: activeAlerts,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final t = _pulseController.value;
          final glow = 0.6 + 0.4 * math.sin(t * math.pi * 2);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3B30).withOpacity(0.4 * glow),
                  blurRadius: 28 * glow,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: compactFab
            ? FloatingActionButton(
                backgroundColor: const Color(0xFFFF3B30),
                onPressed: () => showSosSheet(context, ref),
                child: const Icon(Icons.sos),
              )
            : FloatingActionButton.extended(
                backgroundColor: const Color(0xFFFF3B30),
                onPressed: () => showSosSheet(context, ref),
                icon: const Icon(Icons.sos),
                label: const Text('SOS'),
              ),
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  const _TopStatusBar({
    required this.disasterConfidence,
    required this.weatherSeverity,
    required this.activeAlerts,
    required this.compact,
    required this.onLogout,
  });

  final double disasterConfidence;
  final double weatherSeverity;
  final int activeAlerts;
  final bool compact;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final confidenceText = '${disasterConfidence.toStringAsFixed(0)}%';
    final weatherText = '${weatherSeverity.toStringAsFixed(0)}%';

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFFF453A), Color(0xFF3A0000)],
                          radius: 1.2,
                        ),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ResQNet Command',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'National Emergency Control Room',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      label: 'Disaster Confidence',
                      value: confidenceText,
                      icon: Icons.radar,
                      accentColor: const Color(0xFFFF3B30),
                    ),
                    _StatusPill(
                      label: 'Weather Severity',
                      value: weatherText,
                      icon: Icons.thunderstorm,
                      accentColor: const Color(0xFFFF9F0A),
                    ),
                    _StatusPill(
                      label: 'Active Alerts',
                      value: activeAlerts.toString(),
                      icon: Icons.crisis_alert,
                      accentColor: const Color(0xFFFF453A),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFFF453A), Color(0xFF3A0000)],
                      radius: 1.2,
                    ),
                  ),
                  child: const Icon(Icons.emergency, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ResQNet Command',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'National Emergency Control Room',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                _StatusPill(
                  label: 'Disaster Confidence',
                  value: confidenceText,
                  icon: Icons.radar,
                  accentColor: const Color(0xFFFF3B30),
                ),
                const SizedBox(width: 10),
                _StatusPill(
                  label: 'Weather Severity',
                  value: weatherText,
                  icon: Icons.thunderstorm,
                  accentColor: const Color(0xFFFF9F0A),
                ),
                const SizedBox(width: 10),
                _StatusPill(
                  label: 'Active Alerts',
                  value: activeAlerts.toString(),
                  icon: Icons.crisis_alert,
                  accentColor: const Color(0xFFFF453A),
                ),
                const SizedBox(width: 16),
                IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
              ],
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.35),
        border: Border.all(color: accentColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  value,
                  key: ValueKey('$label-$value'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapCommandPane extends StatelessWidget {
  const _MapCommandPane({
    required this.compact,
    required this.notificationsStream,
    required this.riskPoints,
    required this.events,
    required this.rescueUnits,
    required this.citizenSos,
    required this.activeReport,
    required this.digitalTwinEnabled,
    required this.pulseAnimation,
    required this.onToggleDigitalTwin,
    required this.onOpenMap,
    required this.onOpenAlerts,
    required this.onOpenReport,
  });

  final bool compact;
  final Stream<String> notificationsStream;
  final List<GridRiskPoint> riskPoints;
  final List<DisasterEvent> events;
  final List<RescueUnit> rescueUnits;
  final List<CitizenReport> citizenSos;
  final SosReport? activeReport;
  final bool digitalTwinEnabled;
  final Animation<double> pulseAnimation;
  final ValueChanged<bool> onToggleDigitalTwin;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CommandCenterMap(
            riskPoints: riskPoints,
            events: events,
            rescueUnits: rescueUnits,
            citizenSos: citizenSos,
            activeReport: activeReport,
            digitalTwinEnabled: digitalTwinEnabled,
            pulseAnimation: pulseAnimation,
          ),
          // Tactical glass overlays
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: StreamBuilder<String>(
              stream: notificationsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFFFF453A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snapshot.data!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withOpacity(0.55),
                          border: Border.all(
                            color: const Color(0xFFFF453A).withOpacity(0.7),
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF453A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: const [
                              _LegendDot(
                                color: Color(0xFFFF3B30),
                                label: 'Disaster Heat',
                              ),
                              SizedBox(width: 10),
                              _LegendDot(
                                color: Color(0xFFFF9F0A),
                                label: 'Grid Risk',
                              ),
                              SizedBox(width: 10),
                              _LegendDot(
                                color: Color(0xFF0A84FF),
                                label: 'Citizen SOS',
                              ),
                              SizedBox(width: 10),
                              _LegendDot(
                                color: Color(0xFF34C759),
                                label: 'Rescue Units',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: onOpenMap,
                              icon: const Icon(Icons.fullscreen),
                              tooltip: 'Open full situational map',
                            ),
                            IconButton(
                              onPressed: onOpenAlerts,
                              icon: const Icon(Icons.crisis_alert),
                              tooltip: 'View alerts',
                            ),
                            IconButton(
                              onPressed: onOpenReport,
                              icon: const Icon(
                                Icons.edit_location_alt_outlined,
                              ),
                              tooltip: 'File report',
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _LegendDot(
                          color: const Color(0xFFFF3B30),
                          label: 'Disaster Heat',
                        ),
                        const SizedBox(width: 10),
                        _LegendDot(
                          color: const Color(0xFFFF9F0A),
                          label: 'Grid Risk',
                        ),
                        const SizedBox(width: 10),
                        _LegendDot(
                          color: const Color(0xFF0A84FF),
                          label: 'Citizen SOS',
                        ),
                        const SizedBox(width: 10),
                        _LegendDot(
                          color: const Color(0xFF34C759),
                          label: 'Rescue Units',
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onOpenMap,
                          icon: const Icon(Icons.fullscreen),
                          tooltip: 'Open full situational map',
                        ),
                        IconButton(
                          onPressed: onOpenAlerts,
                          icon: const Icon(Icons.crisis_alert),
                          tooltip: 'View alerts',
                        ),
                        IconButton(
                          onPressed: onOpenReport,
                          icon: const Icon(Icons.edit_location_alt_outlined),
                          tooltip: 'File report',
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            right: 16,
            top: compact ? 84 : 16,
            child: _DigitalTwinToggle(
              compact: compact,
              enabled: digitalTwinEnabled,
              onChanged: onToggleDigitalTwin,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 12),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _DigitalTwinToggle extends StatelessWidget {
  const _DigitalTwinToggle({
    required this.compact,
    required this.enabled,
    required this.onChanged,
  });

  final bool compact;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = enabled
        ? const Color(0xFFFF3B30)
        : Colors.white.withOpacity(0.45);

    return GestureDetector(
      onTap: () => onChanged(!enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.black.withOpacity(0.55),
          border: Border.all(color: accent.withOpacity(0.7)),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withOpacity(0.5),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_motion, color: accent, size: 18),
            const SizedBox(width: 8),
            Text(
              compact ? 'Twin' : 'Digital Twin',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 34,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: enabled ? const Color(0xFFFF3B30) : Colors.white10,
              ),
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntelSidePanel extends StatelessWidget {
  const _IntelSidePanel({
    required this.compact,
    required this.newsHeadlines,
    required this.socialSignals,
    required this.weatherSeverity,
    required this.activeAlerts,
  });

  final bool compact;
  final List<String> newsHeadlines;
  final int socialSignals;
  final double weatherSeverity;
  final int activeAlerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Live Intelligence Feed'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: newsHeadlines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final headline = newsHeadlines[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withOpacity(0.45),
                          border: Border.all(
                            color: const Color(
                              0xFFFF453A,
                            ).withOpacity(index == 0 ? 0.7 : 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              index == 0
                                  ? Icons.flash_on
                                  : Icons.article_outlined,
                              size: 16,
                              color: index == 0
                                  ? const Color(0xFFFF453A)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                headline,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Signals & Conditions'),
                const SizedBox(height: 12),
                compact
                    ? Column(
                        children: [
                          Row(
                            children: [
                              _SignalTile(
                                label: 'Social Media Signals',
                                value: socialSignals.toString(),
                                icon: Icons.social_distance,
                                accent: const Color(0xFF0A84FF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _SignalTile(
                                label: 'Weather Severity',
                                value: '${weatherSeverity.toStringAsFixed(0)}%',
                                icon: Icons.thunderstorm,
                                accent: const Color(0xFFFF9F0A),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _SignalTile(
                            label: 'Social Media Signals',
                            value: socialSignals.toString(),
                            icon: Icons.social_distance,
                            accent: const Color(0xFF0A84FF),
                          ),
                          const SizedBox(width: 10),
                          _SignalTile(
                            label: 'Weather Severity',
                            value: '${weatherSeverity.toStringAsFixed(0)}%',
                            icon: Icons.thunderstorm,
                            accent: const Color(0xFFFF9F0A),
                          ),
                        ],
                      ),
                const SizedBox(height: 10),
                _SignalTile(
                  label: 'Active Alerts',
                  value: activeAlerts.toString(),
                  icon: Icons.crisis_alert,
                  accent: const Color(0xFFFF453A),
                  wide: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: wide ? 2 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withOpacity(0.55),
          border: Border.all(color: accent.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.15),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      value,
                      key: ValueKey('$label-$value'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandCenterMap extends StatefulWidget {
  const _CommandCenterMap({
    required this.riskPoints,
    required this.events,
    required this.rescueUnits,
    required this.citizenSos,
    required this.activeReport,
    required this.digitalTwinEnabled,
    required this.pulseAnimation,
  });

  final List<GridRiskPoint> riskPoints;
  final List<DisasterEvent> events;
  final List<RescueUnit> rescueUnits;
  final List<CitizenReport> citizenSos;
  final SosReport? activeReport;
  final bool digitalTwinEnabled;
  final Animation<double> pulseAnimation;

  @override
  State<_CommandCenterMap> createState() => _CommandCenterMapState();
}

class _CommandCenterMapState extends State<_CommandCenterMap> {
  late final VoidCallback _pulseListener;
  double _unitPulse = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseListener = () {
      if (!mounted) return;
      setState(() {
        _unitPulse =
            1.0 + 0.25 * math.sin(widget.pulseAnimation.value * math.pi * 2);
      });
    };
    widget.pulseAnimation.addListener(_pulseListener);
  }

  @override
  void didUpdateWidget(covariant _CommandCenterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseAnimation != widget.pulseAnimation) {
      oldWidget.pulseAnimation.removeListener(_pulseListener);
      widget.pulseAnimation.addListener(_pulseListener);
    }
  }

  @override
  void dispose() {
    widget.pulseAnimation.removeListener(_pulseListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circles = widget.riskPoints.map((point) {
      final baseRadius = 16.0 + (point.riskScore.clamp(0, 1) * 36);
      final radius = widget.digitalTwinEnabled ? baseRadius * 1.4 : baseRadius;
      final color = _riskColor(
        point.riskScore,
        intense: widget.digitalTwinEnabled,
      );
      return CircleMarker(
        point: LatLng(point.gridLat, point.gridLng),
        radius: radius,
        color: color.withValues(alpha: widget.digitalTwinEnabled ? 0.6 : 0.4),
        borderColor: color.withValues(
          alpha: widget.digitalTwinEnabled ? 0.9 : 0.6,
        ),
        borderStrokeWidth: 1.3,
      );
    }).toList();

    final eventMarkers = widget.events.map((event) {
      final intensity =
          (event.confidenceScore <= 1
                  ? event.confidenceScore
                  : event.confidenceScore / 100)
              .clamp(0.0, 1.0);
      final size = 20.0 + intensity * 12;
      return Marker(
        point: LatLng(event.latitude, event.longitude),
        width: size + 8,
        height: size + 8,
        child: Tooltip(
          message: '${event.type} ${(intensity * 100).toStringAsFixed(0)}%',
          child: Icon(
            Icons.warning_amber_rounded,
            color: const Color(0xFFFF453A),
            size: size,
          ),
        ),
      );
    });

    final sosMarkers = widget.citizenSos.map((report) {
      return Marker(
        point: LatLng(report.latitude, report.longitude),
        width: 30,
        height: 30,
        child: const Icon(
          Icons.person_pin_circle,
          color: Color(0xFF0A84FF),
          size: 24,
        ),
      );
    });

    final unitMarkers = widget.rescueUnits.map((unit) {
      final statusColor = unit.status == 'available'
          ? const Color(0xFF34C759)
          : const Color(0xFFFF9F0A);
      return Marker(
        point: LatLng(unit.latitude, unit.longitude),
        width: 30,
        height: 30,
        child: Transform.scale(
          scale: _unitPulse,
          child: Icon(Icons.local_shipping, color: statusColor, size: 22),
        ),
      );
    });

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(20.5937, 78.9629),
        initialZoom: 4,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.resqnet.app',
        ),
        PolylineLayer(polylines: _buildDispatchPath()),
        CircleLayer(circles: circles),
        MarkerLayer(markers: [...eventMarkers, ...sosMarkers, ...unitMarkers]),
      ],
    );
  }

  List<Polyline> _buildDispatchPath() {
    final report = widget.activeReport;
    if (report == null || widget.rescueUnits.isEmpty) return const [];

    RescueUnit? nearest;
    double? bestDistance;
    for (final unit in widget.rescueUnits) {
      final dLat = unit.latitude - report.latitude;
      final dLng = unit.longitude - report.longitude;
      final d = math.sqrt(dLat * dLat + dLng * dLng);
      if (bestDistance == null || d < bestDistance) {
        bestDistance = d;
        nearest = unit;
      }
    }
    if (nearest == null) return const [];

    return [
      Polyline(
        points: [
          LatLng(nearest.latitude, nearest.longitude),
          LatLng(report.latitude, report.longitude),
        ],
        strokeWidth: 4.0,
        color: const Color(0xFFFF453A),
      ),
    ];
  }

  Color _riskColor(double riskScore, {required bool intense}) {
    final r = riskScore.clamp(0.0, 1.0);
    if (r >= 0.8) {
      return intense ? const Color(0xFFFF1B10) : const Color(0xFFFF3B30);
    }
    if (r >= 0.5) {
      return intense ? const Color(0xFFFFB10A) : const Color(0xFFFF9F0A);
    }
    return intense ? const Color(0xFF40D96A) : const Color(0xFF34C759);
  }
}
