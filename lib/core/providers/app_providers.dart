import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../notifications/notification_service.dart';
import '../security/secure_key_storage.dart';
import '../security/security_service.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/main_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

// Language State Provider (Defaults to Arabic 'ar')
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ar');

  void toggleLanguage() {
    state = state == 'ar' ? 'en' : 'ar';
  }

  void setLanguage(String code) {
    if (code == 'ar' || code == 'en') {
      state = code;
    }
  }
}

// Theme Mode Provider (Light / Dark)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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

// Secure Key Storage Provider
final secureKeyStorageProvider = Provider<SecureKeyStorage>((ref) {
  return SecureKeyStorage();
});

// App Startup Provider: determines initial destination based on persistent session
final appStartupProvider = FutureProvider<Widget>((ref) async {
  final storage = ref.watch(secureKeyStorageProvider);
  final isSessionActive = await storage.readSecureToken('nabd_user_session_active');
  if (isSessionActive == 'true') {
    return const MainScreen();
  }
  final isOnboardingDone = await storage.readSecureToken('nabd_onboarding_completed');
  if (isOnboardingDone == 'true') {
    return const AuthScreen();
  }
  return const OnboardingScreen();
});
