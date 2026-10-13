import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show toast;
import 'sub_page.dart';

/// Shared folders and study material (demo content).
class DriveScreen extends StatelessWidget {
  const DriveScreen({super.key});

  static const _folders = [
    ('dr_f1', 142, '1.2 GB'),
    ('dr_f2', 68, '340 MB'),
    ('dr_f3', 37, '88 MB'),
    ('dr_f4', 14, '12 MB'),
  ];

  @override
  Widget build(BuildContext context) {
    // (file name, size, "when" built from a key + number)
    final files = [
      (
        'Foundations · lesson 8 notes.pdf',
        '2.1 MB',
        tr(context, 'manna_days_ago', args: {'n': '2'}),
      ),
      (
        'Marathi study notes · Sep.pdf',
        '4.8 MB',
        tr(context, 'manna_days_ago', args: {'n': '3'}),
      ),
      ('Cell register template.xlsx', '86 KB', tr(context, 'dr_week')),
    ];
    return SubPage(
      title: tr(context, 'me2_drive'),
      subtitle: tr(context, 'me2_drive_sub'),
      children: [
        SectionTitle(title: tr(context, 'dr_folders')),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              for (final f in _folders)
                GestureDetector(
                  onTap: () => toast(
                    context,
                    '${tr(context, f.$1)} · ${tr(context, 'coming_soon')}',
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA719C8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.folder_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(context, f.$1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tr(
                            context,
                            'dr_items',
                            args: {'n': '${f.$2}', 'size': f.$3},
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(title: tr(context, 'dr_recent')),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            children: [
              for (final (i, f) in files.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_outlined,
                          color: AppColors.muted,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$1,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${f.$2} · ${f.$3}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        // Real downloads come from the backend later.
                        onTap: () => toast(context, tr(context, 'dr_started')),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            tr(context, 'dr_get'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
