import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/live_session.dart';
import '../../data/registration_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/hex_pattern.dart';
import '../entry_screen.dart';
import '../registration/registration_router.dart';

/// A child's registration is with the office. The news goes to the parent's phone (and to this one, while it is open);
/// the child can also check here.
class ChildStatusScreen extends StatefulWidget {
  const ChildStatusScreen({super.key});

  @override
  State<ChildStatusScreen> createState() => _ChildStatusScreenState();
}

class _ChildStatusScreenState extends State<ChildStatusScreen> {
  bool _checking = false;
  String? _note;

  String get _name => registration.firstName;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _note = null;
    });
    try {
      final me = await api.me();
      if (!mounted) return;
      final next = '${me['next']}';
      if (next == 'home' || next == 'childRegistration') {
        await routeAfterServer(context, registration.fullName, next);
      } else {
        setState(() => _note = tr(context, 'child_still'));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout() async {
    await endLiveSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EntryScreen()),
      (_) => false,
    );
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
            padding: EdgeInsets.fromLTRB(24, top + 24, 24, 30),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Stack(
              children: [
                const Positioned.fill(child: HexPattern()),
                Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.hourglass_top,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr(context, 'child_status_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              children: [
                Text(
                  tr(context, 'child_status_sub', args: {'name': _name}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: _checking ? '...' : tr(context, 'child_check'),
                  onPressed: _checking ? null : _check,
                ),
                if (_note != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _note!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
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
    );
  }
}
