import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../core/widgets/offline_status_bar.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/dashboard_providers.dart';

enum _RiskLevel { safe, moderate, high }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.98,
      upperBound: 1.02,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  _RiskLevel _riskFrom(SocialFeedItem? item) {
    if (item == null) return _RiskLevel.safe;
    final confidence = item.confidence;
    final d = item.distanceKm;
    if (confidence >= 80 && d <= 10) return _RiskLevel.high;
    if (confidence >= 50 && d <= 25) return _RiskLevel.moderate;
    return _RiskLevel.safe;
  }

  Color _riskColor(_RiskLevel level) {
    switch (level) {
      case _RiskLevel.high:
        return const Color(0xFFFF3B30);
      case _RiskLevel.moderate:
        return const Color(0xFFFF9F0A);
      case _RiskLevel.safe:
        return const Color(0xFF34C759);
    }
  }

  String _riskLabel(_RiskLevel level, WidgetRef ref) {
    switch (level) {
      case _RiskLevel.high:
        return tr(ref, 'high');
      case _RiskLevel.moderate:
        return tr(ref, 'moderate');
      case _RiskLevel.safe:
        return tr(ref, 'safe');
    }
  }

  Future<void> _openSosSheet() async {
    HapticFeedback.heavyImpact();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _SosBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final nearest = ref.watch(nearestSocialFeedItemProvider);
    final distanceKm = nearest?.distanceKm;
    final risk = _riskFrom(nearest);
    final riskColor = _riskColor(risk);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const OfflineStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(ref, 'app_title'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const LanguageToggle(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  _RiskStatusCard(
                    areaRiskLabel: tr(ref, 'area_risk'),
                    riskLabel: _riskLabel(risk, ref),
                    color: riskColor,
                    disasterType: nearest?.type,
                    sentence: nearest == null
                        ? _localizedNoAlert(lang)
                        : _localizedDetectedNearby(lang, nearest.type),
                    distanceKm: distanceKm,
                    confirmations: nearest?.confirmations,
                    confirmationsLabel: tr(ref, 'confirmations'),
                    onTap: () => context.push('/map'),
                  ),
                  const SizedBox(height: 14),
                  ScaleTransition(
                    scale: _pulse,
                    child: _SosButton(
                      title: '🚨 ${tr(ref, 'sos_title')}',
                      subtitle: tr(ref, 'sos_subtitle'),
                      onTap: _openSosSheet,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AssistantCard(
                    onSpeak: () => context.push('/assistant?mode=speak'),
                    onType: () => context.push('/assistant?mode=type'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.photo_camera,
                    title: tr(ref, 'report_what_you_see'),
                    subtitle: _localizedMinimalReportHint(lang),
                    onTap: () => context.push('/report'),
                  ),
                  const SizedBox(height: 12),
                  _ShelterFinderCard(
                    onViewRoute: () => context.push('/map'),
                  ),
                  const SizedBox(height: 12),
                  _LiveAlertsCard(onTap: () => context.push('/alerts')),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.groups_2,
                    title: switch (lang) {
                      AppLanguage.hi => 'कम्युनिटी',
                      AppLanguage.kn => 'ಸಮುದಾಯ',
                      AppLanguage.en => 'Community',
                    },
                    subtitle: switch (lang) {
                      AppLanguage.hi => 'पास के अलर्ट • पुष्टि • समाचार • फोटो',
                      AppLanguage.kn => 'ಹತ್ತಿರ ಎಚ್ಚರಿಕೆ • ದೃಢೀಕರಣ • ಸುದ್ದಿ • ಫೋಟೋ',
                      AppLanguage.en => 'Nearby alerts • confirm • news • photos',
                    },
                    onTap: () => context.push('/community'),
                  ),
                  const SizedBox(height: 12),
                  _FamilySafetyCard(),
                  const SizedBox(height: 12),
                  _AdvancedToolsCard(
                    onOpenAiToolkit: () => context.push('/assistant-lab'),
                    onOpenDetailedReport: () => context.push('/report-form'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _localizedFooter(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
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

String _localizedDetectedNearby(AppLanguage lang, String type) {
  final t = type.trim().isEmpty ? '' : type.trim();
  switch (lang) {
    case AppLanguage.hi:
      return t.isEmpty ? 'पास में जोखिम' : '$t पास में';
    case AppLanguage.kn:
      return t.isEmpty ? 'ಹತ್ತಿರ ಅಪಾಯ' : '$t ಹತ್ತಿರ';
    case AppLanguage.en:
      return t.isEmpty ? 'Risk detected nearby' : '${_titleCase(t)} detected nearby';
  }
}

String _localizedNoAlert(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.hi:
      return 'पास में कोई अलर्ट नहीं';
    case AppLanguage.kn:
      return 'ಹತ್ತಿರ ಎಚ್ಚರಿಕೆ ಇಲ್ಲ';
    case AppLanguage.en:
      return 'No active alert nearby';
  }
}

String _localizedMinimalReportHint(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.hi:
      return 'कैमरा खुलेगा • GPS जुड़ जाएगा';
    case AppLanguage.kn:
      return 'ಕ್ಯಾಮೆರಾ ತೆರೆಯುತ್ತದೆ • GPS ಸೇರುತ್ತದೆ';
    case AppLanguage.en:
      return 'Camera opens • GPS attaches';
  }
}

String _localizedFooter(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.hi:
      return 'संकट में: SOS दबाएँ। शांत रहें।';
    case AppLanguage.kn:
      return 'ಸಂಕಟದಲ್ಲಿ: SOS ಒತ್ತಿ. ಶಾಂತವಾಗಿರಿ.';
    case AppLanguage.en:
      return 'In danger: press SOS. Stay calm.';
  }
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
}

class _RiskStatusCard extends StatelessWidget {
  const _RiskStatusCard({
    required this.areaRiskLabel,
    required this.riskLabel,
    required this.color,
    required this.sentence,
    required this.onTap,
    this.disasterType,
    this.distanceKm,
    this.confirmations,
    required this.confirmationsLabel,
  });

  final String areaRiskLabel;
  final String riskLabel;
  final Color color;
  final String sentence;
  final String? disasterType;
  final double? distanceKm;
  final int? confirmations;
  final String confirmationsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: color.withValues(alpha: 0.06),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          areaRiskLabel,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: color.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            riskLabel,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: color,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (disasterType != null && disasterType!.trim().isNotEmpty)
                      Text(
                        _titleCase(disasterType!.trim()),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      sentence,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    if (confirmations != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${confirmations!} $confirmationsLabel',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.map, color: color, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency SOS',
      child: SizedBox(
        width: double.infinity,
        height: 76,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(AppConstants.emergencyRed),
              gradient: LinearGradient(
                colors: [
                  const Color(AppConstants.emergencyRed),
                  const Color(AppConstants.emergencyRed).withValues(alpha: 0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(Icons.crisis_alert, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantCard extends ConsumerWidget {
  const _AssistantCard({
    required this.onSpeak,
    required this.onType,
  });

  final VoidCallback onSpeak;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🧠 ${tr(ref, 'need_help_now')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: onSpeak,
                    icon: const Icon(Icons.mic),
                    label: Text('🎤 ${tr(ref, 'speak')}'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: onType,
                    icon: const Icon(Icons.keyboard),
                    label: Text('⌨ ${tr(ref, 'type')}'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => GoRouter.of(context).push('/assistant-lab'),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                tr(ref, 'ai_toolkit'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 14,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            subtitle: Text(
              subtitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
          ),
        ),
      ),
    );
  }
}

class _ShelterFinderCard extends ConsumerWidget {
  const _ShelterFinderCard({required this.onViewRoute});
  final VoidCallback onViewRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(currentPositionProvider).valueOrNull;
    final nearest = _nearestShelter(pos);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.home_work, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(ref, 'shelter_finder'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nearest.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                nearest.distanceText,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${nearest.availableSlots} slots',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onViewRoute,
              icon: const Icon(Icons.route),
              label: Text('➡ ${tr(ref, 'view_safe_route')}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelterUi {
  const _ShelterUi({
    required this.name,
    required this.distanceText,
    required this.availableSlots,
  });

  final String name;
  final String distanceText;
  final int availableSlots;
}

_ShelterUi _nearestShelter(Position? pos) {
  // Lightweight placeholder list (works offline). Can be replaced by API later.
  const shelters = <({String name, double lat, double lng, int slots})>[
    (name: 'Relief Shelter – Govt School', lat: 28.6139, lng: 77.2090, slots: 24),
    (name: 'Community Hall Shelter', lat: 19.0760, lng: 72.8777, slots: 18),
    (name: 'PHC Shelter Point', lat: 12.9716, lng: 77.5946, slots: 12),
  ];

  if (pos == null) {
    return const _ShelterUi(
      name: 'Nearest Shelter',
      distanceText: '--',
      availableSlots: 12,
    );
  }

  final ranked = shelters
      .map((s) {
        final d = GeoMath.haversineKm(
          lat1: pos.latitude,
          lon1: pos.longitude,
          lat2: s.lat,
          lon2: s.lng,
        );
        return (s: s, d: d);
      })
      .toList()
    ..sort((a, b) => a.d.compareTo(b.d));

  final best = ranked.first;
  return _ShelterUi(
    name: best.s.name,
    distanceText: '${best.d.toStringAsFixed(1)} km',
    availableSlots: best.s.slots,
  );
}

class _LiveAlertsCard extends ConsumerWidget {
  const _LiveAlertsCard({required this.onTap});
  final VoidCallback onTap;

  Color _riskColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFFFF3B30);
    if (confidence >= 0.5) return const Color(0xFFFF9F0A);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(socialFeedProvider).valueOrNull ?? [];
    final pos = ref.watch(currentPositionProvider).valueOrNull;
    final lang = ref.watch(appLanguageProvider);
    final repo = ref.read(emergencyRepositoryProvider);
    final user = ref.watch(currentUserProvider);

    final top = [...items]..sort((a, b) => b.confidence.compareTo(a.confidence));
    final view = top.take(4).toList();

    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(ref, 'live_alerts'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 26),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                Text(
                  _localizedNoAlert(ref.watch(appLanguageProvider)),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                )
              else
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: view.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = view[i];
                      final d = e.distanceKm;
                      final c = _riskColor((e.confidence / 100).clamp(0, 1));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: c, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚠ ${_titleCase(e.type)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${switch (lang) {
                                      AppLanguage.hi => 'पास में',
                                      AppLanguage.kn => 'ಹತ್ತಿರ',
                                      AppLanguage.en => 'Nearby',
                                    }} • ${d.toStringAsFixed(1)} km • ${e.confirmations}',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: c.withValues(alpha: 0.45)),
                              ),
                              child: Text(
                                e.confidence >= 80
                                    ? tr(ref, 'high')
                                    : (e.confidence >= 50 ? tr(ref, 'moderate') : tr(ref, 'safe')),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: c,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: Semantics(
                                button: true,
                                label: tr(ref, 'confirm_sighting'),
                                child: FilledButton.tonalIcon(
                                onPressed: pos == null
                                    ? null
                                    : () async {
                                        try {
                                          final res = await repo.confirmSocialEvent(
                                            eventId: e.id,
                                            latitude: pos.latitude,
                                            longitude: pos.longitude,
                                            userId: user?.id,
                                          );
                                          if (!context.mounted) return;
                                          final msg = (res['message'] ?? '').toString();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg.isEmpty ? tr(ref, 'confirm_sighting') : msg)),
                                          );
                                        } catch (err) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(err.toString())),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(tr(ref, 'confirm')),
                              ),
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
    );
  }
}

class _FamilySafetyCard extends ConsumerWidget {
  const _FamilySafetyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final message = _familyMessage(lang);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.family_restroom, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '👨‍👩‍👧 ${tr(ref, 'family_update')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      switch (lang) {
                        AppLanguage.hi => 'संदेश कॉपी हो गया।',
                        AppLanguage.kn => 'ಸಂದೇಶ ಕಾಪಿ ಆಯಿತು.',
                        AppLanguage.en => 'Message copied.',
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(
                switch (lang) {
                  AppLanguage.hi => 'कॉपी करें',
                  AppLanguage.kn => 'ಕಾಪಿ',
                  AppLanguage.en => 'Copy',
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedToolsCard extends ConsumerWidget {
  const _AdvancedToolsCard({
    required this.onOpenAiToolkit,
    required this.onOpenDetailedReport,
  });

  final VoidCallback onOpenAiToolkit;
  final VoidCallback onOpenDetailedReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeReportProvider);
    final lang = ref.watch(appLanguageProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(ref, 'advanced_tools'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenAiToolkit,
                    icon: const Icon(Icons.psychology_alt),
                    label: Text(tr(ref, 'ai_toolkit')),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenDetailedReport,
                    icon: const Icon(Icons.description),
                    label: Text(tr(ref, 'detailed_report')),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: active == null
                  ? null
                  : () => context.push('/tracking/${active.id}'),
              icon: const Icon(Icons.location_searching),
              label: Text(tr(ref, 'track_sos')),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active == null
                ? switch (lang) {
                    AppLanguage.hi => 'कोई सक्रिय SOS नहीं',
                    AppLanguage.kn => 'ಸಕ್ರಿಯ SOS ಇಲ್ಲ',
                    AppLanguage.en => 'No active SOS',
                  }
                : switch (lang) {
                    AppLanguage.hi => 'स्थिति: ${active.status}',
                    AppLanguage.kn => 'ಸ್ಥಿತಿ: ${active.status}',
                    AppLanguage.en => 'Status: ${active.status}',
                  },
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _familyMessage(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.hi:
      return 'मैं सुरक्षित हूँ। मैं आपको अपडेट भेजूँगा/भेजूँगी।';
    case AppLanguage.kn:
      return 'ನಾನು ಸುರಕ್ಷಿತವಾಗಿದ್ದೇನೆ. ನಾನು ನಿಮಗೆ ಅಪ್ಡೇಟ್ ಕಳುಹಿಸುತ್ತೇನೆ.';
    case AppLanguage.en:
      return 'I am safe. I will update you again soon.';
  }
}

class _SosBottomSheet extends ConsumerStatefulWidget {
  const _SosBottomSheet();

  @override
  ConsumerState<_SosBottomSheet> createState() => _SosBottomSheetState();
}

class _SosBottomSheetState extends ConsumerState<_SosBottomSheet> {
  int _people = 1;
  bool _injured = false;
  bool _sending = false;

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final lang = ref.read(appLanguageProvider);
      final location = await ref.read(locationServiceProvider).getCurrentPosition();
      final nearest = ref.read(nearestSocialFeedItemProvider);
      final user = ref.read(currentUserProvider);
      final repo = ref.read(emergencyRepositoryProvider);

      if (user != null && nearest != null) {
        await repo.createSosReport(
          userId: user.id,
          disasterId: nearest.id,
          latitude: location.latitude,
          longitude: location.longitude,
          peopleCount: _people,
          injuryStatus: _injured ? 'injured' : 'not_injured',
        );
      } else {
        await repo.createCitizenReport(
          source: 'sos',
          latitude: location.latitude,
          longitude: location.longitude,
          description: 'SOS people=$_people;injury=${_injured ? 'yes' : 'no'}',
          eventId: nearest?.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (lang) {
              AppLanguage.hi => 'SOS भेजा गया। मदद आ रही है।',
              AppLanguage.kn => 'SOS ಕಳುಹಿಸಲಾಗಿದೆ. ಸಹಾಯ ಬರುತ್ತಿದೆ.',
              AppLanguage.en => 'SOS sent. Help is on the way.',
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final lang = ref.watch(appLanguageProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1320),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '🚨 ${tr(ref, 'sos_title')}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(ref, 'sos_subtitle'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CounterCard(
                      label: tr(ref, 'people_count'),
                      value: _people.toString(),
                      onMinus: _people <= 1 ? null : () => setState(() => _people -= 1),
                      onPlus: _people >= 10 ? null : () => setState(() => _people += 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _YesNoCard(
                      label: tr(ref, 'injury'),
                      value: _injured,
                      yesLabel: tr(ref, 'yes'),
                      noLabel: tr(ref, 'no'),
                      onChanged: (v) => setState(() => _injured = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(AppConstants.emergencyRed),
                  ),
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(tr(ref, 'send_sos')),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  child: Text(tr(ref, 'cancel')),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                switch (lang) {
                  AppLanguage.hi => 'लोकेशन अपने-आप भेजी जाएगी।',
                  AppLanguage.kn => 'ಸ್ಥಳ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಕಳುಹಿಸಲಾಗುತ್ತದೆ.',
                  AppLanguage.en => 'Location will be fetched automatically.',
                },
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SquareIconButton(
                icon: Icons.remove,
                onPressed: onMinus,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SquareIconButton(
                icon: Icons.add,
                onPressed: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YesNoCard extends StatelessWidget {
  const _YesNoCard({
    required this.label,
    required this.value,
    required this.yesLabel,
    required this.noLabel,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final String yesLabel;
  final String noLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(noLabel)),
                ButtonSegment(value: true, label: Text(yesLabel)),
              ],
              selected: {value},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChanged(s.first),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white.withValues(alpha: 0.14);
                  }
                  return Colors.white.withValues(alpha: 0.06);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return Colors.white.withValues(alpha: 0.78);
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
