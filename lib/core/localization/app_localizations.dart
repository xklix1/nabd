import 'package:flutter/material.dart';

class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _values = {
    'ar': {
      'app_name': 'نبض',
      'app_tagline': 'دليلك الصحي الرقمي الموثوق بدون إنترنت',
      
      // Bottom Navigation Tabs (5 Tabs RTL)
      'nav_home': 'الرئيسية',
      'nav_medications': 'الأدوية',
      'nav_labs': 'التحاليل',
      'nav_calc': 'حاسبة صحية',
      'nav_profile': 'الحساب',

      // Onboarding
      'onboarding_title_1': 'موسوعة طبية بدون إنترنت',
      'onboarding_desc_1': 'تصفح معلومات موثقة لآلاف الأدوية والتحاليل والأمراض وفق منظمة الصحة العالمية وهيئة الدواء المصرية دون الحاجة لاتصال بالإنترنت.',
      'onboarding_title_2': 'خصوصية وأمان تام لبياناتك',
      'onboarding_desc_2': 'سجلاتك الحيوية وملفك الصحي محفوظة بأعلى درجات الخصوصية والأمان داخل هاتفك، ومحمية ببصمة وجهك أو إصبعك.',
      'onboarding_title_3': 'تنبيهات ومتابعة دقيقة',
      'onboarding_desc_3': 'جدولة ذكية لجرعات الأدوية ومتابعة مستمرة لقياسات الضغط والسكر ومعدل النبض بأمان تام.',
      'next': 'التالي',
      'skip': 'تخطي',
      'get_started': 'ابدأ الآن',
      'consent_checkbox': 'أقر بأنني قرأت وفهمت إخلاء المسؤولية الطبي، وأن هذا التطبيق أداة تثقيفية وإرشادية عامة ولا يُعد بديلاً عن الطبيب المعالج أو التشخيص السريري.',

      // Auth
      'login_title': 'تسجيل الدخول',
      'register_title': 'إنشاء حساب جديد',
      'email_or_phone': 'البريد الإلكتروني أو رقم الهاتف',
      'password': 'كلمة المرور',
      'login_button': 'دخول',
      'register_button': 'تسجيل',
      'guest_login': 'المتابعة كزائر (استخدام محلي كامل)',
      'guest_notice': 'يمكنك استخدام كافة ميزات التطبيق محلياً دون الحاجة لإنشاء حساب.',

      // Dashboard
      'greeting': 'أهلاً بك',
      'search_hint': 'ابحث عن دواء، تحليل، أو مرض...',
      'vitals_card_title': 'القياسات الحيوية الأخيرة',
      'record_vital': 'تسجيل قياس جديد',
      'heart_rate': 'معدل النبض',
      'blood_pressure': 'ضغط الدم',
      'glucose': 'سكر الدم',
      'spo2': 'الأكسجين',
      'services_title': 'الخدمات والخدمات الطبية',
      'service_meds': 'دليل الأدوية',
      'service_meds_desc': 'دواعي الاستعمال، المحاذير والجرعات الرسمية',
      'service_labs': 'دليل التحاليل',
      'service_labs_desc': 'تفسيرات الفحوصات والنطاقات الطبيعية',
      'service_diseases': 'الموسوعة المرضية',
      'service_diseases_desc': 'الأعراض، الأسباب، والوقاية الأولية',
      'service_calc': 'حاسبة صحية',
      'service_calc_desc': 'كتلة الجسم، السعرات، والماء اليومي',
      'service_reminders': 'تذكير بالدواء',
      'service_reminders_desc': 'مواعيد الجرعات الدورية محلياً',

      // Security Warning
      'security_alert_title': 'تنبيه أمني هام',
      'security_alert_body': 'تم اكتشاف تعديل في نظام تشغيل الجهاز. لحماية خصوصية بياناتك وسجلاتك الصحية، تم تقييد الوصول إليها مؤقتاً.',
      'understand': 'فهمت ذلك',
    },
    'en': {
      'app_name': 'Nabd',
      'app_tagline': 'Your Trusted Offline Digital Health Reference',
      
      // Bottom Navigation Tabs (5 Tabs LTR)
      'nav_home': 'Home',
      'nav_medications': 'Medications',
      'nav_labs': 'Lab Tests',
      'nav_calc': 'Health Calc',
      'nav_profile': 'Profile',

      // Onboarding
      'onboarding_title_1': '100% Offline Medical Reference',
      'onboarding_desc_1': 'Access verified medical information for medications, lab tests, and diseases backed by WHO and EDA without needing internet.',
      'onboarding_title_2': 'Complete Privacy & Security',
      'onboarding_desc_2': 'Your vital health logs are stored strictly and privately on your device, protected by your biometric Face ID or Fingerprint.',
      'onboarding_title_3': 'Offline Medication Reminders',
      'onboarding_desc_3': 'Schedule smart dosage alarms and track vital signs such as blood pressure and heart rate safely.',
      'next': 'Next',
      'skip': 'Skip',
      'get_started': 'Get Started',
      'consent_checkbox': 'I confirm that I have read and agree to the Medical Disclaimer, acknowledging that this app is an educational tool and does not substitute for professional medical advice.',

      // Auth
      'login_title': 'Log In',
      'register_title': 'Create Account',
      'email_or_phone': 'Email or Phone Number',
      'password': 'Password',
      'login_button': 'Sign In',
      'register_button': 'Register',
      'guest_login': 'Continue as Guest (Full Offline Access)',
      'guest_notice': 'You can use all features offline without cloud registration.',

      // Dashboard
      'greeting': 'Welcome',
      'search_hint': 'Search medications, lab tests, or diseases...',
      'vitals_card_title': 'Latest Vital Readings',
      'record_vital': 'Log Reading',
      'heart_rate': 'Heart Rate',
      'blood_pressure': 'Blood Pressure',
      'glucose': 'Blood Glucose',
      'spo2': 'Oxygen SpO2',
      'services_title': 'Medical Services',
      'service_meds': 'Medications',
      'service_meds_desc': 'Indications, side effects & standard leaflets',
      'service_labs': 'Lab Tests',
      'service_labs_desc': 'Explanations & standard normal reference ranges',
      'service_diseases': 'Diseases Encyclopedia',
      'service_diseases_desc': 'Symptoms, causes & initial care guidelines',
      'service_calc': 'Health Calculators',
      'service_calc_desc': 'BMI, calorie needs & daily water intake',
      'service_reminders': 'Med Reminders',
      'service_reminders_desc': 'Exact offline background alerts',

      // Security Warning
      'security_alert_title': 'Security Alert',
      'security_alert_body': 'An altered system environment was detected on this device. To protect your personal health privacy, access to records has been temporarily restricted.',
      'understand': 'Understood',
    },
  };

  static String get(String key, String langCode) {
    return _values[langCode]?[key] ?? _values['ar']?[key] ?? key;
  }
}
