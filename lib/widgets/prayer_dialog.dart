import 'package:flutter/material.dart';

import '../data/manna_data.dart';
import '../data/prayer_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'auth_scaffold.dart' show GradientButton;

/// Popup to add a prayer request. Pass [manna] when it is written from a Daily
/// Manna reading so the request is tied to it.
Future<void> showPrayerDialog(BuildContext context, {Manna? manna}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _PrayerDialog(manna: manna),
    );

class _PrayerDialog extends StatefulWidget {
  const _PrayerDialog({this.manna});

  final Manna? manna;

  @override
  State<_PrayerDialog> createState() => _PrayerDialogState();
}

class _PrayerDialogState extends State<_PrayerDialog> {
  final _text = TextEditingController();
  String _category = kPrayerCategories.first;

  /// On: everyone sees it. Off (default): prayer warriors only.
  bool _everyone = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    // Backend: POST the request here. `everyone == false` must be visible to
    // the prayer warriors group only.
    prayer.add(
      categoryKey: _category,
      text: _text.text,
      anonymous: false,
      everyone: _everyone,
      mannaTitleKey: widget.manna?.titleKey,
    );
    final messenger = ScaffoldMessenger.of(context);
    final message = tr(context, 'pr_sent');
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
      ),
    ),
  );

  Widget _radio({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.magenta : AppColors.muted,
              width: 1.6,
            ),
          ),
          child: selected
              ? Center(
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: AppColors.magenta,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final manna = widget.manna;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'pr_new'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            if (manna != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      size: 18,
                      color: AppColors.magenta,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tr(context, 'pr_for_manna')}: '
                        '${tr(context, manna.titleKey)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.magenta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _label(tr(context, 'pr_category')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kPrayerCategories)
                  GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: c == _category
                            ? AppColors.buttonGradient
                            : null,
                        color: c == _category ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: c == _category
                              ? AppColors.magenta
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tr(context, c),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c == _category ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label(tr(context, 'pr_details')),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 6,
              maxLength: 300, // keeps requests short for the prayer team
              decoration: InputDecoration(
                hintText: tr(context, 'pr_hint'),
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _label(tr(context, 'pr_who')),
            _radio(
              selected: !_everyone,
              title: tr(context, 'pr_opt_warriors'),
              subtitle: tr(context, 'pr_opt_warriors_sub'),
              onTap: () => setState(() => _everyone = false),
            ),
            const SizedBox(height: 10),
            _radio(
              selected: _everyone,
              title: tr(context, 'pr_opt_everyone'),
              subtitle: tr(context, 'pr_opt_everyone_sub'),
              onTap: () => setState(() => _everyone = true),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: tr(context, 'pr_submit'),
              onPressed: _text.text.trim().isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
