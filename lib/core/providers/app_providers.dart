import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../notifications/notification_service.dart';
import '../security/secure_key_storage.dart';
import '../security/security_service.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/biometric_unlock_screen.dart';
import '../../features/dashboard/presentation/main_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

// Secure Key Storage Provider
final secureKeyStorageProvider = Provider<SecureKeyStorage>((ref) {
  return SecureKeyStorage();
});

// Initial Configuration Value Overrides (Loaded in main() before runApp for zero-flicker startup)
final initialLanguageProvider = Provider<String>((ref) => 'ar');
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);
final initialBiometricLockProvider = Provider<bool>((ref) => false);

// Language State Provider (Defaults to Arabic 'ar', persisted across restarts)
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final storage = ref.watch(secureKeyStorageProvider);
  final initial = ref.watch(initialLanguageProvider);
  return LanguageNotifier(storage, initial);
});

class LanguageNotifier extends StateNotifier<String> {
  final SecureKeyStorage _storage;

  LanguageNotifier(this._storage, String initial) : super(initial) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final saved = await _storage.readSecureToken('nabd_language_code');
    if (saved == 'ar' || saved == 'en') {
      if (state != saved) {
        state = saved!;
      }
    }
  }

  Future<void> toggleLanguage() async {
    state = state == 'ar' ? 'en' : 'ar';
    await _storage.saveSecureToken('nabd_language_code', state);
  }

  Future<void> setLanguage(String code) async {
    if (code == 'ar' || code == 'en') {
      state = code;
      await _storage.saveSecureToken('nabd_language_code', state);
    }
  }
}

// Theme Mode Provider (Light / Dark, persisted across restarts)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureKeyStorageProvider);
  final initial = ref.watch(initialThemeModeProvider);
  return ThemeModeNotifier(storage, initial);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SecureKeyStorage _storage;

  ThemeModeNotifier(this._storage, ThemeMode initial) : super(initial) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final saved = await _storage.readSecureToken('nabd_theme_mode');
    if (saved == 'dark') {
      if (state != ThemeMode.dark) state = ThemeMode.dark;
    } else if (saved == 'light') {
      if (state != ThemeMode.light) state = ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _storage.saveSecureToken(
      'nabd_theme_mode',
      state == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _storage.saveSecureToken(
      'nabd_theme_mode',
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

// Biometric App Lock Provider (Persisted across restarts)
final biometricLockProvider = StateNotifierProvider<BiometricLockNotifier, bool>((ref) {
  final storage = ref.watch(secureKeyStorageProvider);
  final initial = ref.watch(initialBiometricLockProvider);
  return BiometricLockNotifier(storage, initial);
});

class BiometricLockNotifier extends StateNotifier<bool> {
  final SecureKeyStorage _storage;

  BiometricLockNotifier(this._storage, bool initial) : super(initial) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final saved = await _storage.readSecureToken('nabd_biometric_enabled');
    final isEnabled = saved == 'true';
    if (state != isEnabled) {
      state = isEnabled;
    }
  }

  Future<void> setBiometricLock(bool enabled) async {
    state = enabled;
    await _storage.saveSecureToken(
      'nabd_biometric_enabled',
      enabled ? 'true' : 'false',
    );
  }
}

// Core Services Providers
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

// Device Security Status Async Provider
final deviceSecurityStatusProvider = FutureProvider<DeviceSecurityStatus>((ref) async {
  final securityService = ref.watch(securityServiceProvider);
  return await securityService.evaluateDeviceSecurity();
});

// Real-Time Offline Search Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final db = ref.watch(databaseHelperProvider);
  return await db.searchAll(query);
});

// Vital Logs Async Provider
final recentVitalLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseHelperProvider);
  return await db.getRecentVitalLogs(limit: 5);
});

// Active Reminders Count Provider
final activeRemindersCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseHelperProvider);
  final reminders = await db.getActiveReminders();
  return reminders.length;
});

// App Startup Provider: determines initial destination based on persistent session & biometric security
final appStartupProvider = FutureProvider<Widget>((ref) async {
  final storage = ref.watch(secureKeyStorageProvider);
  final isSessionActive = await storage.readSecureToken('nabd_user_session_active');

  if (isSessionActive == 'true') {
    // Check if biometric lock is enforced for medical records
    final biometricEnabled = await storage.readSecureToken('nabd_biometric_enabled');
    if (biometricEnabled == 'true') {
      return const BiometricUnlockScreen();
    }
    return const MainScreen();
  }

  final isOnboardingDone = await storage.readSecureToken('nabd_onboarding_completed');
  if (isOnboardingDone == 'true') {
    return const AuthScreen();
  }

  return const OnboardingScreen();
});
