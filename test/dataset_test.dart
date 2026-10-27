import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/database/database_helper.dart';
import 'package:nabd/core/database/seed_medications.dart';
import 'package:nabd/core/database/seed_lab_tests.dart';
import 'package:nabd/core/database/seed_diseases.dart';

void main() {
  group('Comprehensive Medical Catalog Validation', () {
    test('Egyptian Medications catalog has >= 230 medications with rich attributes', () {
      final meds = getInitialMedications();
      expect(meds.length, greaterThanOrEqualTo(230));

      for (final med in meds) {
        expect(med['name_ar'], isNotEmpty);
        expect(med['name_en'], isNotEmpty);
        expect(med['active_ingredient_ar'], isNotEmpty);
        expect(med['active_ingredient_en'], isNotEmpty);
        expect(med['dosage_form_ar'], isNotEmpty);
        expect(med['company'], isNotEmpty);
        expect(med['official_source'], isNotEmpty);
        expect(med['search_tokens'], isNotEmpty);
      }
    });

    test('Laboratory Tests catalog has >= 150 tests with clinical references', () {
      final labs = getInitialLabTests();
      expect(labs.length, greaterThanOrEqualTo(150));

      for (final lab in labs) {
        expect(lab['name_ar'], isNotEmpty);
        expect(lab['name_en'], isNotEmpty);
        expect(lab['code'], isNotEmpty);
        expect(lab['normal_range_ar'], isNotEmpty);
        expect(lab['explanation_ar'], isNotEmpty);
      }
    });

    test('Medical Diseases encyclopedia has >= 150 conditions across specialties', () {
      final diseases = getInitialDiseases();
      expect(diseases.length, greaterThanOrEqualTo(150));

      for (final d in diseases) {
        expect(d['name_ar'], isNotEmpty);
        expect(d['name_en'], isNotEmpty);
        expect(d['category_ar'], isNotEmpty);
        expect(d['overview_ar'], isNotEmpty);
        expect(d['symptoms_ar'], isNotEmpty);
        expect(d['causes_ar'], isNotEmpty);
      }
    });

    test('DatabaseHelper Arabic normalization normalizes alif, taa marbuta, and diacritics', () {
      expect(DatabaseHelper.normalizeArabicText('أوجمنتين 1 جم'), 'اوجمنتين 1 جم');
      expect(DatabaseHelper.normalizeArabicText('إيبوبروفين'), 'ايبوبروفين');
      expect(DatabaseHelper.normalizeArabicText('مضادات حيوية'), 'مضادات حيويه');
      expect(DatabaseHelper.normalizeArabicText('فحص دَمٌ'), 'فحص دم');
    });
  });
}
