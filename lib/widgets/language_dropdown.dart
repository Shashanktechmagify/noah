import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Language picker for the purple auth headers: a transparent pill with a globe icon showing the
/// current language. Tapping it opens a popup to choose from all languages.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: GestureDetector(
          onTap: () => showLanguageDialog(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            // Transparent so it sits on the purple header.
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  locale.lang.native,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Choose your language" popup listing every supported language.
Future<void> showLanguageDialog(BuildContext context) {
  final locale = AppLocale.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialog) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(dialog, 'lang_choose'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final lang in AppLang.values)
              ListTile(
                onTap: () {
                  Navigator.of(dialog).pop();
                  locale.value = lang;
                },
                title: Text(
                  lang.native,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: lang == AppLang.en
                    ? null
                    : Text(
                        lang.english,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                trailing: lang == locale.lang
                    ? const Icon(Icons.check_circle, color: AppColors.magenta)
                    : const Icon(
                        Icons.radio_button_unchecked,
                        color: AppColors.border,
                      ),
              ),
          ],
        ),
      ),
    ),
  );
}
