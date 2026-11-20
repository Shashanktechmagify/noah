import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/dial_data.dart';
import '../../data/live_session.dart';
import '../../data/registration_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/dial_code_picker.dart';
import '../../widgets/hex_pattern.dart';
import '../entry_screen.dart';

/// A child uses the parent's number and email until this age; from it the child can add a number of their own.
const kChildPhoneAge = 15;

/// The child (a child's account, old enough) can add their own mobile number.
bool childCanAddNumber() {
  if (!liveApi || !api.isChild) return false;
  final dob = registration.dob;
  if (dob == null) return false;
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age -= 1;
  }
  return age >= kChildPhoneAge;
}

/// A card for the Me page: "Add your mobile number".
class AddNumberCard extends StatelessWidget {
  const AddNumberCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEBD3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android, color: Color(0xFFC2620A), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'child_add_phone'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr(context, 'child_add_phone_card'),
                  style: const TextStyle(
                    color: Color(0xFFC2620A),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 15,
            color: Color(0xFFC2620A),
          ),
        ],
      ),
    ),
  );
}

/// The child adds their own mobile number: a code to the number, then the number is confirmed and the child is a member,
/// who logs in with it from Members.
class ChildPhoneScreen extends StatefulWidget {
  const ChildPhoneScreen({super.key});

  @override
  State<ChildPhoneScreen> createState() => _ChildPhoneScreenState();
}

class _ChildPhoneScreenState extends State<ChildPhoneScreen> {
  final _number = TextEditingController();
  final _code = TextEditingController();
  DialCountry _country = DialData.fallback.first;
  bool _sent = false;
  bool _busy = false;
  String? _error;
  String? _devOtp;

  @override
  void initState() {
    super.initState();
    _number.addListener(() => setState(() {}));
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _number.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _numberOk =>
      _country.validLength(_number.text.replaceAll(' ', '').length);

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await api.childPhoneCode(_country.dial, _number.text);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _devOtp = r.devOtp;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.childPhoneVerify(_country.dial, _number.text, _code.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            tr(dialog, 'child_phone_done_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: Text(tr(dialog, 'child_phone_done')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(
                tr(dialog, 'reg_ok'),
                style: const TextStyle(
                  color: AppColors.magenta,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
      // From now this is a member: sign out of the child account; they log in from Members with the new number.
      await endLiveSession();
      if (!mounted) return;
      await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EntryScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Stack(
              children: [
                const Positioned.fill(child: HexPattern()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr(context, 'child_add_phone'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, 'child_add_phone_sub'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              children: [
                Row(
                  children: [
                    DialCodePicker(
                      value: _country,
                      onChanged: _sent
                          ? (_) {}
                          : (c) => setState(() => _country = c),
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
                          controller: _number,
                          enabled: !_sent,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              _country.maxDigits,
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: '0' * (_country.isIndia ? 10 : 9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_sent)
                  GradientButton(
                    label: _busy ? '...' : tr(context, 'child_phone_send'),
                    onPressed: _numberOk && !_busy ? _send : null,
                  )
                else ...[
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: tr(context, 'child_phone_code'),
                        hintStyle: const TextStyle(
                          letterSpacing: 0,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (_devOtp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Test code: $_devOtp',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: _busy ? '...' : tr(context, 'child_phone_confirm'),
                    onPressed: _code.text.length >= 4 && !_busy
                        ? _confirm
                        : null,
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _sent = false;
                              _code.clear();
                              _error = null;
                            }),
                      child: Text(tr(context, 'child_phone_change')),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFD6334B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
