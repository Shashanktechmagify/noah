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

/// Asks, then takes the Aadhaar (number and picture) of the child away. True when it was removed.
Future<bool> confirmRemoveAadhaar(
  BuildContext context,
  FamilyPerson kid,
) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(tr(d, 'aadhaar_remove')),
      content: Text(tr(d, 'aadhaar_remove_q')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(d).pop(false),
          child: Text(tr(d, 'add_child_cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(d).pop(true),
          child: Text(
            tr(d, 'aadhaar_remove'),
            style: const TextStyle(color: Color(0xFFD6334B)),
          ),
        ),
      ],
    ),
  );
  if (yes != true || kid.kidId == null) return false;
  try {
    await api.removeChildAadhaar(kid.kidId!);
    await familyState.load();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
}

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
            // Until the office is deciding the parents can take it away and give it again.
            if (kid.memberState == 'none' || kid.memberState == 'rejected') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (await confirmRemoveAadhaar(context, kid)) {
                    navigator.pop();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD6334B),
                  side: const BorderSide(color: Color(0xFFD6334B)),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(tr(context, 'aadhaar_remove')),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
