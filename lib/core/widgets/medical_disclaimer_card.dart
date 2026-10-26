import 'package:flutter/material.dart';
import '../constants/medical_references.dart';
import '../theme/app_colors.dart';

/// Permanent Medical Disclaimer Card.
/// Sourced strictly from WHO & Egyptian EDA/MOHP compliance standards.
/// Purely textual attribution without unauthorized official logos.
class MedicalDisclaimerCard extends StatelessWidget {
  final bool isArabic;
  final String? specificSource;

  const MedicalDisclaimerCard({
    super.key,
    required this.isArabic,
    this.specificSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.darkSurfaceCard
        : AppColors.primaryLightBlue;
    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.primaryBlue.withOpacity(0.25);
    final iconColor = AppColors.primaryBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'إخلاء مسؤولية طبي هام' : 'Important Medical Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? MedicalReferences.disclaimerAr : MedicalReferences.disclaimerEn,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          if (specificSource != null) ...[
            const SizedBox(height: 8),
            Divider(color: borderColor, thickness: 0.5),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                if (specificSource!.contains('EDA') || specificSource!.contains('هيئة الدواء')) {
                  MedicalReferences.launchSourceUrl(MedicalReferences.urlEDA);
                } else if (specificSource!.contains('MOHP') || specificSource!.contains('وزارة الصحة')) {
                  MedicalReferences.launchSourceUrl(MedicalReferences.urlMOHP);
                } else {
                  MedicalReferences.launchSourceUrl(MedicalReferences.urlWHO);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.accentTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'المصدر المعتمد: $specificSource (انقر للمصدر الرسمي)'
                            : 'Official Source: $specificSource (Tap to view)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentTeal,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.accentTeal),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
