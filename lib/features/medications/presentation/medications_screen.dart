import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/medical_references.dart';
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'دليل الأدوية المصرية الشامل' : 'Egyptian Medications Catalog',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              isArabic
                  ? 'بحث فوري في الأسماء التجارية والمواد الفعالة والبدائل'
                  : 'Instant offline index with active ingredients & substitutes',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Search Header with soft shadow
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filter = val),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'ابحث بالاسم التجاري أو المادة الفعالة (أوجمنتين، بنادول، كونكور...)'
                        : 'Search by brand or active ingredient (Augmentin, Concor...)...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filter = '');
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
            ),

            // Content List
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 56,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isArabic ? 'لا توجد أدوية مطابقة لبحثك' : 'No medications found',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
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
                          padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                          child: MedicalDisclaimerCard(isArabic: isArabic),
                        );
                      }

                      final item = list[index];
                      return _MedicationClinicalCard(
                        item: item,
                        isArabic: isArabic,
                        isDark: isDark,
                        onOpenSubstitutes: () => _showSubstitutesSheet(context, item, isArabic, isDark),
                        onOpenDetails: () => _showDetailsSheet(context, item, isArabic, isDark),
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

  void _showSubstitutesSheet(BuildContext context, Map<String, dynamic> item, bool isArabic, bool isDark) {
    final db = ref.read(databaseHelperProvider);
    final medId = item['id'] as int;
    final activeEn = item['active_ingredient_en']?.toString() ?? '';
    final activeAr = item['active_ingredient_ar']?.toString() ?? '';
    final categoryEn = item['category_en']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet Handle
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sync_alt_rounded, color: AppColors.secondaryTeal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'البدائل والمثائل المتاحة' : 'Available Substitutes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            isArabic
                                ? 'بدائل لدواء: ${item['name_ar']}'
                                : 'Equivalents for: ${item['name_en']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Active Ingredient Highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: isDark ? const Color(0xFF0F172A) : AppColors.primaryLightBlue.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.biotech_rounded, size: 18, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'المادة الفعالة: ${item['active_ingredient_ar'] ?? item['scientific_name']}'
                            : 'Active Molecule: ${item['active_ingredient_en'] ?? item['scientific_name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),

              // Substitutes List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: db.getMedicationSubstitutes(
                    medicationId: medId,
                    activeIngredientEn: activeEn,
                    activeIngredientAr: activeAr,
                    categoryEn: categoryEn,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final subs = snapshot.data ?? [];
                    if (subs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            isArabic
                                ? 'لا توجد بدائل مسجلة حالياً تشارك نفس المادة الفعالة أو العائلة'
                                : 'No direct substitutes recorded for this molecule.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final sub = subs[i];
                        final subName = isArabic ? sub['name_ar'] : sub['name_en'];
                        final subForm = isArabic ? sub['dosage_form_ar'] : sub['dosage_form_en'];
                        final subCompany = sub['company'] ?? '';

                        final isSameMolecule = sub['active_ingredient_en'] == activeEn;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSameMolecule
                                  ? AppColors.secondaryTeal.withOpacity(0.4)
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSameMolecule
                                      ? AppColors.secondaryTeal.withOpacity(0.15)
                                      : AppColors.primaryBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: isSameMolecule ? AppColors.secondaryTeal : AppColors.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSameMolecule
                                                ? AppColors.statusNormalBg
                                                : AppColors.primaryLightBlue,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isSameMolecule
                                                ? (isArabic ? 'مثيل متطابق' : 'Identical')
                                                : (isArabic ? 'بديل علاجي' : 'Alternative'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSameMolecule
                                                  ? AppColors.statusNormal
                                                  : AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$subForm • $subCompany',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
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
        );
      },
    );
  }

  void _showDetailsSheet(BuildContext context, Map<String, dynamic> item, bool isArabic, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final name = isArabic ? item['name_ar'] : item['name_en'];
        final subName = isArabic ? item['name_en'] : item['name_ar'];
        final active = isArabic ? item['active_ingredient_ar'] : item['active_ingredient_en'];
        final category = isArabic ? item['category_ar'] : item['category_en'];
        final form = isArabic ? item['dosage_form_ar'] : item['dosage_form_en'];
        final company = item['company'] ?? '';
        final indications = isArabic ? item['indications_ar'] : item['indications_en'];
        final dosage = isArabic ? item['standard_dosage_ar'] : item['standard_dosage_en'];
        final sideEffects = isArabic ? item['side_effects_ar'] : item['side_effects_en'];
        final contra = isArabic ? item['contraindications_ar'] : item['contraindications_en'];
        final source = item['official_source'] ?? '';
        final url = item['official_url']?.toString();
        final priceRaw = item['price_egp'];
        final double? price = priceRaw != null ? (priceRaw as num).toDouble() : null;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.medication_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            subName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _chip(category, AppColors.primaryBlue),
                              if (price != null && price > 0)
                                _chip(
                                  isArabic
                                      ? 'السعر الرسمي: ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} ج.م'
                                      : 'Price: ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} EGP',
                                  const Color(0xFF10B981),
                                ),
                              if (form.isNotEmpty) _chip(form, AppColors.secondaryTeal),
                              if (company.isNotEmpty) _chip(company, Colors.indigo),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),

              // Details Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    _section(
                      icon: Icons.biotech_rounded,
                      color: AppColors.primaryBlue,
                      title: isArabic ? 'المادة الفعالة والتركيز' : 'Active Ingredient',
                      content: active,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _section(
                      icon: Icons.assignment_outlined,
                      color: AppColors.secondaryTeal,
                      title: isArabic ? 'دواعي الاستعمال' : 'Indications',
                      content: indications,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _section(
                      icon: Icons.schedule_rounded,
                      color: Colors.teal,
                      title: isArabic ? 'الجرعات الإرشادية المعتادة' : 'Standard Dosage',
                      content: dosage,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _section(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.statusWarning,
                      title: isArabic ? 'الآثار الجانبية الشائعة' : 'Side Effects',
                      content: sideEffects,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _section(
                      icon: Icons.block_rounded,
                      color: AppColors.statusAlert,
                      title: isArabic ? 'موانع الاستعمال والتحذيرات' : 'Contraindications',
                      content: contra,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Official Source & Verification
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic ? 'المصدر المعتمد: $source' : 'Official Reference: $source',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          if (url != null && url.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              onPressed: () async {
                                final uri = Uri.tryParse(url);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationClinicalCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onOpenSubstitutes;
  final VoidCallback onOpenDetails;

  const _MedicationClinicalCard({
    required this.item,
    required this.isArabic,
    required this.isDark,
    required this.onOpenSubstitutes,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final name = isArabic ? item['name_ar'] : item['name_en'];
    final subName = isArabic ? item['name_en'] : item['name_ar'];
    final active = isArabic
        ? (item['active_ingredient_ar'] ?? item['scientific_name'])
        : (item['active_ingredient_en'] ?? item['scientific_name']);
    final form = isArabic ? (item['dosage_form_ar'] ?? '') : (item['dosage_form_en'] ?? '');
    final company = item['company'] ?? '';
    final category = isArabic ? item['category_ar'] : item['category_en'];
    final priceRaw = item['price_egp'];
    final double? price = priceRaw != null ? (priceRaw as num).toDouble() : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Names + Category
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A56DB), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Text(
                        subName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Active Ingredient Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : AppColors.primaryLightBlue.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.biotech_rounded, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      active,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Pills info: Price, Form, Company, Category
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (price != null && price > 0)
                  _badge(
                    icon: Icons.payments_outlined,
                    label: isArabic
                        ? '${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} ج.م'
                        : '${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} EGP',
                    isDark: isDark,
                    color: const Color(0xFF10B981),
                  ),
                if (form.isNotEmpty)
                  _badge(icon: Icons.grain_rounded, label: form, isDark: isDark),
                if (company.isNotEmpty)
                  _badge(icon: Icons.business_rounded, label: company, isDark: isDark),
                _badge(icon: Icons.folder_open_rounded, label: category, isDark: isDark),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                // 1. Substitutes button (Highlight)
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    onPressed: onOpenSubstitutes,
                    icon: const Icon(Icons.sync_alt_rounded, size: 16, color: AppColors.secondaryTeal),
                    label: Text(
                      isArabic ? 'البدائل والمثائل' : 'Substitutes',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: AppColors.secondaryTeal.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Clinical details button
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: Text(
                      isArabic ? 'التفاصيل والجرعات' : 'Clinical Info',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required IconData icon, required String label, required bool isDark, Color? color}) {
    final textColor = color ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    final bgColor = color != null
        ? color.withOpacity(0.12)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
