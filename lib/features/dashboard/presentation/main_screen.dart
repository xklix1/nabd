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
  String _selectedSearchFilter = 'all'; // 'all', 'medication', 'lab_test', 'disease'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchQuery = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final recentVitalsAsync = ref.watch(recentVitalLogsProvider);
    final activeRemindersCountAsync = ref.watch(activeRemindersCountProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Top Bar: App Identity + User Greeting + Quick Language Switch + Notifications
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.secondaryTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isArabic ? 'تطبيق نبض' : 'Nabd App',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isArabic ? 'آمن ومحمي' : 'Secure',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isArabic ? 'دليلك الطبي الكامل بدون إنترنت' : 'Complete Offline Medical Reference',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick Language Switcher Button
                  OutlinedButton(
                    onPressed: () {
                      ref.read(languageProvider.notifier).toggleLanguage();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(40, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isArabic ? 'English' : 'عربي',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Reminders Notification Bell with Live Counter Badge
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 26),
                        activeRemindersCountAsync.maybeWhen(
                          data: (count) => count > 0
                              ? Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
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

              // 2. Premium Hero Gradient Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F62FE), Color(0xFF0072C3), Color(0xFF00A896)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F62FE).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'مرحباً بك في نبض' : 'Welcome to Nabd',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic
                                    ? 'قاعدة بيانات دوائية وطبية شاملة، موثقة ومعتمدة بالكامل دون الحاجة لأي اتصال بالإنترنت.'
                                    : 'Comprehensive medical encyclopedia with 100 medications, lab tests, and health tools 100% offline.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Quick stats badges inside Hero
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildHeroBadge(
                          icon: Icons.medication_rounded,
                          label: isArabic ? '150+ دواء مصري' : '150+ Egyptian Meds',
                        ),
                        _buildHeroBadge(
                          icon: Icons.biotech_rounded,
                          label: isArabic ? '60 فحص مخبري' : '60 Lab Tests',
                        ),
                        _buildHeroBadge(
                          icon: Icons.offline_bolt_rounded,
                          label: isArabic ? 'يعمل بلا إنترنت' : '100% Offline',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Modern Real-Time Search Box
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.get('search_hint', lang),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
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
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Quick Filter Chips for Search
              if (searchQuery.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: isArabic ? 'الكل' : 'All',
                        value: 'all',
                        isSelected: _selectedSearchFilter == 'all',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: isArabic ? 'الأدوية' : 'Medications',
                        value: 'medication',
                        isSelected: _selectedSearchFilter == 'medication',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: isArabic ? 'التحاليل' : 'Labs',
                        value: 'lab_test',
                        isSelected: _selectedSearchFilter == 'lab_test',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: isArabic ? 'الأمراض' : 'Diseases',
                        value: 'disease',
                        isSelected: _selectedSearchFilter == 'disease',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Real-time Search Results overlay
                searchResultsAsync.when(
                  data: (rawResults) {
                    final results = _selectedSearchFilter == 'all'
                        ? rawResults
                        : rawResults.where((r) => r['type'] == _selectedSearchFilter).toList();

                    if (results.isEmpty) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              isArabic ? 'لا توجد نتائج مطابقة لبحثك' : 'No matching results found',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              isArabic
                                  ? 'نتائج البحث الفوري (${results.length}):'
                                  : 'Instant Results (${results.length}):',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const Divider(height: 1),
                          ...results.map((item) {
                            final type = item['type'];
                            final name = isArabic ? item['name_ar'] : item['name_en'];
                            IconData icon;
                            Color chipColor;
                            String typeLabel;

                            if (type == 'medication') {
                              icon = Icons.medication_rounded;
                              chipColor = AppColors.primaryBlue;
                              typeLabel = isArabic ? 'دواء' : 'Med';
                            } else if (type == 'lab_test') {
                              icon = Icons.biotech_rounded;
                              chipColor = AppColors.secondaryTeal;
                              typeLabel = isArabic ? 'تحليل' : 'Lab';
                            } else {
                              icon = Icons.health_and_safety_outlined;
                              chipColor = const Color(0xFF8A3FFC);
                              typeLabel = isArabic ? 'مرض' : 'Disease';
                            }

                            final activeIngredient = isArabic
                                ? item['active_ingredient_ar']
                                : item['active_ingredient_en'];

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: chipColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: chipColor, size: 22),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
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
                                label: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: chipColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: chipColor.withOpacity(0.12),
                                side: BorderSide.none,
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
              ],

              const SizedBox(height: 18),

              // 4. Dedicated Medication Reminders Interactive Banner (Full Width)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1192E8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.alarm_on_rounded,
                          color: Color(0xFF1192E8),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isArabic ? 'جدول وتنبيهات الأدوية' : 'Medication Schedule & Alarms',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                activeRemindersCountAsync.maybeWhen(
                                  data: (count) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: count > 0 ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isArabic ? '$count نشط' : '$count active',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: count > 0 ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  orElse: () => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isArabic
                                  ? 'تنبيهات دقيقة بدون إنترنت لحفظ مواعيد الجرعات بانتظام'
                                  : 'Reliable offline dosage notifications & time-tracking',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              isArabic ? 'إضافة' : 'Add',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Primary Core Services (Balanced 2x2 Grid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get('services_title', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isArabic ? '4 أقسام رئيسية' : '4 Core Sections',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.4 : 1.12,
                children: [
                  _buildServiceCard(
                    title: isArabic ? 'دليل الأدوية' : 'Medications',
                    badge: isArabic ? '150+ دواء' : '150+ Meds',
                    subtitle: isArabic ? 'الجرعات، التفاعلات، والمحاذير' : 'Dosages, interactions & warnings',
                    icon: Icons.medication_rounded,
                    color: AppColors.primaryBlue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationsScreen())),
                    isDark: isDark,
                  ),
                  _buildServiceCard(
                    title: isArabic ? 'دليل التحاليل' : 'Lab Tests',
                    badge: isArabic ? '60 فحصاً' : '60 Tests',
                    subtitle: isArabic ? 'المعدلات الطبيعية والتفسير' : 'Normal ranges & explanations',
                    icon: Icons.biotech_rounded,
                    color: AppColors.secondaryTeal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestsScreen())),
                    isDark: isDark,
                  ),
                  _buildServiceCard(
                    title: isArabic ? 'الموسوعة المرضية' : 'Diseases',
                    badge: isArabic ? 'موثق' : 'Verified',
                    subtitle: isArabic ? 'الأعراض، الأسباب، والوقاية' : 'Symptoms, causes & prevention',
                    icon: Icons.health_and_safety_rounded,
                    color: const Color(0xFF8A3FFC),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseasesScreen())),
                    isDark: isDark,
                  ),
                  _buildServiceCard(
                    title: isArabic ? 'الحاسبة الصحية' : 'Health Calc',
                    badge: isArabic ? '3 أدوات' : '3 Tools',
                    subtitle: isArabic ? 'كتلة الجسم، السعرات، والماء' : 'BMI, calories & hydration',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFF0072C3),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorsScreen())),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Vital Signs Tracking Card
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.monitor_heart_rounded, color: Colors.redAccent, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppStrings.get('vitals_card_title', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                              width: double.infinity,
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
                            padding: const EdgeInsets.all(14),
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
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          displayValue,
                                          style: TextStyle(
                                            fontSize: 24,
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

              // 7. Medical Disclaimer Card
              MedicalDisclaimerCard(isArabic: isArabic),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedSearchFilter = value;
        });
      },
      selectedColor: AppColors.primaryBlue.withOpacity(0.18),
      checkmarkColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryBlue : null,
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String badge,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.25,
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
