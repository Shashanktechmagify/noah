import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (tr(context, 'chip_community'), tr(context, 'tm_community_b')),
      (tr(context, 'tm_data'), tr(context, 'tm_data_b')),
      (tr(context, 'tile_giving'), tr(context, 'tm_giving_b')),
    ];
    return SubPage(
      title: tr(context, 'me2_terms'),
      subtitle: tr(context, 'tm_version', args: {'v': '1.0'}),
      children: [
        WhiteCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            children: [
              for (final (i, s) in sections.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.$2,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(
            tr(context, 'tm_legal'),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
