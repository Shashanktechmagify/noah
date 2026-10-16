import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/language_dropdown.dart';
import 'registration/registration_router.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.dial,
    this.number,
    this.otpLength = 4,
    this.resendSeconds = 24,
    this.devOtp,
  });

  final String phone;

  /// Set when the code was sent by the real API (otherwise the demo code is used).
  final String? dial;
  final String? number;
  final int otpLength;
  final int resendSeconds;

  /// The code the server echoes back while testing (OTP_DEV_ECHO).
  final String? devOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _demoCode = '4821';
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 24;
  bool _error = false;
  bool _busy = false;
  String? _message;

  bool get _live => widget.dial != null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(
      () => setState(() {
        _error = false;
        _message = null;
      }),
    );
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = widget.resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) t.cancel();
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_live) {
      if (_controller.text != _demoCode) {
        setState(() => _error = true);
        return;
      }
      routeAfterOtp(context, widget.phone);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await api.verifyOtp(
        widget.dial!,
        widget.number!,
        _controller.text,
      );
      if (!mounted) return;
      await routeAfterServer(context, widget.phone, r.next);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = e.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (!_live) {
      setState(_startTimer);
      return;
    }
    try {
      final sent = await api.sendOtp(widget.dial!, widget.number!);
      if (!mounted) return;
      _controller.clear();
      setState(_startTimer);
      if (sent.devOtp != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Test code: ${sent.devOtp}')));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    final len = _live ? widget.otpLength : 4;
    final timerText = '0:${_seconds.toString().padLeft(2, '0')}';
    return AuthScaffold(
      icon: Icons.lock_outline,
      title: tr(context, 'enter_code'),
      subtitle: tr(context, 'sent_to', args: {'phone': widget.phone}),
      headerHeight: 290,
      // Leave room for the back button on the left of the strip.
      topRight: const LanguageDropdown(),
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(len, (i) {
                  final filled = i < code.length;
                  final active = i == code.length;
                  return GestureDetector(
                    onTap: _focus.requestFocus,
                    child: Container(
                      width: len > 4 ? 46 : 62,
                      height: len > 4 ? 54 : 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _error
                              ? Colors.redAccent
                              : active || filled
                              ? AppColors.magenta
                              : AppColors.border,
                          width: active ? 1.8 : 1,
                        ),
                      ),
                      child: Text(
                        filled ? code[i] : '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Invisible field captures the keyboard input.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(len),
                    ],
                    showCursor: false,
                    enableInteractiveSelection: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: tr(context, 'verify'),
            onPressed: code.length == len && !_busy ? _verify : null,
          ),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _message ?? tr(context, 'bad_code'),
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 18),
          if (_seconds > 0)
            Text(
              tr(context, 'resend_in', args: {'time': timerText}),
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
          const SizedBox(height: 8),
          if (!_live || widget.devOtp != null)
            Text(
              _live ? 'Test code: ${widget.devOtp}' : tr(context, 'demo_code'),
              style: const TextStyle(
                color: Color(0xFF555770),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              tr(context, 'change_number'),
              style: const TextStyle(
                color: AppColors.magenta,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
