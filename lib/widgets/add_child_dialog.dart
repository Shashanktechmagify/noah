import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/family_data.dart';
import '../data/registration_data.dart' show idNumberError;
import '../l10n/app_strings.dart';
import '../screens/registration/uploads.dart';
import '../theme/app_theme.dart';
import 'auth_scaffold.dart' show GradientButton;

/// Popup for a parent to add a child under 18: photo, names, date of birth, boy or girl, and the Aadhaar if the parent has
/// it (optional). The child joins the family at once. Returns the child's name when it was added, else null.
Future<String?> showAddChildDialog(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _AddChildDialog(),
);

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _aadhaar = TextEditingController();
  DateTime? _dob;
  String? _gender; // 'male' or 'female'
  PickedUpload? _photo;
  PickedUpload? _aadhaarDoc;
  bool _sending = false;
  String? _error;

  String get _aadhaarDigits => _aadhaar.text.replaceAll(RegExp(r'\D'), '');

  String? get _aadhaarError =>
      _aadhaarDigits.isEmpty ? null : idNumberError('aadhaar', _aadhaarDigits);

  bool get _aadhaarOk => _aadhaarError == null;

  bool get _valid =>
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      _dob != null &&
      _gender != null &&
      (_photo?.ok ?? false) &&
      _aadhaarOk;

  @override
  void initState() {
    super.initState();
    for (final c in [_first, _middle, _last, _aadhaar]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _aadhaar]) {
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

  Future<void> _pickPhoto() async {
    final p = await pickPhoto(context);
    if (p == null || !mounted) return;
    setState(() {
      _photo = p;
      _error = p.ok ? null : tr(context, p.errorKey!);
    });
  }

  Future<void> _pickAadhaar() async {
    final p = await pickDocument(context);
    if (p == null || !mounted) return;
    setState(() {
      _aadhaarDoc = p.ok ? p : null;
      _error = p.ok ? null : tr(context, p.errorKey!);
    });
  }

  Future<void> _submit() async {
    if (_sending || !_valid) return;
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final photo = await api.uploadFile('photo', _photo!.path!);
      String? doc;
      if (_aadhaarDoc != null) {
        doc = (await api.uploadFile('idProof', _aadhaarDoc!.path!)).id;
      }
      await api.addChild(
        firstName: _first.text,
        middleName: _middle.text,
        lastName: _last.text,
        dateOfBirth: _day(_dob!),
        gender: _gender!,
        photoFileId: photo.id,
        aadhaarNumber: _aadhaarDigits.isEmpty ? null : _aadhaarDigits,
        aadhaarFileId: doc,
      );
      await familyState.load();
      navigator.pop(
        [
          _first.text.trim(),
          _last.text.trim(),
        ].where((e) => e.isNotEmpty).join(' '),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _field(
    TextEditingController c,
    String hintKey, {
    TextInputType? type,
    bool words = true,
    List<TextInputFormatter>? formatters,
    String? errorText,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: type,
      textCapitalization: words
          ? TextCapitalization.words
          : TextCapitalization.none,
      inputFormatters: formatters,
      decoration: _deco(tr(context, hintKey)).copyWith(errorText: errorText),
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

  Widget _photoPicker() {
    final path = (_photo?.ok ?? false) ? _photo!.path : null;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _sending ? null : _pickPhoto,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                image: path == null
                    ? null
                    : DecorationImage(
                        image: FileImage(File(path)),
                        fit: BoxFit.cover,
                      ),
              ),
              child: path == null
                  ? const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.magenta,
                      size: 30,
                    )
                  : null,
            ),
          ),
          TextButton(
            onPressed: _sending ? null : _pickPhoto,
            child: Text(
              tr(
                context,
                path == null ? 'add_child_photo' : 'add_child_photo_change',
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          _photoPicker(),
          const SizedBox(height: 6),
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
              _genderChip('male', 'add_child_boy'),
              const SizedBox(width: 10),
              _genderChip('female', 'add_child_girl'),
            ],
          ),
          const SizedBox(height: 14),
          _field(
            _aadhaar,
            'add_child_aadhaar',
            type: TextInputType.number,
            words: false,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            errorText: _aadhaarError == null
                ? null
                : tr(context, _aadhaarError!),
          ),
          OutlinedButton.icon(
            onPressed: _sending ? null : _pickAadhaar,
            icon: Icon(
              _aadhaarDoc == null ? Icons.upload_file : Icons.check_circle,
              size: 18,
            ),
            label: Text(
              tr(
                context,
                _aadhaarDoc == null
                    ? 'add_child_aadhaar_doc'
                    : 'add_child_aadhaar_up',
              ),
            ),
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
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              child: Text(tr(context, 'add_child_cancel')),
            ),
          ),
        ],
      ),
    ),
  );
}
