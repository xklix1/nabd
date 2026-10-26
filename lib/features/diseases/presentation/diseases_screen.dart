import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/medical_references.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/medical_disclaimer_card.dart';

class DiseasesScreen extends ConsumerStatefulWidget {
  const DiseasesScreen({super.key});

  @override
  ConsumerState<DiseasesScreen> createState() => _DiseasesScreenState();
}

class _DiseasesScreenState extends ConsumerState<DiseasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final db = ref.watch(databaseHelperProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('service_diseases', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filter = val),
                decoration: InputDecoration(
                  hintText: isArabic ? 'ابحث في الموسوعة المرضية...' : 'Search diseases...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: db.getDiseases(filter: _filter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        isArabic ? 'لا توجد نتائج مطابقة لبحثك' : 'No conditions found',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                          child: MedicalDisclaimerCard(isArabic: isArabic),
                        );
                      }

                      final item = list[index];
                      final name = isArabic ? item['name_ar'] : item['name_en'];
                      final overview = isArabic ? item['overview_ar'] : item['overview_en'];
                      final causes = isArabic ? item['causes_ar'] : item['causes_en'];
                      final symptoms = isArabic ? item['symptoms_ar'] : item['symptoms_en'];
                      final prevention = isArabic ? item['prevention_ar'] : item['prevention_en'];
                      final care = isArabic ? item['initial_care_ar'] : item['initial_care_en'];
                      final source = item['official_source'];

                      return Card(
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLightBlue,
                            child: const Icon(Icons.health_and_safety_outlined, color: AppColors.primaryBlue),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            overview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(16.0),
                          children: [
                            _buildSection(
                              title: isArabic ? 'نظرة عامة:' : 'Overview:',
                              content: overview,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildSection(
                              title: isArabic ? 'الأسباب وعوامل الخطورة:' : 'Causes & Risk Factors:',
                              content: causes,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildSection(
                              title: isArabic ? 'الأعراض والعلامات الشائعة:' : 'Common Symptoms:',
                              content: symptoms,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildSection(
                              title: isArabic ? 'طرق الوقاية وأنماط الحياة:' : 'Prevention & Lifestyle:',
                              content: prevention,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildSection(
                              title: isArabic ? 'إرشادات الرعاية الأولية:' : 'Initial Care Guidelines:',
                              content: care,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => MedicalReferences.launchSourceUrl(item['official_url'] ?? MedicalReferences.urlWHO),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 15, color: AppColors.accentTeal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? 'المصدر المعتمد: $source (اضغط لفتح المصدر الرسمي)'
                                            : 'Official Source: $source (Tap to view official page)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accentTeal,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.accentTeal),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
