import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final db = ref.watch(databaseHelperProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('service_meds', lang),
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
                  hintText: isArabic ? 'ابحث في دليل الأدوية...' : 'Search medications...',
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
                      final category = isArabic ? item['category_ar'] : item['category_en'];
                      final indications = isArabic ? item['indications_ar'] : item['indications_en'];
                      final sideEffects = isArabic ? item['side_effects_ar'] : item['side_effects_en'];
                      final contraindications = isArabic ? item['contraindications_ar'] : item['contraindications_en'];
                      final dosage = isArabic ? item['standard_dosage_ar'] : item['standard_dosage_en'];
                      final source = item['official_source'];

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
                          subtitle: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(16.0),
                          children: [
                            _buildInfoSection(
                              title: isArabic ? 'دواعي الاستعمال:' : 'Indications:',
                              content: indications,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoSection(
                              title: isArabic ? 'الآثار الجانبية الشائعة:' : 'Common Side Effects:',
                              content: sideEffects,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoSection(
                              title: isArabic ? 'موانع الاستعمال:' : 'Contraindications:',
                              content: contraindications,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoSection(
                              title: isArabic ? 'الجرعة الإرشادية (وفق النشرة الرسمية):' : 'Standard Dosage (Per Leaflet):',
                              content: dosage,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isArabic ? 'المصدر المعتمد: $source' : 'Official Source: $source',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
