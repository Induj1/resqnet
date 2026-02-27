import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

enum QuickDisasterType { flood, fire, accident, other }

class QuickReportScreen extends ConsumerStatefulWidget {
  const QuickReportScreen({super.key});

  @override
  ConsumerState<QuickReportScreen> createState() => _QuickReportScreenState();
}

class _QuickReportScreenState extends ConsumerState<QuickReportScreen> {
  final _picker = ImagePicker();
  final _note = TextEditingController();

  XFile? _photo;
  Uint8List? _photoBytes;
  QuickDisasterType _type = QuickDisasterType.flood;

  bool _uploading = false;
  bool _submitting = false;
  bool _uploadFailed = false;
  String? _uploadedUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _fileExtFromName(String? name) {
    final n = name?.trim();
    if (n == null || n.isEmpty) return 'jpg';
    final i = n.lastIndexOf('.');
    if (i <= 0 || i == n.length - 1) return 'jpg';
    final ext = n.substring(i + 1).toLowerCase();
    if (ext.length > 5) return 'jpg';
    return ext;
  }

  String _apiDisasterType(QuickDisasterType t) {
    return switch (t) {
      QuickDisasterType.flood => 'flood',
      QuickDisasterType.fire => 'fire',
      QuickDisasterType.accident => 'accident',
      QuickDisasterType.other => 'other',
    };
  }

  String _typeLabel(AppLanguage lang, QuickDisasterType t) {
    return switch (lang) {
      AppLanguage.hi => switch (t) {
          QuickDisasterType.flood => 'बाढ़',
          QuickDisasterType.fire => 'आग',
          QuickDisasterType.accident => 'दुर्घटना',
          QuickDisasterType.other => 'अन्य',
        },
      AppLanguage.kn => switch (t) {
          QuickDisasterType.flood => 'ಪ್ರವಾಹ',
          QuickDisasterType.fire => 'ಬೆಂಕಿ',
          QuickDisasterType.accident => 'ಅಪಘಾತ',
          QuickDisasterType.other => 'ಇತರೆ',
        },
      AppLanguage.en => switch (t) {
          QuickDisasterType.flood => 'Flood',
          QuickDisasterType.fire => 'Fire',
          QuickDisasterType.accident => 'Accident',
          QuickDisasterType.other => 'Other',
        },
    };
  }

  Future<void> _openCamera() async {
    final lang = ref.read(appLanguageProvider);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted) return;
      if (photo == null) {
        Navigator.of(context).pop();
        return;
      }
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _photoBytes = bytes;
        _uploadedUrl = null;
        _uploadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (lang) {
              AppLanguage.hi => 'कैमरा नहीं खुल पाया।',
              AppLanguage.kn => 'ಕ್ಯಾಮೆರಾ ತೆರೆಯಲಿಲ್ಲ.',
              AppLanguage.en => 'Could not open camera.',
            },
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(emergencyRepositoryProvider);
    final user = ref.read(currentUserProvider);

    setState(() => _submitting = true);
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      final disasterType = _apiDisasterType(_type);
      final note = _note.text.trim();
      final typeText = _typeLabel(lang, _type);

      if (_photoBytes != null && _uploadedUrl == null) {
        setState(() => _uploading = true);
        try {
          final json = await repo.uploadMedia(
            bytes: _photoBytes!,
            filename: _photo?.name ?? 'report.${_fileExtFromName(_photo?.name)}',
            latitude: pos.latitude,
            longitude: pos.longitude,
            disasterType: disasterType,
            userId: user?.id,
          );
          final url = (json['url'] ?? '').toString();
          if (url.isEmpty) throw Exception('Upload returned empty url');
          if (!mounted) return;
          setState(() {
            _uploadedUrl = url;
            _uploadFailed = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _uploadFailed = true);
        } finally {
          if (mounted) setState(() => _uploading = false);
        }
      }

      final urlPart = _uploadedUrl == null ? '' : ' | ${_uploadedUrl!}';
      final observation = note.isEmpty ? '$typeText$urlPart' : '$typeText | $note$urlPart';

      await repo.postSocialObservation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        disasterType: disasterType,
        observation: observation,
        userId: user?.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (lang) {
              AppLanguage.hi => 'ऑब्ज़र्वेशन पोस्ट हुआ।',
              AppLanguage.kn => 'ವೀಕ್ಷಣೆ ಪೋಸ್ಟ್ ಆಯಿತು.',
              AppLanguage.en => 'Observation posted.',
            },
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final busy = _submitting || _uploading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (lang) {
            AppLanguage.hi => 'रिपोर्ट',
            AppLanguage.kn => 'ವರದಿ',
            AppLanguage.en => 'Report',
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(ref, 'report_what_you_see'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            if (_photo == null)
              Expanded(
                child: Center(
                  child: Text(
                    switch (lang) {
                      AppLanguage.hi => 'कैमरा खोल रहे हैं…',
                      AppLanguage.kn => 'ಕ್ಯಾಮೆರಾ ತೆರೆಯುತ್ತಿದೆ…',
                      AppLanguage.en => 'Opening camera…',
                    },
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else ...[
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBytes == null
                    ? Center(
                        child: Text(
                          switch (lang) {
                            AppLanguage.hi => 'फोटो लोड हो रहा है…',
                            AppLanguage.kn => 'ಫೋಟೋ ಲೋಡ್ ಆಗುತ್ತಿದೆ…',
                            AppLanguage.en => 'Loading photo…',
                          },
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      )
                    : Image.memory(_photoBytes!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              if (_uploading || _uploadedUrl != null || _uploadFailed)
                Text(
                  _uploading
                      ? switch (lang) {
                          AppLanguage.hi => 'फोटो अपलोड हो रहा है…',
                          AppLanguage.kn => 'ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ…',
                          AppLanguage.en => 'Uploading photo…',
                        }
                      : (_uploadedUrl != null
                          ? switch (lang) {
                              AppLanguage.hi => 'फोटो संलग्न है',
                              AppLanguage.kn => 'ಫೋಟೋ ಸೇರಿಸಲಾಗಿದೆ',
                              AppLanguage.en => 'Photo attached',
                            }
                          : switch (lang) {
                              AppLanguage.hi => 'फोटो संलग्न नहीं हो पाया',
                              AppLanguage.kn => 'ಫೋಟೋ ಸೇರಿಸಲಾಗಲಿಲ್ಲ',
                              AppLanguage.en => 'Photo could not be attached',
                            }),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _uploadFailed
                            ? const Color(0xFFFF9F0A).withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in QuickDisasterType.values)
                    ChoiceChip(
                      label: Text(_typeLabel(lang, t)),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      selectedColor: Colors.white.withValues(alpha: 0.14),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: switch (lang) {
                    AppLanguage.hi => 'छोटा नोट (वैकल्पिक)',
                    AppLanguage.kn => 'ಸಣ್ಣ ಟಿಪ್ಪಣಿ (ಐಚ್ಛಿಕ)',
                    AppLanguage.en => 'Short note (optional)',
                  },
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _openCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          switch (lang) {
                            AppLanguage.hi => 'फिर से',
                            AppLanguage.kn => 'ಮತ್ತೆ',
                            AppLanguage.en => 'Retake',
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: busy ? null : _submit,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          switch (lang) {
                            AppLanguage.hi => 'पोस्ट करें',
                            AppLanguage.kn => 'ಪೋಸ್ಟ್',
                            AppLanguage.en => 'Post',
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

