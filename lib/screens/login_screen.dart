import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/language_dropdown.dart';
import '../data/dial_data.dart';
import '../widgets/dial_code_picker.dart';
import 'me/terms_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController(text: '98765 43210');
  DialCountry _country = DialData.fallback.first;

  bool get _valid =>
      _country.validLength(_controller.text.replaceAll(' ', '').length);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickCountry(DialCountry c) {
    setState(() => _country = c);
    // The demo number only makes sense for India.
    _controller.text = c.isIndia ? '98765 43210' : '';
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OtpScreen(phone: '${_country.dial} ${_controller.text}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      icon: Icons.home_outlined,
      title: tr(context, 'welcome_title'),
      subtitle: tr(context, ''),
      headerHeight: 312,
      topRight: const LanguageDropdown(),
      // footer: Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //   children: [
      //     _Badge(
      //       icon: Icons.verified_user_outlined,
      //       label: tr(context, 'badge_aadhaar'),
      //     ),
      //     _Badge(icon: Icons.lock_outline, label: tr(context, 'badge_data')),
      //   ],
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'mobile_number'),
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: spacing(context, 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              DialCodePicker(value: _country, onChanged: _pickCountry),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      _PhoneFormatter(
                        maxDigits: _country.maxDigits,
                        group: _country.isIndia,
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: _country.isIndia ? '00000 00000' : '0' * 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: tr(context, 'continue'),
            onPressed: _valid ? _continue : null,
          ),
          const SizedBox(height: 16),
          const _TermsNote(),
          const SizedBox(height: 18),
          // Center(
          //   child: Text(
          //     tr(context, 'otp_note'),
          //     textAlign: TextAlign.center,
          //     style: const TextStyle(
          //       color: AppColors.muted,
          //       fontSize: 12,
          //       height: 1.4,
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Center(
          //   child: Text(
          //     tr(context, 'demo_note'),
          //     textAlign: TextAlign.center,
          //     style: const TextStyle(
          //       color: AppColors.muted,
          //       fontSize: 12,
          //       height: 1.4,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.magenta),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

/// Keeps only digits (up to [maxDigits]); Indian numbers are grouped as
/// "XXXXX XXXXX".
class _PhoneFormatter extends TextInputFormatter {
  _PhoneFormatter({required this.maxDigits, required this.group});

  final int maxDigits;
  final bool group;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > maxDigits) d = d.substring(0, maxDigits);
    final text = group && d.length > 5
        ? '${d.substring(0, 5)} ${d.substring(5)}'
        : d;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// "By continuing, you agree to our Terms & Conditions and Privacy Policy."
/// Both links open the terms page.
class _TermsNote extends StatefulWidget {
  const _TermsNote();

  @override
  State<_TermsNote> createState() => _TermsNoteState();
}

class _TermsNoteState extends State<_TermsNote> {
  late final _open = TapGestureRecognizer()..onTap = _showTerms;
  late final _open2 = TapGestureRecognizer()..onTap = _showTerms;

  void _showTerms() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const TermsScreen()));

  @override
  void dispose() {
    _open.dispose();
    _open2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      color: AppColors.magenta,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    final spans = <InlineSpan>[];
    tr(context, 'lg_terms').splitMapJoin(
      RegExp(r'\{[tp]\}'),
      onMatch: (m) {
        final isTerms = m[0] == '{t}';
        spans.add(
          TextSpan(
            text: tr(context, isTerms ? 'lg_terms_t' : 'lg_terms_p'),
            style: link,
            recognizer: isTerms ? _open : _open2,
          ),
        );
        return '';
      },
      onNonMatch: (t) {
        spans.add(TextSpan(text: t));
        return '';
      },
    );
    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12.5,
        height: 1.5,
      ),
    );
  }
}
