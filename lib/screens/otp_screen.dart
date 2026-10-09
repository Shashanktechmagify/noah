import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'main_shell.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

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

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _error = false));
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 24;
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

  void _verify() {
    if (_controller.text != _demoCode) {
      setState(() => _error = true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    final timerText = '0:${_seconds.toString().padLeft(2, '0')}';
    return AuthScaffold(
      icon: Icons.lock_outline,
      title: tr(context, 'enter_code'),
      subtitle: tr(context, 'sent_to', args: {'phone': widget.phone}),
      headerHeight: 250,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) {
                  final filled = i < code.length;
                  final active = i == code.length;
                  return GestureDetector(
                    onTap: _focus.requestFocus,
                    child: Container(
                      width: 62,
                      height: 62,
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
                            fontSize: 24, fontWeight: FontWeight.w800),
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
                      LengthLimitingTextInputFormatter(4),
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
            onPressed: code.length == 4 ? _verify : null,
          ),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(tr(context, 'bad_code'),
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          const SizedBox(height: 18),
          if (_seconds > 0)
            Text(tr(context, 'resend_in', args: {'time': timerText}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5))
          else
            GestureDetector(
              onTap: () => setState(_startTimer),
              child: Text(tr(context, 'resend_code'),
                  style: const TextStyle(
                      color: AppColors.magenta,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 8),
          Text(tr(context, 'demo_code'),
              style: const TextStyle(
                  color: Color(0xFF555770),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(tr(context, 'change_number'),
                style: const TextStyle(
                    color: AppColors.magenta,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
