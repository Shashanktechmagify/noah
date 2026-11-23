import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

/// Switches the language of the whole app (and of the daily messages, prayers and confessions, where the office has them).
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  /// The native names of the languages the office translates its content into; null until known (or offline).
  List<String>? _translated;

  @override
  void initState() {
    super.initState();
    _loadTranslated();
  }

  Future<void> _loadTranslated() async {
    if (!liveApi || !api.signedIn) return;
    try {
      final d = await api.contentLanguages();
      final names = [
        for (final l in (d['languages'] as List?) ?? const [])
          if (l is Map && '${l['native'] ?? ''}'.isNotEmpty) '${l['native']}',
      ];
      if (mounted) setState(() => _translated = names);
    } on ApiException {
      // Offline: the note is simply not shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return SubPage(
      title: tr(context, 'me_language'),
      subtitle: tr(context, 'lang_sub'),
      children: [
        WhiteCard(
          child: Column(
            children: [
              for (final (i, lang) in AppLang.values.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => locale.choose(lang),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        lang == locale.lang
                            ? const IconTile(icon: Icons.check)
                            : Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.tint,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.language,
                                  color: AppColors.muted,
                                  size: 21,
                                ),
                              ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            lang == AppLang.en
                                ? lang.native
                                : '${lang.native} · ${lang.english}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (lang == locale.lang)
                          StatusPill(
                            text: tr(context, 'lang_current'),
                            background: StatusPill.booked.$1,
                            foreground: StatusPill.booked.$2,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_translated != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              _translated!.isEmpty
                  ? tr(context, 'lang_content_none')
                  : tr(
                      context,
                      'lang_content_note',
                      args: {'langs': _translated!.join(', ')},
                    ),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(
            tr(context, 'lang_note'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
