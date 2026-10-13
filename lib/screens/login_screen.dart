import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/flag.dart';
import 'otp_screen.dart';

class _Country {
  const _Country(this.name, this.dial, this.digits, this.code);

  final String name;
  final String dial;

  /// ISO country code, used to draw the flag.
  final String code;

  /// Digits expected in the national number.
  final int digits;

  bool get isIndia => dial == '+91';
}

const _countries = [
  _Country('India', '+91', 10, 'IN'),
  _Country('United States', '+1', 10, 'US'),
  _Country('United Kingdom', '+44', 10, 'GB'),
  _Country('UAE', '+971', 9, 'AE'),
  _Country('Singapore', '+65', 8, 'SG'),
  _Country('Australia', '+61', 9, 'AU'),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController(text: '98765 43210');
  _Country _country = _countries.first;

  bool get _valid =>
      _controller.text.replaceAll(' ', '').length == _country.digits;

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

  void _pickCountry(_Country c) {
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
      subtitle: tr(context, 'welcome_sub'),
      headerHeight: 312,
      topRight: const LanguageDropdown(),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Badge(
            icon: Icons.verified_user_outlined,
            label: tr(context, 'badge_aadhaar'),
          ),
          _Badge(icon: Icons.lock_outline, label: tr(context, 'badge_data')),
        ],
      ),
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
              Container(
                height: 52,
                padding: const EdgeInsets.only(left: 14, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: PopupMenuButton<_Country>(
                  tooltip: '',
                  position: PopupMenuPosition.under,
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: _pickCountry,
                  itemBuilder: (_) => [
                    for (final c in _countries)
                      PopupMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Flag(c.code),
                            const SizedBox(width: 10),
                            Text(
                              '${c.name}  ${c.dial}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // Closed state: flag and dial code.
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flag(_country.code),
                      const SizedBox(width: 8),
                      Text(
                        _country.dial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
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
                        maxDigits: _country.digits,
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
          const SizedBox(height: 18),
          Center(
            child: Text(
              tr(context, 'otp_note'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              tr(context, 'demo_note'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
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
