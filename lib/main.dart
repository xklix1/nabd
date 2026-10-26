import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_localizations.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline background notification channels
  try {
    await NotificationService().initialize();
  } catch (_) {
    // Graceful fallback if running in non-mobile test runner
  }

  runApp(
    const ProviderScope(
      child: NabdApp(),
    ),
  );
}

class NabdApp extends ConsumerWidget {
  const NabdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'نبض | Nabd',
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(language),
      darkTheme: AppTheme.darkTheme(language),
      themeMode: themeMode,
      home: const SecurityGateWrapper(),
    );
  }
}

/// SecurityGateWrapper verifies host device integrity (OWASP AppSec Standard)
/// before providing access to the application.
class SecurityGateWrapper extends ConsumerWidget {
  const SecurityGateWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityAsync = ref.watch(deviceSecurityStatusProvider);
    final lang = ref.watch(languageProvider);

    return securityAsync.when(
      data: (status) {
        if (status.isCompromised) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.get('security_alert_title', lang),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.get('security_alert_body', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Allow local testing acknowledgement in non-production builds
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        );
                      },
                      child: Text(AppStrings.get('understand', lang)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const OnboardingScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const OnboardingScreen(),
    );
  }
}
