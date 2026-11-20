import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/live_session.dart';
import '../../data/registration_data.dart';
import '../../data/registration_sync.dart' show describeApiError;
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/hex_pattern.dart';
import '../../widgets/rich_html.dart' show openImageProviderViewer;
import '../entry_screen.dart';
import '../registration/registration_widgets.dart';
import '../registration/uploads.dart';
import 'child_list_screen.dart';
import 'child_status_screen.dart';

/// A child's registration: the name, date of birth and gender come from what the parent gave the office; the child
/// adds a photo, an email (the parent's is offered) and an Aadhaar (number and picture).
class ChildRegistrationScreen extends StatefulWidget {
  const ChildRegistrationScreen({super.key});

  @override
  State<ChildRegistrationScreen> createState() =>
      _ChildRegistrationScreenState();
}

class _ChildRegistrationScreenState extends State<ChildRegistrationScreen> {
  final r = registration;
  late final _email = TextEditingController(text: r.email);
  late final _aadhaar = TextEditingController(
    text: _group(r.idType == 'aadhaar' ? r.idNumber : ''),
  );

  // What was picked on this phone; what the server already holds is shown until then.
  String? _photoPath, _photoName, _idPath, _idName;
  String? _error, _photoError, _idError;
  bool _sending = false;
  bool _tried = false;

