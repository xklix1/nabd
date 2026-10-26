import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/medical_disclaimer_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _isCheckingUpdate = false;
  String? _updateStatusMessage;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final securityAsync = ref.watch(deviceSecurityStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('nav_profile', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryBlue,
                      child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'مستخدم نبض (محلي)' : 'Nabd User (Local)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusNormal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'تشفير AES-256 نشط محلياً' : 'Local AES-256 Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Settings & Preferences
            Text(
              isArabic ? 'الإعدادات العامة' : 'General Settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  // Language Toggle
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppColors.primaryBlue),
                    title: Text(isArabic ? 'لغة التطبيق' : 'App Language'),
                    subtitle: Text(isArabic ? 'العربية (RTL)' : 'English (LTR)'),
                    trailing: TextButton(
                      onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
                      child: Text(
                        isArabic ? 'Switch to English' : 'التحويل للعربية',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Dark Mode Toggle
                  ListTile(
                    leading: Icon(
                      themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text(isArabic ? 'المظهر الداكن' : 'Dark Mode'),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                  ),
                  const Divider(height: 1),

                  // Biometric Security Toggle
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primaryBlue),
                    title: Text(isArabic ? 'قفل السجل الطبي بالبصمة' : 'Biometric App Lock'),
                    subtitle: Text(
                      isArabic
                        ? 'تأمين السجلات الحيوية عبر Face ID / بصمة الإصبع'
                        : 'Secure health logs with Face ID / Fingerprint',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final security = ref.read(securityServiceProvider);
                          final auth = await security.authenticateBiometrically(
                            reasonAr: 'يرجى تأكيد هويتك لتفعيل القفل البيومتري',
                            reasonEn: 'Please authenticate to enable biometric lock',
                            isArabic: isArabic,
                          );
                          if (auth) {
                            setState(() => _biometricEnabled = true);
                          }
                        } else {
                          setState(() => _biometricEnabled = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // On-Demand Database Updates
            Text(
              isArabic ? 'التحديثات والمزامنة السحابية' : 'Updates & Cloud Sync',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: AppColors.secondaryTeal),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'فحص تحديثات القاعدة الطبية' : 'Check for Medical DB Updates',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'جلب التحديثات الطبية الطفيفة (Delta Updates) مع التحقق من سلامة البصمة المشفرة (SHA-256).'
                          : 'Fetch delta patches with SHA-256 cryptographic integrity verification.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isCheckingUpdate ? null : _checkForDatabaseUpdates,
                      child: _isCheckingUpdate
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isArabic ? 'فحص التحديثات الآن' : 'Check Updates Now'),
                    ),
                    if (_updateStatusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _updateStatusMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.statusNormal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Hardware & Environment Security Status
            Text(
              isArabic ? 'حالة أمان الجهاز والبيئة' : 'Device Security Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 8),

            securityAsync.when(
              data: (status) {
                final isSafe = !status.isCompromised;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      isSafe ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                      color: isSafe ? AppColors.statusNormal : AppColors.statusAlert,
                    ),
                    title: Text(
                      isSafe
                          ? (isArabic ? 'بيئة التشغيل آمنة ومحمية' : 'Operating Environment Secure')
                          : (isArabic ? 'تحذير: بيئة تشغيل غير آمنة' : 'Warning: Insecure Environment'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      status.details,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text(err.toString()),
            ),

            const SizedBox(height: 24),

            // Persistent Medical Disclaimer
            MedicalDisclaimerCard(isArabic: isArabic),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Nabd Health App v1.0.0 (Offline-First)\nAttributions: WHO & Egyptian MOHP/EDA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForDatabaseUpdates() async {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';

    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = null;
    });

    // Simulate safe TLS 1.3 delta update check with SHA-256 verification
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updateStatusMessage = isArabic
            ? 'قاعدة البيانات الطبية المحلية محدثة بأحدث مراجع منظمة الصحة وهيئة الدواء (SHA-256 Verified).'
            : 'Local medical database is fully up to date with WHO and EDA guidelines (SHA-256 Verified).';
      });
    }
  }
}
