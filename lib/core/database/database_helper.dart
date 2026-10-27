import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../security/secure_key_storage.dart';
import '../constants/medical_references.dart';

class DatabaseHelper {
  static const String _secureDatabaseName = 'nabd_secure_v5.db';
  static const int _secureDatabaseVersion = 5;
  static const String _catalogDatabaseName = 'nabd_catalog.db';

  final SecureKeyStorage _keyStorage;
  Database? _secureDb;
  Database? _catalogDb;

  DatabaseHelper({SecureKeyStorage? keyStorage})
      : _keyStorage = keyStorage ?? SecureKeyStorage();

  /// Secure encrypted database for HIPAA/OWASP protected PHI (vital signs, medication reminders)
  Future<Database> get database async {
    if (_secureDb != null && _secureDb!.isOpen) return _secureDb!;
    _secureDb = await _initEncryptedDatabase();
    return _secureDb!;
  }

  /// High-performance offline catalog database (26,500+ Egyptian medications, labs, diseases)
  /// Kept unencrypted for instant ~2-4ms B-Tree search without AES decryption overhead.
  Future<Database> get catalogDatabase async {
    if (_catalogDb != null && _catalogDb!.isOpen) return _catalogDb!;
    _catalogDb = await _initCatalogDatabase();
    return _catalogDb!;
  }

  Future<Database> _initCatalogDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _catalogDatabaseName);
    final file = File(path);

    bool needsCopy = true;
    if (await file.exists()) {
      final len = await file.length();
      // The complete precompiled catalog is ~61MB. If file is present and >= 50MB, it's valid.
      if (len >= 50000000) {
        needsCopy = false;
      }
    }

    if (needsCopy) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      try {
        // 1. Try to load compressed gzip catalog asset (9.6MB) and decompress in ~130ms
        try {
          final byteData = await rootBundle.load('assets/database/nabd_catalog.db.gz');
          final compressedBytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          final decompressedBytes = gzip.decode(compressedBytes);
          await file.writeAsBytes(decompressedBytes, flush: true);
        } catch (_) {
          // 2. Fallback to uncompressed asset if present
          final byteData = await rootBundle.load('assets/database/nabd_catalog.db');
          final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          await file.writeAsBytes(bytes, flush: true);
        }
      } catch (e) {
        // Fallback for unit tests or local execution
        final gzFallback = File('assets/database/nabd_catalog.db.gz');
        if (await gzFallback.exists()) {
          final decompressed = gzip.decode(await gzFallback.readAsBytes());
          await file.writeAsBytes(decompressed, flush: true);
        } else {
          final dbFallback = File('assets/database/nabd_catalog.db');
          if (await dbFallback.exists()) {
            await dbFallback.copy(path);
          }
        }
      }
    }

    return await openDatabase(
      path,
      readOnly: false,
    );
  }

  Future<Database> _initEncryptedDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _secureDatabaseName);

    // Retrieve hardware-backed AES-256 key from Android Keystore / iOS Keychain
    final encryptionKey = await _keyStorage.getOrCreateDatabaseEncryptionKey();

    return await openDatabase(
      path,
      version: _secureDatabaseVersion,
      password: encryptionKey,
      onCreate: _onCreateSecure,
      onUpgrade: _onUpgradeSecure,
    );
  }

  Future<void> _onUpgradeSecure(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS vital_logs;');
    await db.execute('DROP TABLE IF EXISTS medication_reminders;');
    await _onCreateSecure(db, newVersion);
  }

  Future<void> _onCreateSecure(Database db, int version) async {
    // 1. Personal Vital Signs Logs (Encrypted Local PHI)
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

    // 2. Medication Reminders Table (Supports One-Time and Recurring Reminders)
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
    final db = await catalogDatabase;
    final cleanQuery = '%${query.trim()}%';
    final normQuery = '%${normalizeArabicText(query)}%';

    final results = <Map<String, dynamic>>[];

    // Medications (Bilingual Search with Active Ingredient & Brand matching)
    final meds = await db.rawQuery('''
      SELECT 'medication' as type, id, name_ar, name_en, active_ingredient_ar, active_ingredient_en, category_ar, category_en, dosage_form_ar, company, price_egp, official_source, official_url
      FROM medications
      WHERE search_tokens LIKE ? OR name_ar LIKE ? OR name_en LIKE ? OR scientific_name LIKE ? OR active_ingredient_ar LIKE ? OR active_ingredient_en LIKE ?
      LIMIT 30;
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

  Future<List<Map<String, dynamic>>> getMedications({String? filter, int limit = 60, int offset = 0}) async {
    final db = await catalogDatabase;
    if (filter != null && filter.trim().isNotEmpty) {
      final raw = '%${filter.trim()}%';
      final norm = '%${normalizeArabicText(filter)}%';
      return await db.rawQuery('''
        SELECT * FROM medications
        WHERE search_tokens LIKE ? OR name_ar LIKE ? OR name_en LIKE ? OR scientific_name LIKE ? OR active_ingredient_ar LIKE ? OR active_ingredient_en LIKE ?
        ORDER BY name_ar ASC
        LIMIT ? OFFSET ?;
      ''', [norm, raw, raw, raw, raw, raw, limit, offset]);
    }
    return await db.rawQuery('''
      SELECT * FROM medications
      ORDER BY name_ar ASC
      LIMIT ? OFFSET ?;
    ''', [limit, offset]);
  }

  Future<Map<String, dynamic>?> getMedicationById(int id) async {
    final db = await catalogDatabase;
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
    final db = await catalogDatabase;
    // 1. Direct identical active ingredient substitutes (المثائل المتطابقة)
    final exact = await db.rawQuery('''
      SELECT * FROM medications
      WHERE id != ? AND (
        active_ingredient_en = ? OR active_ingredient_ar = ? OR scientific_name = ?
      )
      ORDER BY name_ar ASC
      LIMIT 25;
    ''', [medicationId, activeIngredientEn, activeIngredientAr, activeIngredientEn]);

    if (exact.isNotEmpty) return exact;

    // 2. Therapeutic class alternatives (البدائل العلاجية من نفس العائلة الدوائية)
    if (categoryEn != null && categoryEn.isNotEmpty) {
      return await db.rawQuery('''
        SELECT * FROM medications
        WHERE id != ? AND category_en = ?
        ORDER BY name_ar ASC
        LIMIT 15;
      ''', [medicationId, categoryEn]);
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> getLabTests({String? filter}) async {
    final db = await catalogDatabase;
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
    final db = await catalogDatabase;
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

  Future<void> close() async {
    if (_secureDb != null && _secureDb!.isOpen) {
      await _secureDb!.close();
      _secureDb = null;
    }
    if (_catalogDb != null && _catalogDb!.isOpen) {
      await _catalogDb!.close();
      _catalogDb = null;
    }
  }
}

