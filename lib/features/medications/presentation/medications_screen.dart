import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/medical_references.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/medical_disclaimer_card.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          isArabic ? 'دليل الأدوية الشامل (150+ دواء)' : 'Comprehensive Medications (150+ Meds)',
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
                  hintText: isArabic
                      ? 'ابحث بالاسم التجاري أو المادة الفعالة (عربي / English)...'
                      : 'Search by brand or active ingredient (Arabic / English)...',
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
                future: db.getMedications(filter: _filter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        isArabic ? 'لا توجد أدوية مطابقة لبحثك' : 'No medications found',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: list.length + 1, // Last item is persistent Medical Disclaimer
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
                      final subName = isArabic ? item['name_en'] : item['name_ar'];
                      final activeIngredient = isArabic
                          ? (item['active_ingredient_ar'] ?? item['scientific_name'])
                          : (item['active_ingredient_en'] ?? item['scientific_name']);
                      final category = isArabic ? item['category_ar'] : item['category_en'];
                      final indications = isArabic ? item['indications_ar'] : item['indications_en'];
                      final sideEffects = isArabic ? item['side_effects_ar'] : item['side_effects_en'];
                      final contraindications = isArabic ? item['contraindications_ar'] : item['contraindications_en'];
                      final dosage = isArabic ? item['standard_dosage_ar'] : item['standard_dosage_en'];
                      final source = item['official_source'];
                      final sourceUrl = item['official_url'] as String?;

                      return Card(
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLightBlue,
                            child: const Icon(Icons.medication_rounded, color: AppColors.primaryBlue),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.all(16.0),
                          children: [
                            // 1. Prominent Active Ingredient Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCardBg
                                    : AppColors.primaryLightBlue.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withOpacity(0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.biotech_rounded,
                                    size: 22,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic ? 'المادة الفعالة (Active Ingredient):' : 'Active Ingredient:',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          activeIngredient,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. Indications
                            _buildInfoSection(
                              title: isArabic ? 'دواعي الاستعمال:' : 'Indications:',
                              content: indications,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),

                            // 3. Side Effects
                            _buildInfoSection(
                              title: isArabic ? 'الآثار الجانبية الشائعة:' : 'Common Side Effects:',
                              content: sideEffects,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),

                            // 4. Contraindications
                            _buildInfoSection(
                              title: isArabic ? 'موانع الاستعمال والحذر:' : 'Contraindications & Precautions:',
                              content: contraindications,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),

                            // 5. Dosage
                            _buildInfoSection(
                              title: isArabic ? 'الجرعة الإرشادية (وفق النشرة الرسمية):' : 'Standard Dosage (Per Leaflet):',
                              content: dosage,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),

                            // 6. Interactive Official Source Link
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => MedicalReferences.launchSourceUrl(sourceUrl),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.accentTeal.withOpacity(0.35)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.accentTeal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? 'المصدر المعتمد: $source (اضغط لفتح الصفحة الرسمية)'
                                            : 'Official Source: $source (Tap to view official page)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accentTeal,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
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

  Widget _buildInfoSection({required String title, required String content, required bool isDark}) {
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
