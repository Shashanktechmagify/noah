import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/dial_data.dart';
import '../../data/family_data.dart';
import '../../data/registration_data.dart' show idNumberError;
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/dial_code_picker.dart';
import '../../widgets/page_scaffold.dart';
import '../registration/uploads.dart';
import 'aadhaar_view_screen.dart';
import 'sub_page.dart';

/// From 15 the parents ask the office to make their child a member: the child's own mobile number and the Aadhaar (the
/// number and a picture of it, unless it was added with the child). The office approves; then the child logs in with the
/// number and gives the consent.
class MakeMemberScreen extends StatefulWidget {
  const MakeMemberScreen({super.key, required this.child});

  final FamilyPerson child;

  @override
  State<MakeMemberScreen> createState() => _MakeMemberScreenState();
}

class _MakeMemberScreenState extends State<MakeMemberScreen> {
  final _number = TextEditingController();
  final _aadhaar = TextEditingController();
  DialCountry _dial = DialData.fallback.first;
  PickedUpload? _doc;
  bool _sending = false;
  String? _error;

  FamilyPerson get _kid => widget.child;
  String get _firstName => _kid.name.split(' ').first;

  String get _digits => _number.text.replaceAll(RegExp(r'\D'), '');
  String get _aadhaarDigits => _aadhaar.text.replaceAll(RegExp(r'\D'), '');

  /// The number must have the length of its country (India: 10 digits starting with 6 to 9).
  String? get _numberError {
    if (_digits.isEmpty) return null;
    if (!_dial.validLength(_digits.length)) return 'reg_err_phone';
    if (_dial.dial == '+91' && !RegExp(r'^[6-9]').hasMatch(_digits)) {
      return 'reg_err_phone';
    }
    return null;
  }

  String? get _aadhaarError =>
      _aadhaarDigits.isEmpty ? null : idNumberError('aadhaar', _aadhaarDigits);

  bool get _valid =>
      _digits.isNotEmpty &&
      _numberError == null &&
      (_kid.aadhaarAdded ||
          (_aadhaarDigits.isNotEmpty && _aadhaarError == null && _doc != null));

  @override
  void initState() {
    super.initState();
    _number.addListener(() => setState(() {}));
    _aadhaar.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _number.dispose();
    _aadhaar.dispose();
    super.dispose();
  }

  Future<void> _pickDoc() async {
    final p = await pickDocument(context);
    if (p == null || !mounted) return;
    setState(() {
      _doc = p.ok ? p : null;
      _error = p.ok ? null : tr(context, p.errorKey!);
    });
  }

  Future<void> _send() async {
    if (_sending || !_valid) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      String? docId;
      if (_doc != null) {
        docId = (await api.uploadFile('idProof', _doc!.path!)).id;
      }
      await api.makeMember(
        _kid.kidId!,
        dial: _dial.dial,
        number: _digits,
        aadhaarNumber: _aadhaarDigits.isEmpty ? null : _aadhaarDigits,
        aadhaarFileId: docId,
      );
      await familyState.load();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(tr(d, 'mm_sent_title')),
          content: Text(tr(d, 'mm_sent')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(),
              child: Text(tr(d, 'fm_ok')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final args = {'name': _firstName};
    return SubPage(
      title: tr(context, 'mm_title', args: args),
      bandHeight: 84,
      children: [
        WhiteCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'mm_intro', args: args),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _label(tr(context, 'mm_number', args: args)),
              Row(
                children: [
                  DialCodePicker(
                    value: _dial,
                    fill: AppColors.surface,
                    onChanged: (c) => setState(() => _dial = c),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _number,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_dial.maxDigits),
                      ],
                      decoration: _deco('').copyWith(
                        errorText: _numberError == null
                            ? null
                            : tr(context, _numberError!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr(context, 'mm_number_note'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (_kid.aadhaarAdded)
                Text(
                  tr(context, 'mm_aadhaar_have'),
                  style: const TextStyle(
                    color: Color(0xFF1F8A4C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (_kid.aadhaarAdded)
                TextButton.icon(
                  onPressed: () => openAadhaar(context, _kid),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(tr(context, 'aadhaar_view')),
                )
              else ...[
                _label(tr(context, 'mm_aadhaar')),
                TextField(
                  controller: _aadhaar,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: _deco('2345 6789 0123').copyWith(
                    errorText: _aadhaarError == null
                        ? null
                        : tr(context, _aadhaarError!),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _sending ? null : _pickDoc,
                  icon: Icon(
                    _doc == null ? Icons.upload_file : Icons.check_circle,
                    size: 18,
                  ),
                  label: Text(
                    tr(
                      context,
                      _doc == null ? 'mm_aadhaar_doc' : 'add_child_aadhaar_up',
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFD6334B),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: _sending ? '...' : tr(context, 'mm_send'),
                onPressed: _valid && !_sending ? _send : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
