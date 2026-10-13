import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

/// Switches the language of the whole app.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

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
                  onTap: () => locale.value = lang,
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
