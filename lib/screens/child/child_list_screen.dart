import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/hex_pattern.dart';
import '../entry_screen.dart';
import '../registration/registration_router.dart';

/// One child as the server lists them for the signed-in parent.
class ChildInfo {
  ChildInfo({
    required this.kidId,
    required this.name,
    required this.firstName,
    required this.dob,
    required this.age,
    required this.state,
    required this.note,
    required this.photoFileId,
  });

  final String kidId;
  final String name;
  final String firstName;
  final String? dob;
  final int? age;

  /// `ready` (to register), `pending`, `approved` or `rejected`.
  final String state;
  final String note;
  final String? photoFileId;

  factory ChildInfo.fromJson(Map<String, dynamic> j) => ChildInfo(
    kidId: '${j['kidId']}',
    name: '${j['name']}',
    firstName: '${j['firstName'] ?? ''}',
    dob: j['dob'] == null ? null : '${j['dob']}',
    age: (j['age'] as num?)?.toInt(),
    state: '${j['state']}',
    note: '${j['note'] ?? ''}',
    photoFileId: j['photoFileId'] == null ? null : '${j['photoFileId']}',
  );
}

/// The parent's own sign-in, kept while the app works as one of their children, so Back from the child's registration
/// returns to the list of children.
({String access, String refresh, List<String> roles})? parentSession;

/// After a parent signs in from the Child section: their children, each with what can be done next (register, wait,
/// correct, or log in as the child).
class ChildListScreen extends StatefulWidget {
  const ChildListScreen({super.key});

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen> {
  List<ChildInfo>? _children;
  String? _error;
  String? _opening;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await api.children();
      if (!mounted) return;
      setState(() {
        _children = ((d['children'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ChildInfo.fromJson)
            .toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// The parent signed in only to choose a child: leaving ends that session.
  Future<void> _leave() async {
    await api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EntryScreen()),
      (_) => false,
    );
  }

  Future<void> _open(ChildInfo c) async {
    if (_opening != null) return;
    setState(() => _opening = c.kidId);
    try {
      parentSession = (
        access: api.accessToken ?? '',
        refresh: api.refreshToken ?? '',
        roles: List.of(api.roles),
      );
      final r = await api.openChildSession(c.kidId);
      if (!mounted) return;
      await routeAfterServer(context, c.name, r.next);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  String _initials(String name) => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  Widget _avatar(ChildInfo c) {
    final letters = Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFDEBD3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _initials(c.name),
        style: const TextStyle(
          color: Color(0xFFC2620A),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final id = c.photoFileId;
    if (id == null) return letters;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Image.network(
          api.mediaUrl(id),
          headers: api.authHeaders,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => letters,
        ),
      ),
    );
  }

  Widget _card(ChildInfo c) {
    final (label, key, enabled) = switch (c.state) {
      'approved' => ('child_btn_login', 'approved', true),
      'pending' => ('child_pending', 'pending', false),
      'rejected' => ('child_btn_fix', 'rejected', true),
      _ => ('child_btn_register', 'ready', true),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(c),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (c.age != null)
                      Text(
                        tr(context, 'fam_age', args: {'n': '${c.age}'}),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (key == 'rejected' && c.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEBD3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                c.note,
                style: const TextStyle(
                  color: Color(0xFFC2620A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (enabled)
            GradientButton(
              label: _opening == c.kidId ? '...' : tr(context, label),
              onPressed: _opening == null ? () => _open(c) : null,
            )
          else
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                tr(context, label),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final children = _children;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 26),
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
                        onTap: _leave,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(context, 'child_list_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(context, 'child_list_sub'),
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
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: _load,
                              child: Text(tr(context, 'child_try_again')),
                            ),
                            TextButton(
                              onPressed: _leave,
                              child: Text(tr(context, 'child_logout')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : children == null
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        children: [
                          if (children.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 8,
                              ),
                              child: Text(
                                tr(context, 'child_empty'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          for (final c in children) _card(c),
                          const SizedBox(height: 6),
                          Center(
                            child: TextButton(
                              onPressed: _leave,
                              child: Text(tr(context, 'child_logout')),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
