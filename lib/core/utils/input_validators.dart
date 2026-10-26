/// Strict input validation and range checking for vital signs and wellness calculators.
/// Rejects negative, malformed, or clinically impossible inputs to guarantee data integrity.
class InputValidators {
  InputValidators._();

  static String? validateHeartRate(String? value, bool isArabic) {
    if (value == null || value.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال معدل نبضات القلب' : 'Please enter heart rate';
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return isArabic ? 'أدخل رقماً صحيحاً فقط' : 'Enter a valid integer';
    }
    if (num < 30 || num > 250) {
      return isArabic
          ? 'القيمة خارج النطاق المقبول (30 - 250 نبضة/دقيقة)'
          : 'Value out of bounds (30 - 250 bpm)';
    }
    return null;
  }

  static String? validateBloodPressure({
    required String? systolicStr,
    required String? diastolicStr,
    required bool isArabic,
  }) {
    if (systolicStr == null || systolicStr.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال الضغط الانقباضي' : 'Please enter systolic value';
    }
    if (diastolicStr == null || diastolicStr.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال الضغط الانبساطي' : 'Please enter diastolic value';
    }

    final sys = int.tryParse(systolicStr.trim());
    final dia = int.tryParse(diastolicStr.trim());

    if (sys == null || dia == null) {
      return isArabic ? 'يرجى إدخال أرقام صحيحة' : 'Enter valid numbers';
    }

    if (sys < 50 || sys > 260) {
      return isArabic
          ? 'الضغط الانقباضي خارج النطاق المقبول (50 - 260)'
          : 'Systolic value out of bounds (50 - 260)';
    }

    if (dia < 30 || dia > 180) {
      return isArabic
          ? 'الضغط الانبساطي خارج النطاق المقبول (30 - 180)'
          : 'Diastolic value out of bounds (30 - 180)';
    }

    if (sys <= dia) {
      return isArabic
          ? 'يجب أن يكون الضغط الانقباضي أعلى من الانبساطي'
          : 'Systolic must be strictly greater than diastolic';
    }

    return null;
  }

  static String? validateGlucose(String? value, bool isArabic) {
    if (value == null || value.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال مستوى السكر' : 'Please enter blood glucose';
    }
    final num = double.tryParse(value.trim());
    if (num == null) {
      return isArabic ? 'يرجى إدخال رقم صحيح أو عشري' : 'Enter a valid number';
    }
    if (num < 20.0 || num > 600.0) {
      return isArabic
          ? 'القيمة خارج النطاق المقبول (20 - 600 مجم/ديسيلتر)'
          : 'Value out of bounds (20 - 600 mg/dL)';
    }
    return null;
  }

  static String? validateSpO2(String? value, bool isArabic) {
    if (value == null || value.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال نسبة الأكسجين' : 'Please enter SpO2';
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return isArabic ? 'يرجى إدخال رقم صحيح' : 'Enter an integer';
    }
    if (num < 50 || num > 100) {
      return isArabic
          ? 'نسبة الأكسجين يجب أن تكون بين 50% و 100%'
          : 'SpO2 must be between 50% and 100%';
    }
    return null;
  }

  static String? validateHeight(String? value, bool isArabic) {
    if (value == null || value.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال الطول بالسم' : 'Please enter height in cm';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num < 50 || num > 250) {
      return isArabic ? 'الطول يجب أن يكون بين 50 و 250 سم' : 'Height must be between 50 and 250 cm';
    }
    return null;
  }

  static String? validateWeight(String? value, bool isArabic) {
    if (value == null || value.trim().isEmpty) {
      return isArabic ? 'يرجى إدخال الوزن بالكجم' : 'Please enter weight in kg';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num < 20 || num > 350) {
      return isArabic ? 'الوزن يجب أن يكون بين 20 و 350 كجم' : 'Weight must be between 20 and 350 kg';
    }
    return null;
  }
}
