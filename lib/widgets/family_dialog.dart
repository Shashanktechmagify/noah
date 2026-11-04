import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/dial_data.dart';
import '../data/family_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'auth_scaffold.dart' show GradientButton;
import 'dial_code_picker.dart';

/// Popup to ask the office to add a relative to the family. Returns true when the request was sent.
Future<bool> showFamilyDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _FamilyDialog(),
    ) ??
    false;

class _FamilyDialog extends StatefulWidget {
  const _FamilyDialog();

  @override
  State<_FamilyDialog> createState() => _FamilyDialogState();
}

class _FamilyDialogState extends State<_FamilyDialog> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _mobile = TextEditingController();
  final _note = TextEditingController();
  String _relation = kFamilyRelations.first;
  DialCountry _country = DialData.fallback.first;
  DateTime? _dob;
  bool _sending = false;
  String? _error;

  bool get _isChildRelation => _relation == 'son' || _relation == 'daughter';

  /// A son or daughter under 18 is a child: no phone number, the office adds them.
  bool get _isKid {
    final dob = _dob;
    if (!_isChildRelation || dob == null) return false;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age -= 1;
    }
    return age < 18;
  }

  bool get _needsPhone => !_isKid;

  bool get _valid {
    if (_first.text.trim().isEmpty) return false;
    if (_isChildRelation && _dob == null) return false;
    if (_needsPhone &&
        !_country.validLength(_mobile.text.replaceAll(' ', '').length)) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_first, _last, _mobile, _note]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _mobile, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      fieldHintText: 'dd/mm/yyyy',
      initialDate: _dob ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(now.year - 100),
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
      if (liveApi) {
        await familyState.ask(
          relation: _relation,
          firstName: _first.text,
          lastName: _last.text,
          dateOfBirth: _dob == null ? null : _day(_dob!),
          countryCode: _needsPhone ? _country.dial : null,
          mobileNumber: _needsPhone ? _mobile.text : null,
          note: _note.text.trim().isEmpty ? null : _note.text,
        );
      }
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  Widget _help(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        height: 1.35,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dob = _dob;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'fam_add_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: const Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label(tr(context, 'fam_relation')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in kFamilyRelations)
                  GestureDetector(
                    onTap: () => setState(() => _relation = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: r == _relation
                            ? AppColors.buttonGradient
                            : null,
                        color: r == _relation ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: r == _relation
                              ? AppColors.magenta
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tr(context, 'rel_$r'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: r == _relation ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label(tr(context, 'fam_first')),
            TextField(
              controller: _first,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: _decoration('').copyWith(counterText: ''),
            ),
            const SizedBox(height: 12),
            _label(tr(context, 'fam_last')),
            TextField(
              controller: _last,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: _decoration('').copyWith(counterText: ''),
            ),
            if (_isChildRelation) ...[
              const SizedBox(height: 12),
              _label(tr(context, 'fam_dob')),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dob == null
                              ? tr(context, 'fam_dob_pick')
                              : '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}',
                          style: TextStyle(
                            fontSize: 15,
                            color: dob == null
                                ? AppColors.muted
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              _help(tr(context, 'fam_dob_help')),
            ],
            const SizedBox(height: 12),
            if (_needsPhone) ...[
              _label(tr(context, 'fam_mobile')),
              Row(
                children: [
                  DialCodePicker(
                    value: _country,
                    fill: AppColors.surface,
                    onChanged: (c) => setState(() => _country = c),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration(''),
                    ),
                  ),
                ],
              ),
              _help(tr(context, 'fam_mobile_help')),
            ] else
              _help(tr(context, 'fam_kid_help')),
            const SizedBox(height: 12),
            _label(tr(context, 'fam_note')),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 3,
              maxLength: 300,
              decoration: _decoration(''),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFE5334B),
                    fontSize: 13,
                  ),
                ),
              ),
            GradientButton(
              label: _sending ? '...' : tr(context, 'fam_send'),
              onPressed: _valid && !_sending ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
