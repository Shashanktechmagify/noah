import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/family_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

/// Opens the Aadhaar that the parents gave for a child: the number and, when there is one, the picture.
void openAadhaar(BuildContext context, FamilyPerson kid) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AadhaarViewScreen(kid: kid)));

class AadhaarViewScreen extends StatelessWidget {
  const AadhaarViewScreen({super.key, required this.kid});

  final FamilyPerson kid;

  /// 2345 6789 0123
  String get _grouped => (kid.aadhaarNo ?? '').replaceAllMapped(
    RegExp(r'(\d{4})(?=\d)'),
    (m) => '${m[1]} ',
  );

  @override
  Widget build(BuildContext context) => SubPage(
    title: tr(
      context,
      'aadhaar_title',
      args: {'name': kid.name.split(' ').first},
    ),
    bandHeight: 84,
    children: [
      WhiteCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((kid.aadhaarNo ?? '').isNotEmpty) ...[
              Text(
                tr(context, 'aadhaar_number'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _grouped,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (kid.aadhaarFile && kid.kidId != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  child: Image.network(
                    api.childAadhaarUrl(kid.kidId!),
                    headers: api.authHeaders,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        tr(context, 'aadhaar_cannot'),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ),
              )
            else
              Text(
                tr(context, 'aadhaar_none'),
                style: const TextStyle(color: AppColors.muted),
              ),
          ],
        ),
      ),
    ],
  );
}
