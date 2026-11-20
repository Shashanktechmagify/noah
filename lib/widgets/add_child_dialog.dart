import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/family_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'auth_scaffold.dart' show GradientButton;

/// Popup for a parent to add a child: first name, last name, middle name (optional), date of birth and gender. The
/// office checks it, then the parent is asked to register the child. Returns true when it was sent.
Future<bool> showAddChildDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _AddChildDialog(),
    ) ??
    false;

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  DateTime? _dob;
  String?
  _gender; // 'son' (boy) or 'daughter' (girl): what the child is to the parent
  bool _sending = false;
  String? _error;

  bool get _valid =>
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      _dob != null &&
      _gender != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_first, _middle, _last]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _middle, _last]) {
      c.dispose();
    }
    super.dispose();
  }

  String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _shown(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      fieldHintText: 'dd/mm/yyyy',
      initialDate: _dob ?? DateTime(now.year - 8, now.month, now.day),
      // A child is under 18.
      firstDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ).add(const Duration(days: 1)),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (_sending || !_valid) return;
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await familyState.ask(
        relation: _gender!,
        firstName: _first.text,
        middleName: _middle.text,
        lastName: _last.text,
        dateOfBirth: _day(_dob!),
      );
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  Widget _field(TextEditingController c, String hintKey) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: tr(context, hintKey),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _genderChip(String value, String labelKey) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _gender == value ? AppColors.tint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _gender == value ? AppColors.magenta : AppColors.border,
          ),
        ),
        child: Text(
          tr(context, labelKey),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _gender == value ? AppColors.magenta : AppColors.ink,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'add_child_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            tr(context, 'add_child_sub'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _field(_first, 'add_child_first'),
          _field(_middle, 'add_child_middle'),
          _field(_last, 'add_child_last'),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _dob == null ? tr(context, 'add_child_dob') : _shown(_dob!),
                style: TextStyle(
                  fontSize: 15,
                  color: _dob == null ? AppColors.muted : AppColors.ink,
                  fontWeight: _dob == null ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _genderChip('son', 'add_child_boy'),
              const SizedBox(width: 10),
              _genderChip('daughter', 'add_child_girl'),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFD6334B), fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          GradientButton(
            label: _sending ? '...' : tr(context, 'add_child_add'),
            onPressed: _valid && !_sending ? _submit : null,
          ),
          Center(
            child: TextButton(
              onPressed: _sending
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(tr(context, 'add_child_cancel')),
            ),
          ),
        ],
      ),
    ),
  );
}
