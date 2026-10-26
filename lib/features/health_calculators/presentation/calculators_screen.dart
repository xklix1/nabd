import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/medical_references.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/input_validators.dart';
import '../../../core/widgets/medical_disclaimer_card.dart';

class CalculatorsScreen extends ConsumerStatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  ConsumerState<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends ConsumerState<CalculatorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // BMI Controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _calculatedBMI;
  String? _bmiCategory;
  String? _bmiError;

  // Water Intake Controllers
  final _waterWeightController = TextEditingController();
  double? _recommendedWaterLiters;
  String? _waterError;

  // Calorie Calculator Controllers
  final _calWeightController = TextEditingController();
  final _calHeightController = TextEditingController();
  final _calAgeController = TextEditingController();
  bool _isMale = true;
  double _activityMultiplier = 1.2; // Sedentary
  double? _dailyCalories;
  String? _calError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isArabic = lang == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('service_calc', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          indicatorColor: AppColors.primaryBlue,
          tabs: [
            Tab(text: isArabic ? 'كتلة الجسم (BMI)' : 'BMI Calc'),
            Tab(text: isArabic ? 'الاحتياج المائي' : 'Water Intake'),
            Tab(text: isArabic ? 'السعرات اليومية' : 'Calorie Needs'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: BMI Calculator
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isArabic ? 'حاسبة مؤشر كتلة الجسم (BMI)' : 'Body Mass Index (BMI)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'مؤشر استرشادي عام لتقييم تناسب الوزن مع الطول.'
                        : 'A general wellness indicator comparing weight relative to height.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الطول (سم)' : 'Height (cm)',
                      hintText: 'e.g. 175',
                      prefixIcon: const Icon(Icons.height_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
                      hintText: 'e.g. 70',
                      prefixIcon: const Icon(Icons.fitness_center_rounded),
                    ),
                  ),
                  if (_bmiError != null) ...[
                    const SizedBox(height: 8),
                    Text(_bmiError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _computeBMI,
                    child: Text(isArabic ? 'احسب المؤشر' : 'Calculate BMI'),
                  ),
                  if (_calculatedBMI != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.primaryLightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _calculatedBMI!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bmiCategory ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  MedicalDisclaimerCard(
                    isArabic: isArabic,
                    specificSource: MedicalReferences.sourceWHO,
                  ),
                ],
              ),
            ),

            // Tab 2: Daily Water Intake
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isArabic ? 'حاسبة الاحتياج اليومي من الماء' : 'Daily Water Requirement',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'تقدير عام لكمية السوائل اليومية الموصى بها للبالغين الأصحاء (~ 35 مل/كجم).'
                        : 'General estimation of daily fluid intake for healthy adults (~ 35 ml/kg).',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _waterWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
                      hintText: 'e.g. 70',
                      prefixIcon: const Icon(Icons.water_drop_outlined),
                    ),
                  ),
                  if (_waterError != null) ...[
                    const SizedBox(height: 8),
                    Text(_waterError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _computeWater,
                    child: Text(isArabic ? 'احسب الاحتياج' : 'Calculate Water Intake'),
                  ),
                  if (_recommendedWaterLiters != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.secondaryLightTeal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondaryTeal.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_recommendedWaterLiters!.toStringAsFixed(2)} ${isArabic ? "لتر / يوم" : "Liters / day"}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'أي ما يقارب ${( _recommendedWaterLiters! * 4).round()} أكواب متوسطة يومياً'
                                : 'Approximately ${( _recommendedWaterLiters! * 4).round()} standard glasses daily',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  MedicalDisclaimerCard(isArabic: isArabic),
                ],
              ),
            ),

            // Tab 3: Calorie Needs (General Wellness)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isArabic ? 'تقدير الاحتياج اليومي من السعرات' : 'Estimated Calorie Needs',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'مبني على معادلة ميفلين-سانت جور الإرشادية للطاقة الأساسية.'
                        : 'Based on the general Mifflin-St Jeor equation for basal metabolic guidance.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(isArabic ? 'ذكر' : 'Male'),
                          value: true,
                          groupValue: _isMale,
                          onChanged: (val) => setState(() => _isMale = val ?? true),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(isArabic ? 'أنثى' : 'Female'),
                          value: false,
                          groupValue: _isMale,
                          onChanged: (val) => setState(() => _isMale = val ?? false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _calAgeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'العمر (سنة)' : 'Age (years)',
                      hintText: 'e.g. 30',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _calHeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الطول (سم)' : 'Height (cm)',
                      hintText: 'e.g. 175',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _calWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
                      hintText: 'e.g. 70',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    value: _activityMultiplier,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'مستوى النشاط اليومي' : 'Activity Level',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 1.2,
                        child: Text(isArabic ? 'خامل (قليل أو بدون رياضة)' : 'Sedentary (little or no exercise)'),
                      ),
                      DropdownMenuItem(
                        value: 1.375,
                        child: Text(isArabic ? 'نشاط خفيف (1-3 أيام أسبوعياً)' : 'Lightly active (1-3 days/week)'),
                      ),
                      DropdownMenuItem(
                        value: 1.55,
                        child: Text(isArabic ? 'نشاط متوسط (3-5 أيام أسبوعياً)' : 'Moderately active (3-5 days/week)'),
                      ),
                      DropdownMenuItem(
                        value: 1.725,
                        child: Text(isArabic ? 'نشاط مكثف (6-7 أيام أسبوعياً)' : 'Very active (6-7 days/week)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _activityMultiplier = val);
                    },
                  ),
                  if (_calError != null) ...[
                    const SizedBox(height: 8),
                    Text(_calError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _computeCalories,
                    child: Text(isArabic ? 'احسب السعرات' : 'Calculate Calories'),
                  ),
                  if (_dailyCalories != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.primaryLightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_dailyCalories!.round()} ${isArabic ? "سعرة حرارية / يوم" : "kcal / day"}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'للحفاظ على الوزن الحالي بنشاط معتدل'
                                : 'Estimated maintenance energy intake',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  MedicalDisclaimerCard(isArabic: isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _computeBMI() {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';

    final hErr = InputValidators.validateHeight(_heightController.text, isArabic);
    final wErr = InputValidators.validateWeight(_weightController.text, isArabic);

    if (hErr != null || wErr != null) {
      setState(() => _bmiError = hErr ?? wErr);
      return;
    }

    final hMeter = double.parse(_heightController.text.trim()) / 100.0;
    final wKg = double.parse(_weightController.text.trim());
    final bmi = wKg / (hMeter * hMeter);

    setState(() {
      _bmiError = null;
      _calculatedBMI = bmi;
      _bmiCategory = MedicalReferences.interpretBMI(bmi, isArabic);
    });
  }

  void _computeWater() {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';

    final wErr = InputValidators.validateWeight(_waterWeightController.text, isArabic);
    if (wErr != null) {
      setState(() => _waterError = wErr);
      return;
    }

    final wKg = double.parse(_waterWeightController.text.trim());
    // 35 ml per kg
    final liters = (wKg * 35.0) / 1000.0;

    setState(() {
      _waterError = null;
      _recommendedWaterLiters = liters;
    });
  }

  void _computeCalories() {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';

    final hErr = InputValidators.validateHeight(_calHeightController.text, isArabic);
    final wErr = InputValidators.validateWeight(_calWeightController.text, isArabic);
    final ageStr = _calAgeController.text.trim();
    final age = int.tryParse(ageStr);

    if (hErr != null || wErr != null || age == null || age < 1 || age > 120) {
      setState(() {
        _calError = hErr ?? wErr ?? (isArabic ? 'يرجى إدخال عمر صحيح بين 1 و 120' : 'Enter valid age between 1 and 120');
      });
      return;
    }

    final weight = double.parse(_calWeightController.text.trim());
    final height = double.parse(_calHeightController.text.trim());

    // Mifflin-St Jeor formula
    // Men: (10 x weight) + (6.25 x height) - (5 x age) + 5
    // Women: (10 x weight) + (6.25 x height) - (5 x age) - 161
    double bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age);
    if (_isMale) {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    setState(() {
      _calError = null;
      _dailyCalories = bmr * _activityMultiplier;
    });
  }
}
