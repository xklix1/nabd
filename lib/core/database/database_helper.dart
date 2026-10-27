import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../security/secure_key_storage.dart';
import '../constants/medical_references.dart';
import 'seed_medications.dart';
import 'seed_lab_tests.dart';
import 'seed_diseases.dart';

class DatabaseHelper {
  static const String _databaseName = 'nabd_secure_v5.db';
  static const int _databaseVersion = 5;

  final SecureKeyStorage _keyStorage;
  Database? _db;

  DatabaseHelper({SecureKeyStorage? keyStorage})
      : _keyStorage = keyStorage ?? SecureKeyStorage();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initEncryptedDatabase();
    return _db!;
  }

  Future<Database> _initEncryptedDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    // Retrieve hardware-backed AES-256 key from Android Keystore / iOS Keychain
    final encryptionKey = await _keyStorage.getOrCreateDatabaseEncryptionKey();

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: encryptionKey,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS medications;');
    await db.execute('DROP TABLE IF EXISTS lab_tests;');
    await db.execute('DROP TABLE IF EXISTS diseases;');
    await db.execute('DROP TABLE IF EXISTS medication_reminders;');
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Medications Table (Comprehensive Egyptian Catalog with Form & Manufacturer)
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        scientific_name TEXT NOT NULL,
        active_ingredient_ar TEXT NOT NULL,
        active_ingredient_en TEXT NOT NULL,
        category_ar TEXT NOT NULL,
        category_en TEXT NOT NULL,
        dosage_form_ar TEXT NOT NULL DEFAULT '',
        dosage_form_en TEXT NOT NULL DEFAULT '',
        company TEXT NOT NULL DEFAULT '',
        indications_ar TEXT NOT NULL,
        indications_en TEXT NOT NULL,
        side_effects_ar TEXT NOT NULL,
        side_effects_en TEXT NOT NULL,
        contraindications_ar TEXT NOT NULL,
        contraindications_en TEXT NOT NULL,
        standard_dosage_ar TEXT NOT NULL,
        standard_dosage_en TEXT NOT NULL,
        official_source TEXT NOT NULL,
        official_url TEXT NOT NULL,
        search_tokens TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_med_names ON medications(name_ar, name_en, scientific_name);');
    await db.execute('CREATE INDEX idx_med_search ON medications(search_tokens);');
    await db.execute('CREATE INDEX idx_med_active ON medications(active_ingredient_en, active_ingredient_ar);');
    await db.execute('CREATE INDEX idx_med_category ON medications(category_en, category_ar);');

    // 2. Lab Tests Table (150+ Tests)
    await db.execute('''
      CREATE TABLE lab_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        code TEXT NOT NULL,
        explanation_ar TEXT NOT NULL,
        explanation_en TEXT NOT NULL,
        normal_range_ar TEXT NOT NULL,
        normal_range_en TEXT NOT NULL,
        unit TEXT NOT NULL,
        official_source TEXT NOT NULL,
        official_url TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_lab_names ON lab_tests(name_ar, name_en, code);');

    // 3. Diseases & Medical Conditions Table (150+ Conditions)
    await db.execute('''
      CREATE TABLE diseases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        category_ar TEXT NOT NULL DEFAULT 'عام',
        category_en TEXT NOT NULL DEFAULT 'General',
        overview_ar TEXT NOT NULL,
        overview_en TEXT NOT NULL,
        causes_ar TEXT NOT NULL,
        causes_en TEXT NOT NULL,
        symptoms_ar TEXT NOT NULL,
        symptoms_en TEXT NOT NULL,
        prevention_ar TEXT NOT NULL,
        prevention_en TEXT NOT NULL,
        initial_care_ar TEXT NOT NULL,
        initial_care_en TEXT NOT NULL,
        official_source TEXT NOT NULL,
        official_url TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_disease_names ON diseases(name_ar, name_en);');
    await db.execute('CREATE INDEX idx_disease_cat ON diseases(category_ar, category_en);');

    // 4. Personal Vital Signs Logs (Encrypted Local PHI)
    await db.execute('''
      CREATE TABLE vital_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value_primary REAL NOT NULL,
        value_secondary REAL,
        unit TEXT NOT NULL,
        status_evaluated TEXT NOT NULL,
        recorded_at TEXT NOT NULL
      );
    ''');

    // 5. Medication Reminders Table (Supports One-Time and Recurring Reminders)
    await db.execute('''
      CREATE TABLE medication_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_name TEXT NOT NULL,
        dose_description TEXT NOT NULL,
        first_dose_time TEXT NOT NULL,
        scheduled_date_time TEXT NOT NULL,
        interval_hours INTEGER NOT NULL,
        is_one_time INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      );
    ''');

    // Seed Verified Medical Reference Data (Exclusively WHO & Egyptian EDA/MOHP)
    await _seedInitialMedicalData(db);
  }

  Future<void> _seedInitialMedicalData(Database db) async {
    final batch = db.batch();

    // 1. Insert Egyptian Medications (230+)
    for (final med in getInitialMedications()) {
      batch.insert('medications', med);
    }

    // 2. Insert Comprehensive Medical Lab Tests (150+)
    for (final lab in getInitialLabTests()) {
      batch.insert('lab_tests', lab);
    }

    // 3. Insert Comprehensive Medical Diseases Encyclopedia (150+)
    for (final disease in getInitialDiseases()) {
      batch.insert('diseases', disease);
    }

    await batch.commit(noResult: true);
  }

  /// Normalizes Arabic text for flexible matching (alif forms, taa marbuta, yaa, diacritics).
  static String normalizeArabicText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .trim();
  }

  // Safe Parameterized Search Methods (OWASP SQLi Prevention)
  // Supports bilingual matching in Arabic and English with Arabic normalization
  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final db = await database;
    final cleanQuery = '%${query.trim()}%';
    final normQuery = '%${normalizeArabicText(query)}%';

    final results = <Map<String, dynamic>>[];

    // Medications (Bilingual Search with Active Ingredient & Brand matching)
    final meds = await db.rawQuery('''
      SELECT 'medication' as type, id, name_ar, name_en, active_ingredient_ar, active_ingredient_en, category_ar, category_en, official_source, official_url
      FROM medications
      WHERE search_tokens LIKE ? OR name_ar LIKE ? OR name_en LIKE ? OR scientific_name LIKE ? OR active_ingredient_ar LIKE ? OR active_ingredient_en LIKE ?
      LIMIT 25;
    ''', [normQuery, cleanQuery, cleanQuery, cleanQuery, cleanQuery, cleanQuery]);
    results.addAll(meds);

    // Lab Tests
    final labs = await db.rawQuery('''
      SELECT 'lab_test' as type, id, name_ar, name_en, code, explanation_ar, explanation_en, normal_range_ar, normal_range_en, unit, official_source, official_url
      FROM lab_tests
      WHERE name_ar LIKE ? OR name_en LIKE ? OR code LIKE ?
      LIMIT 15;
    ''', [cleanQuery, cleanQuery, cleanQuery]);
    results.addAll(labs);

    // Diseases
    final diseases = await db.rawQuery('''
      SELECT 'disease' as type, id, name_ar, name_en, overview_ar, overview_en, official_source, official_url
      FROM diseases
      WHERE name_ar LIKE ? OR name_en LIKE ?
      LIMIT 15;
    ''', [cleanQuery, cleanQuery]);
    results.addAll(diseases);

    return results;
  }

  Future<List<Map<String, dynamic>>> getMedications({String? filter}) async {
    final db = await database;
    if (filter != null && filter.trim().isNotEmpty) {
      final raw = '%${filter.trim()}%';
      final norm = '%${normalizeArabicText(filter)}%';
      return await db.rawQuery('''
        SELECT * FROM medications
        WHERE search_tokens LIKE ? OR name_ar LIKE ? OR name_en LIKE ? OR scientific_name LIKE ? OR active_ingredient_ar LIKE ? OR active_ingredient_en LIKE ?
        ORDER BY name_ar ASC;
      ''', [norm, raw, raw, raw, raw, raw]);
    }
    return await db.query('medications', orderBy: 'name_ar ASC');
  }

  Future<Map<String, dynamic>?> getMedicationById(int id) async {
    final db = await database;
    final res = await db.query('medications', where: 'id = ?', whereArgs: [id], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  /// Get direct equivalents (المثائل) and therapeutic alternatives (البدائل)
  Future<List<Map<String, dynamic>>> getMedicationSubstitutes({
    required int medicationId,
    required String activeIngredientEn,
    required String activeIngredientAr,
    String? categoryEn,
  }) async {
    final db = await database;
    // 1. Direct identical active ingredient substitutes (المثائل المتطابقة)
    final exact = await db.rawQuery('''
      SELECT * FROM medications
      WHERE id != ? AND (
        active_ingredient_en = ? OR active_ingredient_ar = ? OR scientific_name = ?
      )
      ORDER BY name_ar ASC;
    ''', [medicationId, activeIngredientEn, activeIngredientAr, activeIngredientEn]);

    if (exact.isNotEmpty) return exact;

    // 2. Therapeutic class alternatives (البدائل العلاجية من نفس العائلة الدوائية)
    if (categoryEn != null && categoryEn.isNotEmpty) {
      return await db.rawQuery('''
        SELECT * FROM medications
        WHERE id != ? AND category_en = ?
        ORDER BY name_ar ASC
        LIMIT 10;
      ''', [medicationId, categoryEn]);
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> getLabTests({String? filter}) async {
    final db = await database;
    if (filter != null && filter.trim().isNotEmpty) {
      final q = '%${filter.trim()}%';
      return await db.rawQuery('''
        SELECT * FROM lab_tests
        WHERE name_ar LIKE ? OR name_en LIKE ? OR code LIKE ?
        ORDER BY name_ar ASC;
      ''', [q, q, q]);
    }
    return await db.query('lab_tests', orderBy: 'name_ar ASC');
  }

  Future<List<Map<String, dynamic>>> getDiseases({String? filter, String? category}) async {
    final db = await database;
    if (category != null && category.isNotEmpty && category != 'all') {
      if (filter != null && filter.trim().isNotEmpty) {
        final q = '%${filter.trim()}%';
        return await db.rawQuery('''
          SELECT * FROM diseases
          WHERE (category_ar = ? OR category_en = ?) AND (name_ar LIKE ? OR name_en LIKE ?)
          ORDER BY name_ar ASC;
        ''', [category, category, q, q]);
      }
      return await db.query(
        'diseases',
        where: 'category_ar = ? OR category_en = ?',
        whereArgs: [category, category],
        orderBy: 'name_ar ASC',
      );
    }

    if (filter != null && filter.trim().isNotEmpty) {
      final q = '%${filter.trim()}%';
      return await db.rawQuery('''
        SELECT * FROM diseases
        WHERE name_ar LIKE ? OR name_en LIKE ? OR category_ar LIKE ? OR category_en LIKE ?
        ORDER BY name_ar ASC;
      ''', [q, q, q, q]);
    }
    return await db.query('diseases', orderBy: 'name_ar ASC');
  }

  // Vital Signs Logging (Encrypted PHI)
  Future<int> insertVitalLog({
    required String type,
    required double primaryValue,
    double? secondaryValue,
    required String unit,
    required String statusEvaluated,
  }) async {
    final db = await database;
    return await db.insert('vital_logs', {
      'type': type,
      'value_primary': primaryValue,
      'value_secondary': secondaryValue,
      'unit': unit,
      'status_evaluated': statusEvaluated,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentVitalLogs({int limit = 10}) async {
    final db = await database;
    return await db.query('vital_logs', orderBy: 'recorded_at DESC', limit: limit);
  }

  // Medication Reminders (Supports One-Time Exact Dose & Recurring Schedule)
  Future<int> insertReminder({
    required String medicationName,
    required String doseDescription,
    required String firstDoseTime,
    required String scheduledDateTime,
    required int intervalHours,
    required bool isOneTime,
  }) async {
    final db = await database;
    return await db.insert('medication_reminders', {
      'medication_name': medicationName,
      'dose_description': doseDescription,
      'first_dose_time': firstDoseTime,
      'scheduled_date_time': scheduledDateTime,
      'interval_hours': intervalHours,
      'is_one_time': isOneTime ? 1 : 0,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    final db = await database;
    return await db.query('medication_reminders', where: 'is_active = 1', orderBy: 'scheduled_date_time ASC, first_dose_time ASC');
  }

  Future<void> deleteReminder(int id) async {
    final db = await database;
    await db.delete('medication_reminders', where: 'id = ?', whereArgs: [id]);
  }
}
