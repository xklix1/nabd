import 'package:flutter/material.dart';
import '../../../core/notifications/alarm_audio_service.dart';
import '../../../core/theme/app_colors.dart';

/// Highly-accessible Medical Alarm Dialog designed specifically for elderly
/// and hearing-impaired patients (High contrast, 60dp+ touch targets, prominent actions).
class MedicationAlarmDialog extends StatefulWidget {
  final String medicationName;
  final String doseDescription;
  final bool isArabic;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  const MedicationAlarmDialog({
    super.key,
    required this.medicationName,
    required this.doseDescription,
    required this.isArabic,
    required this.onTaken,
    required this.onSnooze,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String medicationName,
    required String doseDescription,
    required bool isArabic,
    required VoidCallback onTaken,
    required VoidCallback onSnooze,
    required VoidCallback onDismiss,
  }) {
    AlarmAudioService.startAlarm();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MedicationAlarmDialog(
        medicationName: medicationName,
        doseDescription: doseDescription,
        isArabic: isArabic,
        onTaken: () {
          AlarmAudioService.stopAlarm();
          Navigator.of(ctx).pop();
          onTaken();
        },
        onSnooze: () {
          AlarmAudioService.stopAlarm();
          Navigator.of(ctx).pop();
          onSnooze();
        },
        onDismiss: () {
          AlarmAudioService.stopAlarm();
          Navigator.of(ctx).pop();
          onDismiss();
        },
      ),
    ).then((_) {
      AlarmAudioService.stopAlarm();
    });
  }

  @override
  State<MedicationAlarmDialog> createState() => _MedicationAlarmDialogState();
}

class _MedicationAlarmDialogState extends State<MedicationAlarmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    AlarmAudioService.startAlarm();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    AlarmAudioService.stopAlarm();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: isDark ? const Color(0xFF161F2E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pulsing Alarm Bell Header
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isAr ? '⏰ منبه موعد الدواء!' : '⏰ Medication Dose Alarm!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'يرجى تناول الجرعة المحددة الآن للحفاظ على صحتك'
                    : 'Please take your scheduled dose now to maintain your health',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Medication Card with High Contrast
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.medicationName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryDarkBlue,
                      ),
                    ),
                    if (widget.doseDescription.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '💊 ${widget.doseDescription}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.secondaryTeal : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Huge Primary Action: "تم تناول الدواء الآن"
              SizedBox(
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: widget.onTaken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 28),
                  label: Text(
                    isAr ? 'تم تناول الدواء الآن' : 'Taken Dose Now',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Action: "غفوة 10 دقائق"
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: widget.onSnooze,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEA580C), width: 2),
                    foregroundColor: const Color(0xFFEA580C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.snooze_rounded, size: 24),
                  label: Text(
                    isAr ? 'غفوة 10 دقائق (تذكير لاحقاً)' : 'Snooze 10 Minutes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Dismiss
              Center(
                child: TextButton(
                  onPressed: widget.onDismiss,
                  child: Text(
                    isAr ? 'إيقاف المنبه' : 'Dismiss Alarm',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
