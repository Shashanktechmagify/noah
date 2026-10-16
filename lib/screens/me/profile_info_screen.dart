import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/profile_data.dart';
import '../../data/registration_data.dart'
    show emailError, idNumberError, phoneError, pinError;
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show toast;
import '../registration/registration_widgets.dart' show DateInputField;
import 'sub_page.dart';

const _amber = Color(0xFFC2620A);
const _amberBg = Color(0xFFFDEBD3);

/// Me → My information: every detail the ministry holds about the member.
/// Members cannot edit these directly. They tap a detail, enter the new value
/// and send it to the admin; the detail changes only if the admin accepts.
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
            _Notice(
              icon: Icons.info_outline,
              background: _amberBg,
              color: _amber,
              text: tr(context, 'pf_banner', args: {'n': '$missing'}),
            ),
          _Notice(
            icon: Icons.lock_outline,
            background: AppColors.tint,
            color: AppColors.ink,
            text: tr(context, 'pf_view_note'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: profile.pendingCount > 0
                  ? '${tr(context, 'pf_req_btn')} (${profile.pendingCount})'
                  : tr(context, 'pf_req_btn'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangeRequestsScreen()),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.background,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A stored value as the member sees it (choice label, dd/mm/yyyy date).
String _display(BuildContext context, PfField f, String v) {
  if (v.isEmpty) return tr(context, 'pf_empty');
  // The joining date is system set (read only) but is still a date.
  if (f.id == 'joined') return displayDate(v);
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

/// The value shown in a row: age is worked out, everything else is stored.
String _shown(BuildContext context, PfField f) {
  if (f.id == 'age') return profile.age?.toString() ?? '';
  final v = profile.get(f.id);
  return v.isEmpty ? '' : _display(context, f, v);
}

/// One detail. Tapping it starts a request to the admin to change or add it.
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final PfField field;

  @override
  Widget build(BuildContext context) {
    final value = _shown(context, field);
    final required = profile.isRequired(field);
    final empty = value.isEmpty;
    final pending = profile.pendingFor(field.id);
    final askable = field.kind != PfKind.readOnly;
    return InkWell(
      onTap: askable ? () => showChangeRequest(context, field) : null,
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
                  if (pending != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        tr(
                          context,
                          'pf_requested',
                          args: {
                            'v': _display(context, field, pending.newValue),
                          },
                        ),
                        style: const TextStyle(
                          color: _amber,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (pending != null)
              _Tag(tr(context, 'pf_pending'))
            else if (empty && required)
              _Tag(tr(context, 'pf_required'))
            else if (askable)
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.magenta,
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _amberBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _amber,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
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

/// Lets the member propose a new value for [field] and send it to the admin.
/// The detail itself does not change until the admin accepts.
Future<void> showChangeRequest(BuildContext context, PfField field) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _RequestDialog(field: field),
  );
  if (sent == true && context.mounted) {
    toast(context, tr(context, 'pf_req_sent'));
  }
}

class _RequestDialog extends StatefulWidget {
  const _RequestDialog({required this.field});

  final PfField field;

  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
  late String _value =
      profile.pendingFor(widget.field.id)?.newValue ??
      profile.get(widget.field.id);
  late final _c = TextEditingController(text: _value);

  PfField get f => widget.field;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _editor(BuildContext context) {
    switch (f.kind) {
      case PfKind.date:
        return DateInputField(
          value: DateTime.tryParse(_value),
          onChanged: (d) => setState(() {
            _value = d == null
                ? ''
                : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          }),
        );
      case PfKind.choice:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, key) in f.options!)
              GestureDetector(
                onTap: () => setState(() => _value = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: value == _value ? AppColors.magenta : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: value == _value
                          ? AppColors.magenta
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    key == null ? value : tr(context, key),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value == _value ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        );
      default:
        final error = _error(f, _value);
        return TextField(
          controller: _c,
          autofocus: true,
          onChanged: (v) => setState(() => _value = v),
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
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = f.kind == PfKind.idNumber ? _value.toUpperCase() : _value;
    final valid =
        v.trim().isNotEmpty &&
        _error(f, v) == null &&
        v.trim() != profile.get(f.id);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'pf_req_title'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              tr(context, f.labelKey),
              style: const TextStyle(
                color: AppColors.magenta,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tr(
                context,
                'pf_req_current',
                args: {'v': _display(context, f, profile.get(f.id))},
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Text(
              tr(context, 'pf_req_new'),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _editor(context),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      tr(context, 'pf_cancel'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    label: tr(context, 'pf_req_submit'),
                    onPressed: valid
                        ? () {
                            profile.requestChange(f.id, v);
                            Navigator.of(context).pop(true);
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

/// The member's change requests and what the admin decided. The accept / reject
/// buttons are prototype controls standing in for the admin's own screen.
class ChangeRequestsScreen extends StatelessWidget {
  const ChangeRequestsScreen({super.key});

  PfField _field(String id) =>
      kProfileSections.expand((s) => s.fields).firstWhere((f) => f.id == id);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: profile,
    builder: (context, _) => SubPage(
      title: tr(context, 'pf_reqs_title'),
      subtitle: tr(context, 'pf_reqs_sub'),
      children: [
        if (profile.requests.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                tr(context, 'pf_reqs_none'),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        for (final r in profile.requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WhiteCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, _field(r.fieldId).labelKey),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_display(context, _field(r.fieldId), r.oldValue)}  →  ${_display(context, _field(r.fieldId), r.newValue)}',
                    style: const TextStyle(
                      color: Color(0xFF55576F),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    text: tr(context, 'pf_st_${r.status.name}'),
                    background: switch (r.status) {
                      RequestStatus.pending => _amberBg,
                      RequestStatus.approved => const Color(0xFFE1F3E7),
                      RequestStatus.rejected => const Color(0xFFECEAF5),
                    },
                    foreground: switch (r.status) {
                      RequestStatus.pending => _amber,
                      RequestStatus.approved => const Color(0xFF1F8A4C),
                      RequestStatus.rejected => AppColors.muted,
                    },
                  ),
                  if (r.status == RequestStatus.pending) ...[
                    const SizedBox(height: 14),
                    Text(
                      tr(context, 'pf_proto').toUpperCase(),
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: spacing(context, 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ProtoButton(
                            label: tr(context, 'pf_sim_accept'),
                            onTap: () => profile.approveRequest(r),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProtoButton(
                            label: tr(context, 'pf_sim_reject'),
                            onTap: () => profile.rejectRequest(r),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _ProtoButton extends StatelessWidget {
  const _ProtoButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.magenta),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.magenta,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
