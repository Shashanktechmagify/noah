import 'package:flutter/material.dart';

import '../../data/terms_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

/// Terms & Conditions: About, Privacy Policy, Terms of Service and Refund
/// Policy. The chips at the top jump to each part. The wording is the
/// ministry's own and is shown as supplied (English).
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _keys = {for (final p in kLegalParts) p.id: GlobalKey()};

  void _jump(String id) {
    final ctx = _keys[id]!.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(
    title: tr(context, 'me2_terms'),
    subtitle: tr(context, 'tm_version', args: {'v': kTermsVersion}),
    children: [
      // SizedBox(
      //   height: 42,
      //   child: ListView.separated(
      //     scrollDirection: Axis.horizontal,
      //     padding: const EdgeInsets.symmetric(horizontal: 16),
      //     itemCount: kLegalParts.length,
      //     separatorBuilder: (_, _) => const SizedBox(width: 10),
      //     itemBuilder: (_, i) => GestureDetector(
      //       onTap: () => _jump(kLegalParts[i].id),
      //       child: Container(
      //         alignment: Alignment.center,
      //         padding: const EdgeInsets.symmetric(horizontal: 18),
      //         decoration: BoxDecoration(
      //           color: Colors.white,
      //           borderRadius: BorderRadius.circular(21),
      //           border: Border.all(color: AppColors.magenta),
      //         ),
      //         child: Text(
      //           kLegalParts[i].title,
      //           style: const TextStyle(
      //             fontSize: 13.5,
      //             fontWeight: FontWeight.w700,
      //           ),
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      const SizedBox(height: 14),
      for (final part in kLegalParts) ...[
        WhiteCard(
          key: _keys[part.id],
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final b in part.blocks) _Block(block: b),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    ],
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.block});

  final LegalBlock block;

  static const _body = TextStyle(
    color: Color(0xFF55576F),
    fontSize: 13.5,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.heading != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              block.heading!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.magenta,
                letterSpacing: spacing(context, 0.4),
              ),
            ),
          ),
        for (final p in block.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(p, style: _body),
          ),
        for (final item in block.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 5, color: AppColors.magenta),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: _body)),
              ],
            ),
          ),
      ],
    ),
  );
}
