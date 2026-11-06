import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/registration_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rich_html.dart' show openImageProviderViewer;
import 'registration_widgets.dart';
import 'uploads.dart';

/// Step 3, below the main ID proof: further documents. Any two, any three: another ID (with its number), a
/// salary slip, a qualification certificate or a marriage certificate.
class OtherDocuments extends StatefulWidget {
  const OtherDocuments({super.key});

  @override
  State<OtherDocuments> createState() => _OtherDocumentsState();
}

class _OtherDocumentsState extends State<OtherDocuments> {
  @override
  void initState() {
    super.initState();
    registration.addListener(_tick);
  }

  @override
  void dispose() {
    registration.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  /// The kinds of document still to pick from: every ID except the main one and those already added, and the
  /// other documents not yet added.
  List<String> _available() {
    final r = registration;
    final used = {
      if (r.idType != null) r.idType!,
      for (final d in r.documents) d.type,
    };
    return [
      for (final t in idTypesFor(r.country))
        if (!used.contains(t.$1)) t.$1,
      for (final t in kOtherDocTypes)
        if (!used.contains(t.$1)) t.$1,
    ];
  }

  Future<void> _add() async {
    final types = _available();
    if (types.isEmpty) return;
    final doc = await showModalBottomSheet<RegDocument>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddDocumentSheet(types: types),
    );
    if (doc == null) return;
    registration.documents.add(doc);
    registration.touch();
  }

  Future<void> _view(RegDocument d) async {
    final isPdf = (d.fileName ?? '').toLowerCase().endsWith('.pdf');
    final path = d.path;
    if (isPdf) return _noPreview();
    if (path != null && File(path).existsSync()) {
      // Read the file now, so a replaced picture never shows the old one from the image cache.
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      openImageProviderViewer(context, MemoryImage(bytes));
    } else if (d.fileId != null) {
      openImageProviderViewer(
        context,
        NetworkImage(api.fileUrl(d.fileId!), headers: api.authHeaders),
      );
    } else {
      _noPreview();
    }
  }

  void _noPreview() => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(tr(context, 'pf_doc_nopreview'))));

  @override
  Widget build(BuildContext context) {
    final r = registration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Text(
          tr(context, 'doc_other_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          tr(context, 'doc_other_hint'),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        for (final d in r.documents)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F4EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E9D5B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFF1F8A4C)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, docLabelKey(d.type)),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          [
                            if (d.isId && d.number.trim().isNotEmpty) d.number,
                            d.fileName ?? '',
                          ].where((p) => p.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _view(d),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 12),
                      child: Text(
                        tr(context, 'reg_view'),
                        style: const TextStyle(
                          color: AppColors.magenta,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      r.documents.remove(d);
                      r.touch();
                    },
                    child: Text(
                      tr(context, 'doc_remove'),
                      style: const TextStyle(
                        color: Color(0xFFD6334B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_available().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DashedBox(
              height: 52,
              onTap: _add,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.magenta, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    tr(context, 'doc_add'),
                    style: const TextStyle(
                      color: AppColors.magenta,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pick the kind of document, type its number when it is an ID, choose the file, then add it.
class _AddDocumentSheet extends StatefulWidget {
  const _AddDocumentSheet({required this.types});

  final List<String> types;

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  String? _type;
  final _number = TextEditingController();
  String? _name;
  String? _path;
  String? _error;

  bool get _isId => _type != null && kIdTypes.any((t) => t.$1 == _type);

  bool get _ready =>
      _type != null &&
      _path != null &&
      (!_isId || idNumberError(_type, _number.text) == null);

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final picked = await pickDocument(context);
    if (picked == null || !mounted) return;
    setState(() {
      _error = picked.errorKey == null ? null : tr(context, picked.errorKey!);
      if (picked.ok) {
        _name = picked.name;
        _path = picked.path;
      }
    });
  }

  List<TextInputFormatter> get _formatters => switch (_type) {
    'aadhaar' || 'emirates' => [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s-]')),
      LengthLimitingTextInputFormatter(20),
    ],
    _ => [
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s-]')),
      LengthLimitingTextInputFormatter(24),
      TextInputFormatter.withFunction(
        (old, v) => v.copyWith(text: v.text.toUpperCase()),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final hint = kIdTypes
        .where((t) => t.$1 == _type)
        .map((t) => t.$3)
        .firstOrNull;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'doc_add_title'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              tr(context, 'doc_pick_type'),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in widget.types)
                  GestureDetector(
                    onTap: () => setState(() {
                      _type = t;
                      _number.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: t == _type ? AppColors.tint : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: t == _type
                              ? AppColors.magenta
                              : AppColors.border,
                          width: t == _type ? 1.6 : 1,
                        ),
                      ),
                      child: Text(
                        tr(context, docLabelKey(t)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t == _type ? AppColors.magenta : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_isId) ...[
              const SizedBox(height: 14),
              RegLabel(
                tr(
                  context,
                  'reg_id_number',
                  args: {'id': tr(context, docLabelKey(_type!))},
                ),
                required: true,
              ),
              RegInput(
                controller: _number,
                hint: hint ?? '',
                keyboardType: _type == 'aadhaar' || _type == 'emirates'
                    ? TextInputType.number
                    : TextInputType.text,
                formatters: _formatters,
                textCapitalization: TextCapitalization.characters,
                error: _number.text.trim().isEmpty
                    ? null
                    : (idNumberError(_type, _number.text) == null
                          ? null
                          : tr(context, idNumberError(_type, _number.text)!)),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_type != null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _choose,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.magenta),
                  ),
                  child: Text(
                    _name ?? tr(context, 'doc_choose_file'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.magenta,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_error != null) RegError(_error!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.magenta,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _ready
                    ? () => Navigator.of(context).pop(
                        RegDocument(
                          type: _type!,
                          number: _isId ? _number.text.trim() : '',
                          fileName: _name,
                          path: _path,
                        ),
                      )
                    : null,
                child: Text(
                  tr(context, 'doc_save'),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