  static String _group(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) out.write(' ');
      out.write(d[i]);
    }
    return out.toString();
  }

  bool get _hasPhoto => _photoPath != null || r.photoFileId != null;
  bool get _hasId => _idPath != null || r.idProofFileId != null;
  String get _aadhaarDigits => _aadhaar.text.replaceAll(' ', '');

  String? get _emailErr => _tried && emailError(_email.text) != null
      ? tr(context, 'reg_err_email')
      : null;
  String? get _aadhaarErr {
    if (!_tried) return null;
    final k = idNumberError('aadhaar', _aadhaarDigits);
    return k == null ? null : tr(context, k);
  }

  @override
  void dispose() {
    _email.dispose();
    _aadhaar.dispose();
    super.dispose();
  }

  String get _fullName => [
    r.firstName,
    r.middleName,
    r.lastName,
  ].where((p) => p.trim().isNotEmpty).join(' ');

  String _dobText() {
    final d = r.dob;
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickPhoto() async {
    final p = await pickPhoto(context);
    if (p == null || !mounted) return;
    setState(() {
      _photoError = p.errorKey == null ? null : tr(context, p.errorKey!);
      if (p.ok) {
        _photoPath = p.path;
        _photoName = p.name;
      }
    });
  }

  Future<void> _pickId() async {
    final p = await pickDocument(context);
    if (p == null || !mounted) return;
    setState(() {
      _idError = p.errorKey == null ? null : tr(context, p.errorKey!);
      if (p.ok) {
        _idPath = p.path;
        _idName = p.name;
      }
    });
  }

  Future<void> _viewId() async {
    final path = _idPath;
    final name = (_idName ?? '').toLowerCase();
    if (name.endsWith('.pdf')) return;
    if (path != null && File(path).existsSync()) {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      openImageProviderViewer(context, MemoryImage(bytes));
    } else if (r.idProofFileId != null) {
      openImageProviderViewer(
        context,
        NetworkImage(api.fileUrl(r.idProofFileId!), headers: api.authHeaders),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (emailError(_email.text) != null ||
        idNumberError('aadhaar', _aadhaarDigits) != null ||
        !_hasPhoto ||
        !_hasId) {
      setState(() => _error = tr(context, 'child_reg_missing'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      var photoId = r.photoFileId;
      var idId = r.idProofFileId;
      if (_photoPath != null) {
        photoId = (await api.uploadFile(
          'photo',
          _photoPath!,
          name: _photoName,
        )).id;
      }
      if (_idPath != null) {
        idId = (await api.uploadFile('idProof', _idPath!, name: _idName)).id;
      }
      await api.saveRegistration({
        'email': _email.text.trim().toLowerCase(),
        'idType': 'aadhaar',
        'idNumber': _aadhaarDigits,
        'idProofFileId': idId,
        'photoFileId': photoId,
      });
      await api.submitRegistration();
      r.complete();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChildStatusScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = describeApiError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Back: leaves the child and returns to the parent's list of children (the parent's own sign-in was kept).
  Future<void> _backToList() async {
    final parent = parentSession;
    await endLiveSession();
    if (!mounted) return;
    if (parent == null || parent.access.isEmpty) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EntryScreen()),
        (_) => false,
      );
      return;
    }
    api.restore(
      accessToken: parent.access,
      refreshToken: parent.refresh,
      roles: parent.roles,
    );
    parentSession = null;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChildListScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await endLiveSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EntryScreen()),
      (_) => false,
    );
  }

  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _photo() {
    final local = _photoPath != null && File(_photoPath!).existsSync();
    Widget content;
    if (local) {
      content = Image.file(File(_photoPath!), fit: BoxFit.cover);
    } else if (r.photoFileId != null) {
      content = Image.network(
        api.fileUrl(r.photoFileId!),
        headers: api.authHeaders,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person_outline, size: 64, color: AppColors.muted),
      );
    } else {
      content = const Icon(
        Icons.person_outline,
        size: 64,
        color: AppColors.muted,
      );
    }
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: 132,
        height: 132,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.tint,
          border: Border.all(
            color: _tried && !_hasPhoto
                ? const Color(0xFFD6334B)
                : AppColors.border,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox.expand(child: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToList();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(child: HexPattern()),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _backToList,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        tr(
                          context,
                          'child_reg_title',
                          args: {'name': r.firstName},
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(context, 'child_reg_sub'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  if (r.status == RegStatus.rejected && r.reviewNote.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEBD3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${tr(context, 'child_reg_fix')}\n\n${r.reviewNote}',
                        style: const TextStyle(
                          color: Color(0xFFC2620A),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _fact(tr(context, 'child_name'), _fullName),
                        _fact(tr(context, 'child_dob'), _dobText()),
                        _fact(tr(context, 'child_gender'), switch (r.gender) {
                          'male' => tr(context, 'child_male'),
                          'female' => tr(context, 'child_female'),
                          _ => tr(context, 'child_other'),
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(child: _photo()),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Text(
                        tr(
                          context,
                          _hasPhoto ? 'child_photo_change' : 'child_photo_add',
                        ),
                        style: const TextStyle(
                          color: AppColors.magenta,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                  if (_photoError != null) RegError(_photoError!),
                  if (_tried && !_hasPhoto && _photoError == null)
                    RegError(tr(context, 'child_photo_need')),
                  RegLabel(tr(context, 'child_email'), required: true),
                  RegInput(
                    controller: _email,
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    error: _emailErr,
                    onChanged: (_) => setState(() {}),
                  ),
                  RegLabel(tr(context, 'child_aadhaar'), required: true),
                  RegInput(
                    controller: _aadhaar,
                    hint: '2345 6789 0123',
                    keyboardType: TextInputType.number,
                    error: _aadhaarErr,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                      TextInputFormatter.withFunction((old, v) {
                        final t = _group(v.text);
                        return TextEditingValue(
                          text: t,
                          selection: TextSelection.collapsed(offset: t.length),
                        );
                      }),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  RegLabel(tr(context, 'child_aadhaar_doc'), required: true),
                  if (_idError != null) RegError(_idError!),
                  if (!_hasId)
                    DashedBox(
                      height: 100,
                      onTap: _pickId,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: AppColors.magenta),
                          Text(
                            tr(context, 'child_aadhaar_up'),
                            style: const TextStyle(
                              color: AppColors.magenta,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
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
                            child: Text(
                              _idName ?? tr(context, 'reg_uploaded'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _viewId,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
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
                            onTap: _pickId,
                            child: Text(
                              tr(context, 'reg_replace'),
                              style: const TextStyle(
                                color: AppColors.magenta,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    RegError(_error!),
                  ],
                  const SizedBox(height: 22),
                  GradientButton(
                    label: _sending ? '...' : tr(context, 'child_submit'),
                    onPressed: _sending ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _logout,
                      child: Text(tr(context, 'child_logout')),
                    ),
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
