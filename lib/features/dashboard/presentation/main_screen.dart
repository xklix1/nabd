import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/medical_references.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/medical_disclaimer_card.dart';
import '../../diseases/presentation/diseases_screen.dart';
import '../../health_calculators/presentation/calculators_screen.dart';
import '../../lab_tests/presentation/lab_tests_screen.dart';
import '../../medications/presentation/medications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../vital_signs/presentation/vital_signs_dialog.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    final screens = [
      const _DashboardTabView(),
      const MedicationsScreen(),
      const LabTestsScreen(),
      const CalculatorsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: AppStrings.get('nav_home', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medication_outlined),
            activeIcon: const Icon(Icons.medication_rounded),
            label: AppStrings.get('nav_medications', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.biotech_outlined),
            activeIcon: const Icon(Icons.biotech_rounded),
            label: AppStrings.get('nav_labs', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate_outlined),
            activeIcon: const Icon(Icons.calculate_rounded),
            label: AppStrings.get('nav_calc', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            activeIcon: const Icon(Icons.person_rounded),
            label: AppStrings.get('nav_profile', lang),
          ),
        ],
      ),
    );
  }
}

class _DashboardTabView extends ConsumerStatefulWidget {
  const _DashboardTabView();

  @override
  ConsumerState<_DashboardTabView> createState() => _DashboardTabViewState();
}

class _DashboardTabViewState extends ConsumerState<_DashboardTabView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchQuery = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final recentVitalsAsync = ref.watch(recentVitalLogsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // 1. Top Header: Avatar at start edge, username, Notifications icon at end edge
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('greeting', lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      isArabic ? 'زائر نبض' : 'Nabd User',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Search Bar directly below the header for real-time offline search
          TextField(
            controller: _searchController,
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).state = val;
            },
            decoration: InputDecoration(
              hintText: AppStrings.get('search_hint', lang),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Real-time Search Results overlay if active
          if (searchQuery.trim().isNotEmpty) ...[
            searchResultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        isArabic ? 'لا توجد نتائج مطابقة' : 'No matching results found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          isArabic ? 'نتائج البحث الفوري:' : 'Instant Results:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const Divider(height: 1),
                      ...results.map((item) {
                        final type = item['type'];
                        final name = isArabic ? item['name_ar'] : item['name_en'];
                        IconData icon;
                        String typeLabel;

                        if (type == 'medication') {
                          icon = Icons.medication_rounded;
                          typeLabel = isArabic ? 'دواء' : 'Medication';
                        } else if (type == 'lab_test') {
                          icon = Icons.biotech_rounded;
                          typeLabel = isArabic ? 'تحليل' : 'Lab Test';
                        } else {
                          icon = Icons.health_and_safety_outlined;
                          typeLabel = isArabic ? 'مرض' : 'Disease';
                        }

                        final activeIngredient = isArabic
                            ? item['active_ingredient_ar']
                            : item['active_ingredient_en'];

                        return ListTile(
                          leading: Icon(icon, color: AppColors.primaryBlue),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: activeIngredient != null
                              ? Text(
                                  activeIngredient,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Chip(
                            label: Text(typeLabel, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                          ),
                          onTap: () {
                            if (type == 'medication') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationsScreen()));
                            } else if (type == 'lab_test') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestsScreen()));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseasesScreen()));
                            }
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text(err.toString()),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Vital Signs Card: Latest recorded readings with visual normal comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monitor_heart_rounded, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.get('vitals_card_title', lang),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const VitalSignsDialog(),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: Text(AppStrings.get('record_vital', lang), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  recentVitalsAsync.when(
                    data: (logs) {
                      if (logs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              isArabic
                                  ? 'لم تسجل أي قياسات حيوية بعد. اضغط على "تسجيل قياس جديد" لحفظ قراءتك الحالية.'
                                  : 'No vitals logged yet. Tap "Log Reading" to track blood pressure or heart rate.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ),
                        );
                      }

                      final latest = logs.first;
                      final type = latest['type'];
                      final primary = latest['value_primary'];
                      final secondary = latest['value_secondary'];
                      final unit = latest['unit'];
                      final statusStr = latest['status_evaluated'];

                      HealthRangeStatus status = HealthRangeStatus.normal;
                      if (statusStr == 'warning') status = HealthRangeStatus.warning;
                      if (statusStr == 'alert') status = HealthRangeStatus.alert;

                      String displayValue = primary.toStringAsFixed(0);
                      if (secondary != null) {
                        displayValue = '${primary.toInt()} / ${secondary.toInt()}';
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : MedicalReferences.getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MedicalReferences.getStatusColor(status).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type == 'blood_pressure'
                                      ? AppStrings.get('blood_pressure', lang)
                                      : (type == 'heart_rate'
                                          ? AppStrings.get('heart_rate', lang)
                                          : type),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      displayValue,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: MedicalReferences.getStatusColor(status),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: MedicalReferences.getStatusColor(status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                MedicalReferences.getStatusLabel(status, isArabic),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text(err.toString()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. Main Services Grid: 5 Core Services
          Text(
            AppStrings.get('services_title', lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _buildServiceCard(
                title: AppStrings.get('service_meds', lang),
                subtitle: AppStrings.get('service_meds_desc', lang),
                icon: Icons.medication_rounded,
                color: AppColors.primaryBlue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationsScreen())),
                isDark: isDark,
              ),
              _buildServiceCard(
                title: AppStrings.get('service_labs', lang),
                subtitle: AppStrings.get('service_labs_desc', lang),
                icon: Icons.biotech_rounded,
                color: AppColors.secondaryTeal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestsScreen())),
                isDark: isDark,
              ),
              _buildServiceCard(
                title: AppStrings.get('service_diseases', lang),
                subtitle: AppStrings.get('service_diseases_desc', lang),
                icon: Icons.health_and_safety_rounded,
                color: const Color(0xFF8A3FFC),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseasesScreen())),
                isDark: isDark,
              ),
              _buildServiceCard(
                title: AppStrings.get('service_calc', lang),
                subtitle: AppStrings.get('service_calc_desc', lang),
                icon: Icons.calculate_rounded,
                color: const Color(0xFF0072C3),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorsScreen())),
                isDark: isDark,
              ),
              _buildServiceCard(
                title: AppStrings.get('service_reminders', lang),
                subtitle: AppStrings.get('service_reminders_desc', lang),
                icon: Icons.alarm_on_rounded,
                color: const Color(0xFF1192E8),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Persistent Disclaimer at the bottom of the dashboard
          MedicalDisclaimerCard(isArabic: isArabic),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
