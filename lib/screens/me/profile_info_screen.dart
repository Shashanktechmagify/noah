import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:video_player/video_player.dart';

import '../../data/api_client.dart';
import '../../data/profile_data.dart';
import '../../data/registration_data.dart'
    show emailError, idNumberError, phoneError, pinError;
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/page_scaffold.dart';
import '../../widgets/rich_html.dart' show openImageProviderViewer;
import '../jodie/jodie_widgets.dart' show toast;
import '../registration/contact_confirm.dart' show confirmContact;
import '../registration/registration_widgets.dart' show DateInputField;
import 'sub_page.dart';

const _amber = Color(0xFFC2620A);
const _amberBg = Color(0xFFFDEBD3);

/// Me → My information: every detail the ministry holds about the member.
/// Members cannot edit these directly. They tap a detail, enter the new value
/// and send it to the admin; the detail changes only if the admin accepts.
class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  @override
  void initState() {
    super.initState();
    // Anything entered but not sent when the page was last left is dropped; the uploads come from the server.
    profile.drafts.clear();
    profile.loadDocuments();
    // The office may have decided on a request since the app last asked.
    profile.refresh();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: profile,
    builder: (context, _) {
      final missing = profile.missingRequired;
      final total = profile.totalRequired;
      return SubPage(
        bottomBar: profile.drafts.isEmpty
            ? null
            : _SendBar(key: ValueKey(profile.drafts.length)),
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
            if (section.titleKey == 'pf_sec_documents' &&
                (profile.docs?.any ?? false)) ...[
              const SizedBox(height: 12),
              _DocsCard(docs: profile.docs!),
            ],
            const SizedBox(height: 14),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: profile.pendingCount > 0
                  ? '${tr(context, 'pf_req_btn')} (${profile.pendingCount})'
                  : tr(context, 'pf_req_btn'),
              onPressed: () {
                profile.refresh();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangeRequestsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

/// The one button that sends every detail the member changed to the admin together.
class _SendBar extends StatelessWidget {
  const _SendBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr(
              context,
              'pf_drafts_ready',
              args: {'n': '${profile.drafts.length}'},
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          GradientButton(
            label: '${tr(context, 'pf_req_submit')} (${profile.drafts.length})',
            onPressed: () {
              profile.submitDrafts();
              toast(context, tr(context, 'pf_req_sent'));
            },
          ),
        ],
      ),
    ),
  );
}

/// What the member uploaded when registering: ID proof and photo (tap to see them) and the declaration video.
class _DocsCard extends StatelessWidget {
  const _DocsCard({required this.docs});

  final UploadedDocs docs;

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onView,
  }) => InkWell(
    onTap: onView,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          IconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            tr(context, 'pf_doc_view'),
            style: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    ),
  );

  /// A picture the member uploaded, full screen and zoomable, fetched with their own login.
  void _viewFile(BuildContext context, String fileId) =>
      openImageProviderViewer(
        context,
        NetworkImage(api.fileUrl(fileId), headers: api.authHeaders),
      );

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final uploaded = tr(context, 'pf_doc_uploaded');
    final seconds = docs.videoSeconds;
    final rows = <Widget>[
      if (docs.idProofId != null)
        _row(
          context,
          icon: Icons.badge_outlined,
          title: tr(context, 'pf_doc_idproof'),
          subtitle: docs.idType == null
              ? uploaded
              : '${docs.idType!.toUpperCase()} · $uploaded',
          onView: () => _viewFile(context, docs.idProofId!),
        ),
      if (docs.photoId != null)
        _row(
          context,
          icon: Icons.photo_outlined,
          title: tr(context, 'pf_doc_photo'),
          subtitle: uploaded,
          onView: () => _viewFile(context, docs.photoId!),
        ),
      if (docs.videoId != null)
        _row(
          context,
          icon: Icons.videocam_outlined,
          title: tr(context, 'pf_doc_video'),
          subtitle: seconds == null
              ? uploaded
              : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} · $uploaded',
          onView: () => _open(
            context,
            _VideoPage(
              title: tr(context, 'pf_doc_video'),
              fileId: docs.videoId!,
            ),
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Text(
            tr(context, 'pf_docs_title'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        WhiteCard(
          child: Column(
            children: [
              for (final (i, r) in rows.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                r,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The declaration video the member recorded, played from the server with their own login.
class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.title, required this.fileId});

  final String title;
  final String fileId;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(
      Uri.parse(api.fileUrl(widget.fileId)),
      httpHeaders: api.authHeaders,
    );
    _c
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() => _ready = true);
            _c.play();
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(widget.title),
    ),
    body: Center(
      child: _failed
          ? Text(
              tr(context, 'pf_doc_nopreview'),
              style: const TextStyle(color: Colors.white70),
            )
          : !_ready
          ? const CircularProgressIndicator(color: Colors.white)
          : GestureDetector(
              onTap: () =>
                  setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
              child: AspectRatio(
                aspectRatio: _c.value.aspectRatio,
                child: VideoPlayer(_c),
              ),
            ),
    ),
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
      final option = f.optionFor(v);
      if (option == null) return v;
      return option.$2 == null ? option.$1 : tr(context, option.$2!);
    case PfKind.education:
      // One line for each qualification; 10th and 12th show their school, marks and year.
      return [
        for (final e in parseEducation(v, f.options!.map((o) => o.$1)))
          eduNeedsDetails(e.label)
              ? '${e.label}: ${e.school}, ${e.marks}, ${e.year}'
              : e.label,
      ].join('\n');
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
  if (f.id == 'age') {
    final a = profile.ageParts;
    if (a == null) return '';
    final years = tr(context, a.years == 1 ? 'pf_year' : 'pf_years', args: {'n': '${a.years}'});
    if (a.months == 0) return years;
    final months = tr(context, a.months == 1 ? 'pf_month' : 'pf_months', args: {'n': '${a.months}'});
    return '$years $months';
  }
  final v = profile.get(f.id);
  return v.isEmpty ? '' : _display(context, f, v);
}

/// One detail. Tapping it starts a request to the admin to change or add it.
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final PfField field;

  @override
  Widget build(BuildContext context) {
    // A change the member has entered but not sent yet shows in place of the stored value.
    final draft = profile.drafts[field.id];
    final value = draft != null
        ? _display(context, field, draft)
        : _shown(context, field);
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: draft != null ? AppColors.magenta : null,
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
            if (draft != null)
              _Tag(tr(context, 'pf_edited'))
            else if (pending != null)
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

/// Lets the member enter a new value for [field]. It is kept as a draft; the one button at the bottom of
/// the page sends every draft to the admin together, and a detail changes only when the admin accepts.
Future<void> showChangeRequest(BuildContext context, PfField field) =>
    showDialog<bool>(
      context: context,
      builder: (_) => _RequestDialog(field: field),
    );

class _RequestDialog extends StatefulWidget {
  const _RequestDialog({required this.field});

  final PfField field;

  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
  late String _value = _bucket(
    profile.drafts[widget.field.id] ??
        profile.pendingFor(widget.field.id)?.newValue ??
        profile.get(widget.field.id),
  );

  /// A stored income is shown as the range it falls in.
  String _bucket(String stored) => widget.field.optionFor(stored)?.$1 ?? stored;
  late final _c = TextEditingController(text: _value);

  PfField get f => widget.field;

  bool _confirming = false;
  bool _eduComplete = true;

  /// Keeps the new value as a draft. A WhatsApp number is kept only after the code sent to it was entered.
  Future<void> _done(BuildContext context, String v) async {
    if (f.id == 'phone2' && liveApi) {
      final m = RegExp(r'^(\+\d{1,4})\s*(\d[\d\s-]*)$').firstMatch(v.trim());
      // A number typed without a country code is taken as an Indian one.
      final digits = v.replaceAll(RegExp(r'\D'), '');
      final dial = m?.group(1) ?? '+91';
      final number = m != null
          ? m.group(2)!.replaceAll(RegExp(r'\D'), '')
          : digits.length > 10
          ? digits.substring(digits.length - 10)
          : digits;
      setState(() => _confirming = true);
      final ok = await confirmContact(
        context,
        dial: dial,
        number: number,
        whatsapp: true,
      );
      if (!mounted) return;
      setState(() => _confirming = false);
      if (!ok) return;
      profile.stage(f.id, '$dial $number');
    } else {
      profile.stage(f.id, v);
    }
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => f.kind == PfKind.multi
          ? _MultiSheet(field: f, selected: _value)
          : _OptionSheet(field: f, selected: _value),
    );
    if (picked != null) setState(() => _value = picked);
  }

  Widget _pickerField(BuildContext context) => GestureDetector(
    onTap: () => _pick(context),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _value.isEmpty
                  ? tr(context, 'pf_choose')
                  : _display(context, f, _value),
              style: TextStyle(
                fontSize: 15,
                fontWeight: _value.isEmpty ? FontWeight.w500 : FontWeight.w800,
                color: _value.isEmpty ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
        ],
      ),
    ),
  );

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
      case PfKind.education:
        return _EducationEditor(
          field: f,
          initial: _value,
          onChanged: (value, complete) => setState(() {
            _value = value;
            _eduComplete = complete;
          }),
        );
      case PfKind.choice || PfKind.multi:
        // A choice is a dropdown: a sheet with the options (and a search box when the list is long).
        // A list (education) lets several be ticked.
        return _pickerField(context);
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
            // Aadhaar and Emirates ID are all digits; PAN, passport, voter ID and licence mix letters and digits.
            PfKind.idNumber
                when f.idType == 'aadhaar' || f.idType == 'emirates' =>
              TextInputType.number,
            PfKind.idNumber => TextInputType.visiblePassword,
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
            if (f.kind == PfKind.idNumber) ...[
              FilteringTextInputFormatter.allow(
                f.idType == 'aadhaar' || f.idType == 'emirates'
                    ? RegExp(r'[0-9\s-]')
                    : RegExp(r'[A-Za-z0-9\s-]'),
              ),
              LengthLimitingTextInputFormatter(24),
              TextInputFormatter.withFunction(
                (old, v) => v.copyWith(text: v.text.toUpperCase()),
              ),
            ],
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
        (f.kind != PfKind.education || _eduComplete) &&
        v.trim() != _bucket(profile.get(f.id));
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
            if (profile.drafts.containsKey(f.id))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    profile.discardDraft(f.id);
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    tr(context, 'pf_discard'),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
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
                    label: tr(context, 'pf_done'),
                    onPressed: valid && !_confirming
                        ? () => _done(context, v)
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

/// The qualifications to tick, and, for each of 10th (SSC) and 12th (HSC) that is ticked, the school name, the marks
/// and the academic year. Reports the text to keep and whether every detail that is asked for is filled in.
class _EducationEditor extends StatefulWidget {
  const _EducationEditor({
    required this.field,
    required this.initial,
    required this.onChanged,
  });

  final PfField field;
  final String initial;
  final void Function(String value, bool complete) onChanged;

  @override
  State<_EducationEditor> createState() => _EducationEditorState();
}

class _EducationEditorState extends State<_EducationEditor> {
  late final List<EduEntry> _entries = parseEducation(
    widget.initial,
    widget.field.options!.map((o) => o.$1),
  );
  final _controllers = <String, TextEditingController>{};

  TextEditingController _c(EduEntry e, String part, String initial) =>
      _controllers.putIfAbsent('${e.label}|$part', () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _report() => widget.onChanged(
    composeEducation(_entries),
    _entries.isNotEmpty && _entries.every((e) => e.complete),
  );

  Future<void> _pick() async {
    final labels = _entries.map((e) => e.label).join(',');
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MultiSheet(field: widget.field, selected: labels),
    );
    if (picked == null) return;
    final chosen = picked.split(', ').where((p) => p.isNotEmpty).toList();
    setState(() {
      // What was already typed for a qualification that stays is kept.
      final old = {for (final e in _entries) e.label: e};
      _entries
        ..clear()
        ..addAll([for (final l in chosen) old[l] ?? EduEntry(l)]);
    });
    _report();
  }

  Widget _input(EduEntry e, String part, String hintKey, String value, void Function(String) set) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextField(
      controller: _c(e, part, value),
      onChanged: (v) {
        set(v);
        setState(() {});
        _report();
      },
      textCapitalization: TextCapitalization.words,
      keyboardType: part == 'school' ? TextInputType.text : TextInputType.visiblePassword,
      decoration: InputDecoration(
        hintText: tr(context, hintKey),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _entries.isEmpty
                        ? tr(context, 'pf_choose')
                        : _entries.map((e) => e.label).join(', '),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _entries.isEmpty ? FontWeight.w500 : FontWeight.w800,
                      color: _entries.isEmpty ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
              ],
            ),
          ),
        ),
        // 10th and 12th ask for their own details.
        for (final e in _entries.where((e) => eduNeedsDetails(e.label))) ...[
          const SizedBox(height: 14),
          Text(
            e.label,
            style: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          _input(e, 'school', 'pf_edu_school', e.school, (v) => e.school = v),
          _input(e, 'marks', 'pf_edu_marks', e.marks, (v) => e.marks = v),
          _input(e, 'year', 'pf_edu_year', e.year, (v) => e.year = v),
          if (!e.complete)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                tr(context, 'pf_edu_need'),
                style: const TextStyle(color: _amber, fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }
}

/// A list with tick boxes, for a detail that can hold several choices (education). Returns them joined by commas.
class _MultiSheet extends StatefulWidget {
  const _MultiSheet({required this.field, required this.selected});

  final PfField field;
  final String selected;

  @override
  State<_MultiSheet> createState() => _MultiSheetState();
}

class _MultiSheetState extends State<_MultiSheet> {
  late final Set<String> _picked = {
    for (final part in widget.selected.split(','))
      if (part.trim().isNotEmpty)
        widget.field.optionFor(part.trim())?.$1 ?? part.trim(),
  };

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                tr(context, f.labelKey),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final (value, key) in f.options!)
                    CheckboxListTile(
                      value: _picked.contains(value),
                      activeColor: AppColors.magenta,
                      title: Text(key == null ? value : tr(context, key)),
                      onChanged: (on) => setState(() {
                        if (on == true) {
                          _picked.add(value);
                        } else {
                          _picked.remove(value);
                        }
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GradientButton(
                label: tr(context, 'pf_done'),
                onPressed: () {
                  // In the order of the list, not the order they were ticked.
                  final ordered = [
                    for (final (value, _) in f.options!)
                      if (_picked.contains(value)) value,
                    ..._picked.where((p) => f.optionFor(p) == null),
                  ];
                  Navigator.of(context).pop(ordered.join(', '));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A searchable list of the options of a long choice (the designations).
class _OptionSheet extends StatefulWidget {
  const _OptionSheet({required this.field, required this.selected});

  final PfField field;
  final String selected;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  String _query = '';

  bool _isSelected(String value) =>
      widget.field.optionFor(widget.selected)?.$1 == value;

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    final searchable = f.options!.length > 12;
    final q = _query.trim().toLowerCase();
    final options = [
      for (final (value, key) in f.options!)
        if (q.isEmpty ||
            (key == null ? value : tr(context, key)).toLowerCase().contains(q))
          (value, key == null ? value : tr(context, key)),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: searchable ? MediaQuery.sizeOf(context).height * 0.75 : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                tr(context, f.labelKey),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (searchable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: tr(context, 'pf_search'),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.muted,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (value, label) in options)
                    ListTile(
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: _isSelected(value)
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _isSelected(value)
                              ? AppColors.magenta
                              : AppColors.ink,
                        ),
                      ),
                      trailing: _isSelected(value)
                          ? const Icon(Icons.check, color: AppColors.magenta)
                          : null,
                      onTap: () => Navigator.of(context).pop(value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The member's change requests and what the admin decided (the admin decides in the admin console).
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
                  // The profile photo is not a form field: the request carries the id of the new picture.
                  Text(
                    tr(
                      context,
                      r.fieldId == 'photo'
                          ? 'me2_photo'
                          : _field(r.fieldId).labelKey,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (r.fieldId != 'photo') ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_display(context, _field(r.fieldId), r.oldValue)}  →  ${_display(context, _field(r.fieldId), r.newValue)}',
                      style: const TextStyle(
                        color: Color(0xFF55576F),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
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
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
