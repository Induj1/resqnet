import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  en('EN', Locale('en')),
  hi('हिंदी', Locale('hi')),
  kn('ಕನ್ನಡ', Locale('kn'));

  const AppLanguage(this.label, this.locale);
  final String label;
  final Locale locale;
}

final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  return AppLanguage.en;
});

const _strings = <String, Map<AppLanguage, String>>{
  'app_title': {
    AppLanguage.en: 'ResQNet',
    AppLanguage.hi: 'रेस्क्यूनेट',
    AppLanguage.kn: 'ರೆಸ್ಕ್ಯೂನೆಟ್',
  },
  'offline': {
    AppLanguage.en: 'OFFLINE',
    AppLanguage.hi: 'ऑफ़लाइन',
    AppLanguage.kn: 'ಆಫ್‌ಲೈನ್',
  },
  'online': {
    AppLanguage.en: 'ONLINE',
    AppLanguage.hi: 'ऑनलाइन',
    AppLanguage.kn: 'ಆನ್‌ಲೈನ್',
  },
  'area_risk': {
    AppLanguage.en: 'Area Risk',
    AppLanguage.hi: 'क्षेत्र जोखिम',
    AppLanguage.kn: 'ಪ್ರದೇಶದ ಅಪಾಯ',
  },
  'safe': {
    AppLanguage.en: 'SAFE',
    AppLanguage.hi: 'सुरक्षित',
    AppLanguage.kn: 'ಸುರಕ್ಷಿತ',
  },
  'moderate': {
    AppLanguage.en: 'MODERATE',
    AppLanguage.hi: 'मध्यम',
    AppLanguage.kn: 'ಮಧ್ಯಮ',
  },
  'high': {
    AppLanguage.en: 'HIGH',
    AppLanguage.hi: 'उच्च',
    AppLanguage.kn: 'ಹೆಚ್ಚು',
  },
  'tap_for_map': {
    AppLanguage.en: 'Tap to view map',
    AppLanguage.hi: 'मानचित्र देखने के लिए टैप करें',
    AppLanguage.kn: 'ನಕ್ಷೆ ನೋಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
  },
  'sos_title': {
    AppLanguage.en: 'EMERGENCY SOS',
    AppLanguage.hi: 'आपातकालीन SOS',
    AppLanguage.kn: 'ತುರ್ತು SOS',
  },
  'sos_subtitle': {
    AppLanguage.en: 'Tap if you are in danger',
    AppLanguage.hi: 'खतरे में हों तो टैप करें',
    AppLanguage.kn: 'ಅಪಾಯದಲ್ಲಿದ್ದರೆ ಟ್ಯಾಪ್ ಮಾಡಿ',
  },
  'need_help_now': {
    AppLanguage.en: 'Need Help Now?',
    AppLanguage.hi: 'अभी मदद चाहिए?',
    AppLanguage.kn: 'ಈಗ ಸಹಾಯ ಬೇಕೇ?',
  },
  'speak': {
    AppLanguage.en: 'Speak',
    AppLanguage.hi: 'बोलें',
    AppLanguage.kn: 'ಮಾತನಾಡಿ',
  },
  'type': {
    AppLanguage.en: 'Type',
    AppLanguage.hi: 'लिखें',
    AppLanguage.kn: 'ಟೈಪ್',
  },
  'report_what_you_see': {
    AppLanguage.en: 'Report What You See',
    AppLanguage.hi: 'जो दिखे, रिपोर्ट करें',
    AppLanguage.kn: 'ನೀವು ನೋಡಿದುದನ್ನು ವರದಿ ಮಾಡಿ',
  },
  'shelter_finder': {
    AppLanguage.en: 'Shelter Finder',
    AppLanguage.hi: 'आश्रय खोजें',
    AppLanguage.kn: 'ಆಶ್ರಯ ಹುಡುಕಿ',
  },
  'view_safe_route': {
    AppLanguage.en: 'View Safe Route',
    AppLanguage.hi: 'सुरक्षित मार्ग देखें',
    AppLanguage.kn: 'ಸುರಕ್ಷಿತ ದಾರಿ ನೋಡಿ',
  },
  'live_alerts': {
    AppLanguage.en: 'Live Alerts',
    AppLanguage.hi: 'लाइव अलर्ट',
    AppLanguage.kn: 'ಲೈವ್ ಎಚ್ಚರಿಕೆಗಳು',
  },
  'family_update': {
    AppLanguage.en: 'Send Family Update',
    AppLanguage.hi: 'परिवार को अपडेट भेजें',
    AppLanguage.kn: 'ಕುಟುಂಬಕ್ಕೆ ಅಪ್ಡೇಟ್ ಕಳುಹಿಸಿ',
  },
  'advanced_tools': {
    AppLanguage.en: 'AI Safety Desk',
    AppLanguage.hi: 'AI सुरक्षा डेस्क',
    AppLanguage.kn: 'AI ಭದ್ರತಾ ಕೇಂದ್ರ',
  },
  'ai_toolkit': {
    AppLanguage.en: 'All AI Features',
    AppLanguage.hi: 'सभी AI फीचर्स',
    AppLanguage.kn: 'ಎಲ್ಲ AI ವೈಶಿಷ್ಟ್ಯಗಳು',
  },
  'detailed_report': {
    AppLanguage.en: 'Full Report Form',
    AppLanguage.hi: 'पूरी रिपोर्ट फॉर्म',
    AppLanguage.kn: 'ಪೂರ್ಣ ವರದಿ ಫಾರ್ಮ್',
  },
  'track_sos': {
    AppLanguage.en: 'Track SOS',
    AppLanguage.hi: 'SOS ट्रैक करें',
    AppLanguage.kn: 'SOS ಟ್ರ್ಯಾಕ್',
  },
  'confirm_sighting': {
    AppLanguage.en: 'I can see this too',
    AppLanguage.hi: 'मैं भी देख सकता/सकती हूँ',
    AppLanguage.kn: 'ನಾನೂ ನೋಡುತ್ತಿದ್ದೇನೆ',
  },
  'confirm': {
    AppLanguage.en: 'Confirm',
    AppLanguage.hi: 'पुष्टि',
    AppLanguage.kn: 'ದೃಢೀಕರಿಸಿ',
  },
  'confirmations': {
    AppLanguage.en: 'confirmations',
    AppLanguage.hi: 'पुष्टियाँ',
    AppLanguage.kn: 'ದೃಢೀಕರಣಗಳು',
  },
  'quick_safe': {
    AppLanguage.en: "I'm safe",
    AppLanguage.hi: 'मैं सुरक्षित हूँ',
    AppLanguage.kn: 'ನಾನು ಸುರಕ್ಷಿತ',
  },
  'quick_need_help': {
    AppLanguage.en: 'Need help',
    AppLanguage.hi: 'मदद चाहिए',
    AppLanguage.kn: 'ಸಹಾಯ ಬೇಕು',
  },
  'copied': {
    AppLanguage.en: 'Copied.',
    AppLanguage.hi: 'कॉपी हो गया।',
    AppLanguage.kn: 'ಕಾಪಿ ಆಯಿತು.',
  },
  'people_count': {
    AppLanguage.en: 'People',
    AppLanguage.hi: 'लोग',
    AppLanguage.kn: 'ಜನ',
  },
  'injury': {
    AppLanguage.en: 'Injury',
    AppLanguage.hi: 'चोट',
    AppLanguage.kn: 'ಗಾಯ',
  },
  'yes': {
    AppLanguage.en: 'YES',
    AppLanguage.hi: 'हाँ',
    AppLanguage.kn: 'ಹೌದು',
  },
  'no': {
    AppLanguage.en: 'NO',
    AppLanguage.hi: 'नहीं',
    AppLanguage.kn: 'ಇಲ್ಲ',
  },
  'send_sos': {
    AppLanguage.en: 'Send SOS',
    AppLanguage.hi: 'SOS भेजें',
    AppLanguage.kn: 'SOS ಕಳುಹಿಸಿ',
  },
  'cancel': {
    AppLanguage.en: 'Cancel',
    AppLanguage.hi: 'रद्द करें',
    AppLanguage.kn: 'ರದ್ದು',
  },
};

String tr(WidgetRef ref, String key) {
  final lang = ref.watch(appLanguageProvider);
  final map = _strings[key];
  if (map == null) return key;
  return map[lang] ?? map[AppLanguage.en] ?? key;
}

