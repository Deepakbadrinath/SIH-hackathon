import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/models/medication_models.dart';
import '../../../common_widgets/large_text.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/secondary_button.dart';

class MedicationEditDialog extends StatefulWidget {
  final Medication? existingMedication;
  final MedicationSchedule? existingSchedule;
  final Function({
    required String name,
    required String dosageDescription,
    required String timeOfDay,
    required MealRelation mealRelation,
    required String instructions,
    required bool isActive,
  }) onSave;
  final VoidCallback? onDelete;

  const MedicationEditDialog({
    super.key,
    this.existingMedication,
    this.existingSchedule,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<MedicationEditDialog> createState() => _MedicationEditDialogState();
}

class _MedicationEditDialogState extends State<MedicationEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _dosageCtrl;
  late TextEditingController _instructionsCtrl;

  late TimeOfDay _selectedTime;
  late MealRelation _selectedMealRelation;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final med = widget.existingMedication;
    final sched = widget.existingSchedule;

    _nameCtrl = TextEditingController(text: med?.name ?? '');
    _dosageCtrl = TextEditingController(text: med?.dosageDescription ?? '');
    _instructionsCtrl = TextEditingController(text: med?.instructions ?? '');

    if (sched != null) {
      final parts = sched.timeOfDay.split(':');
      final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8;
      final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      _selectedTime = TimeOfDay(hour: hour, minute: min);
      _selectedMealRelation = sched.mealRelation;
      _isActive = med?.isActive ?? true;
    } else {
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      _selectedMealRelation = MealRelation.afterMeal;
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingMedication != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LargeText(
                        isEditing ? 'Edit Medication' : 'Add Medication Reminder',
                        type: LargeTextType.heading,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Caregiver-authorized entry only. Do not invent medical instructions.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 16),

                // Medication Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Medication Name *',
                    hintText: 'e.g. Donepezil, Multivitamin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.medication_rounded),
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter medication name' : null,
                ),
                const SizedBox(height: 16),

                // Dosage Description
                TextFormField(
                  controller: _dosageCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dosage Text *',
                    hintText: 'e.g. 1 tablet (5mg), 1 capsule',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.local_pharmacy_rounded),
                  ),
                  style: const TextStyle(fontSize: 16),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter prescribed dosage' : null,
                ),
                const SizedBox(height: 16),

                // Reminder Time Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_rounded, size: 30),
                  title: const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _selectedTime.format(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
                    child: const Text('Pick Time'),
                  ),
                ),
                const SizedBox(height: 12),

                // Meal Relation Dropdown
                DropdownButtonFormField<MealRelation>(
                  initialValue: _selectedMealRelation,
                  decoration: InputDecoration(
                    labelText: 'Meal Timing',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.restaurant_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: MealRelation.afterMeal, child: Text('After Meal')),
                    DropdownMenuItem(value: MealRelation.beforeMeal, child: Text('Before Meal')),
                    DropdownMenuItem(value: MealRelation.withMeal, child: Text('With Meal')),
                    DropdownMenuItem(value: MealRelation.anytime, child: Text('Anytime')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMealRelation = v);
                  },
                ),
                const SizedBox(height: 16),

                // Instructions
                TextFormField(
                  controller: _instructionsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Special Instructions (Optional)',
                    hintText: 'e.g. Take with warm water after breakfast',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.info_outline_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Active Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder Active', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Toggle reminder notifications on or off'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                PrimaryButton(
                  label: isEditing ? 'Save Changes' : 'Create Reminder',
                  icon: Icons.check_circle_rounded,
                  height: 56,
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onSave(
                        name: _nameCtrl.text.trim(),
                        dosageDescription: _dosageCtrl.text.trim(),
                        timeOfDay: _formatTimeOfDay(_selectedTime),
                        mealRelation: _selectedMealRelation,
                        instructions: _instructionsCtrl.text.trim(),
                        isActive: _isActive,
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 10),

                if (isEditing && widget.onDelete != null) ...[
                  SecondaryButton(
                    label: 'Delete Medication',
                    icon: Icons.delete_outline_rounded,
                    height: 50,
                    borderColor: const Color(0xFFDC2626),
                    textColor: const Color(0xFFDC2626),
                    onPressed: () {
                      widget.onDelete!();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.l10n.translate('common.button.cancel'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
