import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _intervalHours = 8;

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
          AppStrings.get('service_reminders', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
        label: Text(
          isArabic ? 'إضافة تذكير' : 'Add Reminder',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: db.getActiveReminders(),
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
                      Icons.alarm_off_rounded,
                      size: 64,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'لا توجد تذكيرات دوائية مجدولة' : 'No active reminders scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'اضغط على زر الإضافة لجدولة مواعيد أدويتك'
                          : 'Tap Add to schedule recurring dose alerts',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                final id = item['id'] as int;
                final name = item['medication_name'];
                final dose = item['dose_description'];
                final time = item['first_dose_time'];
                final interval = item['interval_hours'];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLightBlue,
                      child: const Icon(Icons.alarm_rounded, color: AppColors.primaryBlue),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      isArabic
                          ? '$dose • كل $interval ساعات • يبدأ: $time'
                          : '$dose • Every $interval hrs • Starts: $time',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        await db.deleteReminder(id);
                        final notifier = ref.read(notificationServiceProvider);
                        await notifier.cancelReminder(id);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isArabic ? 'جدولة تذكير دوائي جديد' : 'New Medication Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اسم الدواء' : 'Medication Name',
                        hintText: 'e.g. Paracetamol',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _doseController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'وصف الجرعة (اختياري)' : 'Dose (e.g. 1 Tablet)',
                        hintText: isArabic ? 'قرص واحد 500 مجم' : '1 tablet 500mg',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isArabic ? 'موعد الجرعة الأولى' : 'First Dose Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => _selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _intervalHours,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'التكرار الدوري' : 'Repeat Interval',
                      ),
                      items: [
                        DropdownMenuItem(value: 4, child: Text(isArabic ? 'كل 4 ساعات' : 'Every 4 hours')),
                        DropdownMenuItem(value: 6, child: Text(isArabic ? 'كل 6 ساعات' : 'Every 6 hours')),
                        DropdownMenuItem(value: 8, child: Text(isArabic ? 'كل 8 ساعات (3 مرات يومياً)' : 'Every 8 hours')),
                        DropdownMenuItem(value: 12, child: Text(isArabic ? 'كل 12 ساعة (مرتين يومياً)' : 'Every 12 hours')),
                        DropdownMenuItem(value: 24, child: Text(isArabic ? 'مرة واحدة يومياً (كل 24 ساعة)' : 'Once daily (24 hrs)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _intervalHours = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;

                    final dose = _doseController.text.trim().isEmpty
                        ? (isArabic ? 'جرعة مجدولة' : 'Scheduled dose')
                        : _doseController.text.trim();

                    final now = DateTime.now();
                    final firstDoseDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    final db = ref.read(databaseHelperProvider);
                    final id = await db.insertReminder(
                      medicationName: name,
                      doseDescription: dose,
                      firstDoseTime: _selectedTime.format(context),
                      intervalHours: _intervalHours,
                    );

                    // Schedule Offline Notification with lock screen privacy
                    final notificationService = ref.read(notificationServiceProvider);
                    await notificationService.scheduleMedicationReminder(
                      id: id,
                      medicationName: name,
                      firstDoseTime: firstDoseDateTime,
                      intervalHours: _intervalHours,
                      isArabic: isArabic,
                    );

                    _nameController.clear();
                    _doseController.clear();
                    if (mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                    }
                  },
                  child: Text(isArabic ? 'حفظ وجدولة' : 'Save & Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
