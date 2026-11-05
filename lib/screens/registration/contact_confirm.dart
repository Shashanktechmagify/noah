import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// The demo code (the app is not talking to a server).
const _demoCode = '4821';

/// Confirms an email address ([email]) or a mobile number ([dial] and [number]) with a one-time code sent to it.
/// Returns true when the right code was entered. The server keeps the contact only then.
Future<bool> confirmContact(
  BuildContext context, {
  String? email,
  String? dial,
  String? number,
}) async {
  OtpSent? sent;
  if (liveApi) {
    try {
      sent = await api.sendContactCode(
        email: email,
        dial: dial,
        number: number,
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CodeDialog(
      email: email,
      dial: dial,
      number: number,
      sent: sent,
      shownTo: sent?.sentTo ?? email ?? '$dial $number',
    ),
  );
  return ok == true;
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({
    required this.email,
    required this.dial,
    required this.number,
    required this.sent,
    required this.shownTo,
  });

  final String? email;
  final String? dial;
  final String? number;
  final OtpSent? sent;
  final String shownTo;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();
  Timer? _timer;
  late int _length = widget.sent?.otpLength ?? 4;
  late int _seconds = widget.sent?.resendAfter ?? 24;
  late String? _devOtp = widget.sent?.devOtp;
  late String? _mailError = widget.sent?.devMailError;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() => _error = null));
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) t.cancel();
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!liveApi) {
      if (_code.text == _demoCode) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = tr(context, 'bad_code'));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await api.verifyContact(
        _code.text,
        email: widget.email,
        dial: widget.dial,
        number: widget.number,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (!liveApi) {
      setState(() => _seconds = 24);
      _tick();
      return;
    }
    try {
      final sent = await api.sendContactCode(
        email: widget.email,
        dial: widget.dial,
        number: widget.number,
      );
      if (!mounted) return;
      _code.clear();
      setState(() {
        _length = sent.otpLength;
        _seconds = sent.resendAfter;
        _devOtp = sent.devOtp;
        _mailError = sent.devMailError;
      });
      _tick();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.email != null;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        tr(context, isEmail ? 'cc_title_email' : 'cc_title_mobile'),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'cc_sent', args: {'to': widget.shownTo}),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_length),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: '•' * _length,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 10),
          if (_seconds > 0)
            Text(
              tr(
                context,
                'resend_in',
                args: {'time': '0:${_seconds.toString().padLeft(2, '0')}'},
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            )
          else
            GestureDetector(
              onTap: _resend,
              child: Text(
                tr(context, 'resend_code'),
                style: const TextStyle(
                  color: AppColors.magenta,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (!liveApi || _devOtp != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                liveApi ? 'Test code: $_devOtp' : tr(context, 'demo_code'),
                style: const TextStyle(
                  color: Color(0xFF555770),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (liveApi && _mailError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Email not sent: $_mailError',
                style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(tr(context, 'pf_cancel')),
        ),
        TextButton(
          onPressed: _code.text.length == _length && !_busy ? _verify : null,
          child: Text(
            tr(context, 'cc_verify'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
