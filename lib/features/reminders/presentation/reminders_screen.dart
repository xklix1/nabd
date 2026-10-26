import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  int _intervalHours = 8;
  bool _isOneTime = false;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
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
                          : 'Tap Add to schedule recurring or one-time dose alerts',
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
                final firstTime = item['first_dose_time'];
                final interval = item['interval_hours'];
                final isOneTime = (item['is_one_time'] ?? 0) == 1;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isOneTime
                          ? Colors.orange.withOpacity(0.15)
                          : AppColors.primaryLightBlue,
                      child: Icon(
                        isOneTime ? Icons.event_available_rounded : Icons.alarm_rounded,
                        color: isOneTime ? Colors.deepOrange : AppColors.primaryBlue,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (isOneTime)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade400, width: 0.8),
                            ),
                            child: Text(
                              isArabic ? 'مرة واحدة' : 'One-Time',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        isOneTime
                            ? (isArabic
                                ? '$dose • موعد الجرعة: $firstTime'
                                : '$dose • Dose time: $firstTime')
                            : (isArabic
                                ? '$dose • كل $interval ساعات • يبدأ: $firstTime'
                                : '$dose • Every $interval hrs • Starts: $firstTime'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    _isOneTime = false;
    _intervalHours = 8;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = DateFormat('yyyy/MM/dd', isArabic ? 'ar' : 'en').format(_selectedDate);
            final timeStr = _selectedTime.format(context);

            return AlertDialog(
              title: Text(isArabic ? 'جدولة تذكير دوائي' : 'Schedule Medication Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اسم الدواء' : 'Medication Name',
                        hintText: isArabic ? 'مثال: أوميبرازول أو بنادول' : 'e.g. Omeprazole',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _doseController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'وصف الجرعة (اختياري)' : 'Dose (Optional)',
                        hintText: isArabic ? 'مثال: قرص واحد 20 مجم' : 'e.g. 1 tablet 20mg',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminder Type Selector (One-Time vs Recurring)
                    Text(
                      isArabic ? 'نوع الجدولة:' : 'Schedule Type:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => _isOneTime = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isOneTime
                                    ? AppColors.primaryBlue
                                    : (isDark ? AppColors.darkCardBg : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  isArabic ? 'تكرار دوري' : 'Recurring',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: !_isOneTime ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => _isOneTime = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isOneTime
                                    ? Colors.deepOrange
                                    : (isDark ? AppColors.darkCardBg : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  isArabic ? 'مرة واحدة فقط' : 'One-Time Dose',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _isOneTime ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // If One-Time: Choose Exact Date & Time
                    if (_isOneTime) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_rounded, color: Colors.deepOrange),
                        title: Text(isArabic ? 'تاريخ ويوم الجرعة' : 'Dose Date'),
                        subtitle: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit_calendar_rounded),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() => _selectedDate = pickedDate);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded, color: Colors.deepOrange),
                        title: Text(isArabic ? 'ساعة ووقت الجرعة' : 'Dose Exact Time'),
                        subtitle: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit_rounded),
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (pickedTime != null) {
                            setDialogState(() => _selectedTime = pickedTime);
                          }
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? 'سيتم إرسال التنبيه في اليوم والساعة المحددة لمرة واحدة فقط.'
                                    : 'Alert will trigger exactly once on the specified date & time.',
                                style: const TextStyle(fontSize: 11, color: Colors.deepOrange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Recurring: First Dose Time + Interval
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded, color: AppColors.primaryBlue),
                        title: Text(isArabic ? 'موعد الجرعة الأولى' : 'First Dose Time'),
                        subtitle: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit_rounded),
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (pickedTime != null) {
                            setDialogState(() => _selectedTime = pickedTime);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
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
                    final baseDate = _isOneTime ? _selectedDate : now;
                    final targetDateTime = DateTime(
                      baseDate.year,
                      baseDate.month,
                      baseDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    // Formatted display string
                    final displayTimeStr = _isOneTime
                        ? '${DateFormat('yyyy/MM/dd', isArabic ? 'ar' : 'en').format(baseDate)} - ${_selectedTime.format(context)}'
                        : _selectedTime.format(context);

                    final db = ref.read(databaseHelperProvider);
                    final id = await db.insertReminder(
                      medicationName: name,
                      doseDescription: dose,
                      firstDoseTime: displayTimeStr,
                      scheduledDateTime: targetDateTime.toIso8601String(),
                      intervalHours: _isOneTime ? 0 : _intervalHours,
                      isOneTime: _isOneTime,
                    );

                    // Schedule Offline Notification with lock screen privacy
                    final notificationService = ref.read(notificationServiceProvider);
                    await notificationService.scheduleMedicationReminder(
                      id: id,
                      medicationName: name,
                      firstDoseTime: targetDateTime,
                      intervalHours: _isOneTime ? 0 : _intervalHours,
                      isOneTime: _isOneTime,
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
