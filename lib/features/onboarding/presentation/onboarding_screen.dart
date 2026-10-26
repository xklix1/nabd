import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasAcceptedDisclaimer = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      _OnboardingPageData(
        icon: Icons.offline_bolt_rounded,
        title: AppStrings.get('onboarding_title_1', lang),
        description: AppStrings.get('onboarding_desc_1', lang),
      ),
      _OnboardingPageData(
        icon: Icons.security_rounded,
        title: AppStrings.get('onboarding_title_2', lang),
        description: AppStrings.get('onboarding_desc_2', lang),
      ),
      _OnboardingPageData(
        icon: Icons.alarm_on_rounded,
        title: AppStrings.get('onboarding_title_3', lang),
        description: AppStrings.get('onboarding_desc_3', lang),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
            icon: const Icon(Icons.language_rounded, size: 20),
            label: Text(
              isArabic ? 'English' : 'العربية',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceCard : AppColors.primaryLightBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
                          ),
                          child: Icon(page.icon, size: 56, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryBlue
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mandatory Legal Disclaimer Checkbox on Final Page
            if (_currentPage == pages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasAcceptedDisclaimer
                          ? AppColors.statusNormal
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _hasAcceptedDisclaimer,
                        activeColor: AppColors.primaryBlue,
                        onChanged: (val) {
                          setState(() => _hasAcceptedDisclaimer = val ?? false);
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _hasAcceptedDisclaimer = !_hasAcceptedDisclaimer);
                          },
                          child: Text(
                            AppStrings.get('consent_checkbox', lang),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Next / Get Started Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ElevatedButton(
                onPressed: (_currentPage == pages.length - 1 && !_hasAcceptedDisclaimer)
                    ? null
                    : () {
                        if (_currentPage < pages.length - 1) {
                          _pageController.animateToPage(
                            _currentPage + 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          ref.read(secureKeyStorageProvider).saveSecureToken('nabd_onboarding_completed', 'true');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                child: Text(
                  _currentPage == pages.length - 1
                      ? AppStrings.get('get_started', lang)
                      : AppStrings.get('next', lang),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
