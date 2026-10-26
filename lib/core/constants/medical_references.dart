import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum HealthRangeStatus {
  normal,
  warning,
  alert,
}

/// Official medical reference ranges compliant with WHO & Egyptian MOHP guidelines.
/// Purely informational and educational: does not diagnose or prescribe.
class MedicalReferences {
  MedicalReferences._();

  // Official Attribution Sources
  static const String sourceWHO = 'World Health Organization (WHO)';
  static const String sourceEDA = 'Egyptian Drug Authority (EDA)';
  static const String sourceMOHP = 'Ministry of Health and Population - Egypt';

  static const String disclaimerAr =
      'المحتوى المعروض في هذا التطبيق هو لأغراض تثقيفية وإعلامية عامة فقط، '
      'ولا يُعد بديلاً عن الاستشارة الطبية المتخصصة، أو التشخيص السريري، أو خطط العلاج المعتمدة. '
      'يُرجى دائماً مراجعة طبيبك المعالج أو مقدم الرعاية الصحية المؤهل عند وجود أي استفسار حول حالتك الصحية.';

  static const String disclaimerEn =
      'The information provided in this application is for general educational and informational purposes only '
      'and is not intended as a substitute for professional medical advice, clinical diagnosis, or treatment. '
      'Always seek the advice of your physician or qualified health provider with any questions regarding a medical condition.';

  // Blood Pressure Evaluation (Adult Resting, mmHg)
  // Normal: Systolic < 120 and Diastolic < 80
  // Warning (Elevated): Systolic 120-129 and Diastolic < 80
  // Alert (High): Systolic >= 130 or Diastolic >= 80
  static HealthRangeStatus evaluateBloodPressure(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80 && systolic >= 90 && diastolic >= 60) {
      return HealthRangeStatus.normal;
    } else if ((systolic >= 120 && systolic <= 129) && diastolic < 80) {
      return HealthRangeStatus.warning;
    } else {
      return HealthRangeStatus.alert;
    }
  }

  // Heart Rate Evaluation (Adult Resting, BPM)
  // Normal: 60 - 100 bpm
  // Warning: 50 - 59 or 101 - 110 bpm
  // Alert: < 50 or > 110 bpm
  static HealthRangeStatus evaluateHeartRate(int bpm) {
    if (bpm >= 60 && bpm <= 100) {
      return HealthRangeStatus.normal;
    } else if ((bpm >= 50 && bpm < 60) || (bpm > 100 && bpm <= 110)) {
      return HealthRangeStatus.warning;
    } else {
      return HealthRangeStatus.alert;
    }
  }

  // Fasting Blood Glucose (mg/dL)
  // Normal: 70 - 99 mg/dL
  // Warning: 100 - 125 mg/dL
  // Alert: < 70 or >= 126 mg/dL
  static HealthRangeStatus evaluateGlucose(double mgDl) {
    if (mgDl >= 70 && mgDl <= 99) {
      return HealthRangeStatus.normal;
    } else if (mgDl >= 100 && mgDl <= 125) {
      return HealthRangeStatus.warning;
    } else {
      return HealthRangeStatus.alert;
    }
  }

  // Oxygen Saturation SpO2 (%)
  // Normal: 95% - 100%
  // Warning: 90% - 94%
  // Alert: < 90%
  static HealthRangeStatus evaluateSpO2(int percentage) {
    if (percentage >= 95 && percentage <= 100) {
      return HealthRangeStatus.normal;
    } else if (percentage >= 90 && percentage < 95) {
      return HealthRangeStatus.warning;
    } else {
      return HealthRangeStatus.alert;
    }
  }

  // BMI Interpretation (Safe general wellness metric)
  static String interpretBMI(double bmi, bool isArabic) {
    if (bmi < 18.5) {
      return isArabic ? 'نقص في الوزن' : 'Underweight';
    } else if (bmi < 25.0) {
      return isArabic ? 'وزن طبيعي' : 'Normal Weight';
    } else if (bmi < 30.0) {
      return isArabic ? 'وزن زائد' : 'Overweight';
    } else {
      return isArabic ? 'سمنة' : 'Obese';
    }
  }

  static Color getStatusColor(HealthRangeStatus status) {
    switch (status) {
      case HealthRangeStatus.normal:
        return AppColors.statusNormal;
      case HealthRangeStatus.warning:
        return AppColors.statusWarning;
      case HealthRangeStatus.alert:
        return AppColors.statusAlert;
    }
  }

  static Color getStatusBgColor(HealthRangeStatus status) {
    switch (status) {
      case HealthRangeStatus.normal:
        return AppColors.statusNormalBg;
      case HealthRangeStatus.warning:
        return AppColors.statusWarningBg;
      case HealthRangeStatus.alert:
        return AppColors.statusAlertBg;
    }
  }

  static String getStatusLabel(HealthRangeStatus status, bool isArabic) {
    switch (status) {
      case HealthRangeStatus.normal:
        return isArabic ? 'ضمن المعدل الطبيعي' : 'Within Normal Range';
      case HealthRangeStatus.warning:
        return isArabic ? 'ملاحظة: قريب من الحد' : 'Borderline / Caution';
      case HealthRangeStatus.alert:
        return isArabic ? 'خارج النطاق الطبيعي: يُرجى استشارة الطبيب' : 'Out of Range: Consult Doctor';
    }
  }
}
