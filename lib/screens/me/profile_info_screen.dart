import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/profile_data.dart';
import '../../data/registration_data.dart'
    show emailError, idNumberError, phoneError, pinError;
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

const _amber = Color(0xFFC2620A);
const _amberBg = Color(0xFFFDEBD3);

/// Me → My information: every detail the ministry holds about the member.
/// Anything missing is flagged so the member can fill it in.
class ProfileInfoScreen extends StatelessWidget {
  const ProfileInfoScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: profile,
    builder: (context, _) {
      final missing = profile.missingRequired;
      final total = profile.totalRequired;
      return SubPage(
        title: tr(context, 'pf_title'),
        subtitle: tr(
          context,
          'pf_sub',
          args: {'a': '${total - missing}', 'b': '$total'},
        ),
        children: [
          if (missing > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _amberBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(context, 'pf_banner', args: {'n': '$missing'}),
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F3E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF1F8A4C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(context, 'pf_all_set'),
                      style: const TextStyle(
                        color: Color(0xFF1F8A4C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final section in kProfileSections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Text(
                tr(context, section.titleKey),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, f) in section.fields.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _FieldRow(field: f),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
    },
  );
}

String _shown(BuildContext context, PfField f) {
  if (f.id == 'age') return profile.age?.toString() ?? '';
  final v = profile.get(f.id);
  if (v.isEmpty) return '';
  switch (f.kind) {
    case PfKind.date:
      return displayDate(v);
    case PfKind.choice:
      for (final (value, key) in f.options!) {
        if (value == v) return key == null ? value : tr(context, key);
      }
      return v;
    case PfKind.number:
      return f.id == 'height'
          ? '$v ${tr(context, 'pf_cm')}'
          : '$v ${tr(context, 'pf_kg')}';
    default:
      return v;
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final PfField field;

  @override
  Widget build(BuildContext context) {
    final value = _shown(context, field);
    final required = profile.isRequired(field);
    final editable = field.kind != PfKind.readOnly;
    final empty = value.isEmpty;
    return InkWell(
      onTap: editable ? () => _edit(context, field) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, field.labelKey),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (!empty)
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else if (field.kind == PfKind.readOnly)
                    const Text(
                      '—',
                      style: TextStyle(color: AppColors.muted, fontSize: 15),
                    )
                  else
                    Text(
                      tr(context, required ? 'pf_fill' : 'pf_add'),
                      style: TextStyle(
                        color: required ? _amber : AppColors.muted,
                        fontSize: 14,
                        fontWeight: required
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (editable)
              empty && required
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _amberBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tr(context, 'pf_required'),
                        style: const TextStyle(
                          color: _amber,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : Icon(
                      empty ? Icons.add : Icons.edit_outlined,
                      size: 18,
                      color: AppColors.magenta,
                    ),
          ],
        ),
      ),
    );
  }
}

String? _error(PfField f, String v) {
  if (v.trim().isEmpty) return null;
  return switch (f.kind) {
    PfKind.email => emailError(v),
    PfKind.phone => phoneError(v),
    PfKind.pin => pinError(v),
    PfKind.idNumber => idNumberError(f.idType, v),
    PfKind.number =>
      RegExp(r'^\d{1,3}(\.\d+)?$').hasMatch(v.trim()) ? null : 'pf_err_number',
    _ => null,
  };
}

Future<void> _edit(BuildContext context, PfField f) async {
  switch (f.kind) {
    case PfKind.date:
      final now = DateTime.now();
      final current = DateTime.tryParse(profile.get(f.id));
      final picked = await showDatePicker(
        context: context,
        initialDate: current ?? DateTime(now.year - 30, now.month, now.day),
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked != null) {
        profile.set(
          f.id,
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
        );
      }
    case PfKind.choice:
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheet).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    tr(sheet, f.labelKey),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final (value, key) in f.options!)
                  ListTile(
                    title: Text(
                      key == null ? value : tr(sheet, key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: profile.get(f.id) == value
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.magenta,
                          )
                        : null,
                    onTap: () => Navigator.of(sheet).pop(value),
                  ),
              ],
            ),
          ),
        ),
      );
      if (picked != null) profile.set(f.id, picked);
    default:
      await showDialog<void>(
        context: context,
        builder: (_) => _TextEditDialog(field: f),
      );
  }
}

class _TextEditDialog extends StatefulWidget {
  const _TextEditDialog({required this.field});

  final PfField field;

  @override
  State<_TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<_TextEditDialog> {
  late final _c = TextEditingController(text: profile.get(widget.field.id));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    final error = _error(f, _c.text);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, f.labelKey),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _c,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              keyboardType: switch (f.kind) {
                PfKind.phone => TextInputType.phone,
                PfKind.email => TextInputType.emailAddress,
                PfKind.pin || PfKind.number => TextInputType.number,
                _ => TextInputType.text,
              },
              inputFormatters: [
                if (f.kind == PfKind.pin) ...[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                if (f.kind == PfKind.number)
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                if (f.kind == PfKind.phone)
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              textCapitalization: f.kind == PfKind.idNumber
                  ? TextCapitalization.characters
                  : TextCapitalization.sentences,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                errorText: error == null ? null : tr(context, error),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      tr(context, 'pf_cancel'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GradientButton(
                    label: tr(context, 'pf_save'),
                    onPressed: error == null
                        ? () {
                            profile.set(
                              f.id,
                              f.kind == PfKind.idNumber
                                  ? _c.text.toUpperCase()
                                  : _c.text,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
