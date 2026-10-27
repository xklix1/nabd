import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'medication_alarm_dialog.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  int _intervalHours = 8;
  bool _isOneTime = false;
  late Future<List<Map<String, dynamic>>> _remindersFuture;

  @override
  void initState() {
    super.initState();
    _remindersFuture = ref.read(databaseHelperProvider).getActiveReminders();
  }

  void _reloadReminders() {
    setState(() {
      _remindersFuture = ref.read(databaseHelperProvider).getActiveReminders();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _triggerLiveAlarmTest({
    required BuildContext context,
    required String medicationName,
    required String doseDescription,
    required bool isArabic,
  }) async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.triggerImmediateAlarm(
      medicationName: medicationName,
      doseDescription: doseDescription,
      isArabic: isArabic,
    );

    if (!mounted) return;
    MedicationAlarmDialog.show(
      context: context,
      medicationName: medicationName,
      doseDescription: doseDescription,
      isArabic: isArabic,
      onTaken: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? '✅ تم تأكيد تناول الدواء ($medicationName) بنجاح!'
                  : '✅ Medication dose confirmed as taken!',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      },
      onSnooze: () async {
        await notificationService.snoozeReminder(
          id: 9999,
          medicationName: medicationName,
          doseDescription: doseDescription,
          isArabic: isArabic,
          minutes: 10,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? '⏱️ تم تأجيل المنبه لمدة 10 دقائق (غفوة)'
                    : '⏱️ Alarm snoozed for 10 minutes',
              ),
              backgroundColor: const Color(0xFFEA580C),
            ),
          );
        }
      },
      onDismiss: () async {
        await notificationService.cancelReminder(9999);
      },
    );
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
        child: Column(
          children: [
            // Top High-Priority Medical Alarm Banner (Tailored for Elderly & Hearing Impaired)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic
                                      ? 'منبه طبي عالي الصوت والأولوية'
                                      : 'High-Priority Medical Alarm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isArabic
                                      ? 'نغمة اختراقية واهتزاز متواصل لكبار السن وضعاف السمع'
                                      : 'Piercing chime & insistent vibration for seniors',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _triggerLiveAlarmTest(
                          context: context,
                          medicationName:
                              isArabic ? 'أوميبرازول 20 مجم' : 'Omeprazole 20mg',
                          doseDescription: isArabic
                              ? 'قرص واحد قبل الإفطار'
                              : '1 capsule before breakfast',
                          isArabic: isArabic,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.volume_up_rounded, size: 20),
                        label: Text(
                          isArabic
                              ? 'تجربة المنبه الحي (صوت واهتزاز)'
                              : 'Test Live Alarm (Loud Chime & Vibration)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Reminders List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _remindersFuture,
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
                            isArabic
                                ? 'لا توجد تنبيهات أدوية مجدولة حالياً'
                                : 'No active reminders scheduled',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              isArabic
                                  ? 'اضغط على زر "إضافة تذكير" بالأسفل لجدولة مواعيد أدويتك كمنبه صوتي واهتزازي'
                                  : 'Tap Add Reminder below to schedule dose alarms with chime & vibration',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
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
                      final name = item['medication_name'] as String;
                      final dose = item['dose_description'] as String;
                      final firstTime = item['first_dose_time'] as String;
                      final interval = item['interval_hours'] as int;
                      final isOneTime = (item['is_one_time'] ?? 0) == 1;

                      return Card(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: isOneTime
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppColors.primaryLightBlue,
                            child: Icon(
                              isOneTime
                                  ? Icons.event_available_rounded
                                  : Icons.alarm_rounded,
                              color: isOneTime ? Colors.deepOrange : AppColors.primaryBlue,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              if (isOneTime)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orange.shade400, width: 0.8),
                                  ),
                                  child: Text(
                                    isArabic ? 'جرعة واحدة' : 'One-Time',
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
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded,
                                    color: AppColors.primaryBlue),
                                tooltip: isArabic ? 'تجربة المنبه' : 'Test Alarm',
                                onPressed: () => _triggerLiveAlarmTest(
                                  context: context,
                                  medicationName: name,
                                  doseDescription: dose,
                                  isArabic: isArabic,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent),
                                tooltip: isArabic ? 'حذف المنبه' : 'Delete Alarm',
                                onPressed: () async {
                                  final db = ref.read(databaseHelperProvider);
                                  await db.deleteReminder(id);
                                  final notif = ref.read(notificationServiceProvider);
                                  await notif.cancelReminder(id);
                                  _reloadReminders();
                                },
                              ),
                            ],
                          ),
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

  void _showAddReminderDialog(BuildContext context) {
    final lang = ref.read(languageProvider);
    final isArabic = lang == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _selectedDate = DateTime.now();
    _selectedTime =
        TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    _isOneTime = false;
    _intervalHours = 8;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = DateFormat('yyyy/MM/dd', isArabic ? 'ar' : 'en')
                .format(_selectedDate);
            final timeStr = _selectedTime.format(context);

            return AlertDialog(
              title: Text(isArabic ? 'جدولة منبه دواء' : 'Schedule Medication Alarm'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اسم الدواء' : 'Medication Name',
                        hintText: isArabic
                            ? 'مثال: أوميبرازول 20 مجم'
                            : 'e.g. Omeprazole',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _doseController,
                      decoration: InputDecoration(
                        labelText:
                            isArabic ? 'وصف الجرعة (اختياري)' : 'Dose (Optional)',
                        hintText:
                            isArabic ? 'مثال: قرص واحد 20 مجم' : 'e.g. 1 tablet 20mg',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminder Type Selector (One-Time vs Recurring)
                    Text(
                      isArabic ? 'نوع الجدولة:' : 'Schedule Type:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.primaryDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setDialogState(() => _isOneTime = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isOneTime
                                    ? AppColors.primaryBlue
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  isArabic ? 'تكرار دوري' : 'Recurring',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: !_isOneTime
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
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
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  isArabic ? 'جرعة واحدة فقط' : 'One-Time Dose',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _isOneTime
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
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
                        leading: const Icon(Icons.calendar_today_rounded,
                            color: Colors.deepOrange),
                        title:
                            Text(isArabic ? 'تاريخ موعد الجرعة' : 'Dose Date'),
                        subtitle: Text(dateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit_calendar_rounded),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() => _selectedDate = pickedDate);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded,
                            color: Colors.deepOrange),
                        title: Text(
                            isArabic ? 'ساعة ووقت الجرعة' : 'Dose Exact Time'),
                        subtitle: Text(timeStr,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 18, color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? 'سيتم إطلاق المنبه عالي الصوت في اليوم والساعة المحددة.'
                                    : 'Alarm will ring with loud chime on the specified date & time.',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.deepOrange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Recurring: First Dose Time + Interval
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded,
                            color: AppColors.primaryBlue),
                        title: Text(
                            isArabic ? 'موعد الجرعة الأولى' : 'First Dose Time'),
                        subtitle: Text(timeStr,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          labelText:
                              isArabic ? 'التكرار الدوري' : 'Repeat Interval',
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 4,
                              child: Text(
                                  isArabic ? 'كل 4 ساعات' : 'Every 4 hours')),
                          DropdownMenuItem(
                              value: 6,
                              child: Text(
                                  isArabic ? 'كل 6 ساعات' : 'Every 6 hours')),
                          DropdownMenuItem(
                              value: 8,
                              child: Text(isArabic
                                  ? 'كل 8 ساعات (3 مرات يومياً)'
                                  : 'Every 8 hours')),
                          DropdownMenuItem(
                              value: 12,
                              child: Text(isArabic
                                  ? 'كل 12 ساعة (مرتين يومياً)'
                                  : 'Every 12 hours')),
                          DropdownMenuItem(
                              value: 24,
                              child: Text(isArabic
                                  ? 'مرة واحدة يومياً (كل 24 ساعة)'
                                  : 'Once daily (24 hrs)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _intervalHours = val);
                          }
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
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

                    final notificationService =
                        ref.read(notificationServiceProvider);
                    await notificationService.scheduleMedicationReminder(
                      id: id,
                      medicationName: name,
                      firstDoseTime: targetDateTime,
                      intervalHours: _isOneTime ? 0 : _intervalHours,
                      isOneTime: _isOneTime,
                      isArabic: isArabic,
                      doseDescription: dose,
                    );

                    _nameController.clear();
                    _doseController.clear();
                    if (mounted) {
                      Navigator.pop(ctx);
                      _reloadReminders();
                    }
                  },
                  child: Text(isArabic ? 'حفظ وجدولة المنبه' : 'Save & Schedule Alarm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
