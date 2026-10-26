import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/medical_references.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/input_validators.dart';

class VitalSignsDialog extends ConsumerStatefulWidget {
  const VitalSignsDialog({super.key});

  @override
  ConsumerState<VitalSignsDialog> createState() => _VitalSignsDialogState();
}

class _VitalSignsDialogState extends ConsumerState<VitalSignsDialog> {
  String _selectedType = 'blood_pressure';
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';

    return AlertDialog(
      title: Text(isArabic ? 'تسجيل قراءة حيوية' : 'Log Vital Reading'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: [
                DropdownMenuItem(
                  value: 'blood_pressure',
                  child: Text(AppStrings.get('blood_pressure', lang)),
                ),
                DropdownMenuItem(
                  value: 'heart_rate',
                  child: Text(AppStrings.get('heart_rate', lang)),
                ),
                DropdownMenuItem(
                  value: 'glucose',
                  child: Text(AppStrings.get('glucose', lang)),
                ),
                DropdownMenuItem(
                  value: 'spo2',
                  child: Text(AppStrings.get('spo2', lang)),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedType == 'blood_pressure') ...[
              TextField(
                controller: _primaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الضغط الانقباضي (Systolic)' : 'Systolic',
                  hintText: 'e.g. 120',
                  suffixText: 'mmHg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secondaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الضغط الانبساطي (Diastolic)' : 'Diastolic',
                  hintText: 'e.g. 80',
                  suffixText: 'mmHg',
                ),
              ),
            ] else if (_selectedType == 'heart_rate') ...[
              TextField(
                controller: _primaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic ? 'معدل النبض (BPM)' : 'Heart Rate (BPM)',
                  hintText: 'e.g. 72',
                  suffixText: 'bpm',
                ),
              ),
            ] else if (_selectedType == 'glucose') ...[
              TextField(
                controller: _primaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isArabic ? 'جلوكوز الدم الصائم (mg/dL)' : 'Fasting Glucose (mg/dL)',
                  hintText: 'e.g. 95',
                  suffixText: 'mg/dL',
                ),
              ),
            ] else if (_selectedType == 'spo2') ...[
              TextField(
                controller: _primaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic ? 'نسبة الأكسجين SpO2 (%)' : 'Oxygen Saturation (%)',
                  hintText: 'e.g. 98',
                  suffixText: '%',
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveReading,
          child: Text(isArabic ? 'حفظ القياس' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _saveReading() async {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';

    String? error;
    double primary = 0;
    double? secondary;
    String unit = '';
    HealthRangeStatus status = HealthRangeStatus.normal;

    if (_selectedType == 'blood_pressure') {
      error = InputValidators.validateBloodPressure(
        systolicStr: _primaryController.text,
        diastolicStr: _secondaryController.text,
        isArabic: isArabic,
      );
      if (error == null) {
        primary = double.parse(_primaryController.text.trim());
        secondary = double.parse(_secondaryController.text.trim());
        unit = 'mmHg';
        status = MedicalReferences.evaluateBloodPressure(primary.toInt(), secondary.toInt());
      }
    } else if (_selectedType == 'heart_rate') {
      error = InputValidators.validateHeartRate(_primaryController.text, isArabic);
      if (error == null) {
        primary = double.parse(_primaryController.text.trim());
        unit = 'bpm';
        status = MedicalReferences.evaluateHeartRate(primary.toInt());
      }
    } else if (_selectedType == 'glucose') {
      error = InputValidators.validateGlucose(_primaryController.text, isArabic);
      if (error == null) {
        primary = double.parse(_primaryController.text.trim());
        unit = 'mg/dL';
        status = MedicalReferences.evaluateGlucose(primary);
      }
    } else if (_selectedType == 'spo2') {
      error = InputValidators.validateSpO2(_primaryController.text, isArabic);
      if (error == null) {
        primary = double.parse(_primaryController.text.trim());
        unit = '%';
        status = MedicalReferences.evaluateSpO2(primary.toInt());
      }
    }

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    final db = ref.read(databaseHelperProvider);
    await db.insertVitalLog(
      type: _selectedType,
      primaryValue: primary,
      secondaryValue: secondary,
      unit: unit,
      statusEvaluated: status.name,
    );

    // Refresh provider
    ref.invalidate(recentVitalLogsProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
