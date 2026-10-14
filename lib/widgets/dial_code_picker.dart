import 'package:flutter/material.dart';

import '../data/dial_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'flag.dart';

/// Country-code field: shows the flag and dial code; tapping it opens a
/// searchable list of every country with its flag and code.
class DialCodePicker extends StatefulWidget {
  const DialCodePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.fill = AppColors.tint,
    this.height = 52,
  });

  final DialCountry value;
  final ValueChanged<DialCountry> onChanged;
  final Color fill;
  final double height;

  @override
  State<DialCodePicker> createState() => _DialCodePickerState();
}

class _DialCodePickerState extends State<DialCodePicker> {
  @override
  void initState() {
    super.initState();
    // Fetch the full country list once; the short list is used until then.
    DialData.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _open() async {
    final picked = await showModalBottomSheet<DialCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DialSheet(selected: widget.value),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _open,
    child: Container(
      height: widget.height,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: widget.fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountryFlag(widget.value.code),
          const SizedBox(width: 8),
          Text(
            widget.value.dial,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _DialSheet extends StatefulWidget {
  const _DialSheet({required this.selected});

  final DialCountry selected;

  @override
  State<_DialSheet> createState() => _DialSheetState();
}

class _DialSheetState extends State<_DialSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final all = DialData.countries;
    final shown = q.isEmpty
        ? all
        : all
              .where(
                (c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.dial.contains(q.replaceAll('+', '')) &&
                        q.replaceAll('+', '').isNotEmpty,
              )
              .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text(
              tr(context, 'dial_title'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _q = v),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: tr(context, 'reg_search'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        tr(context, 'reg_no_results'),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final c = shown[i];
                        return ListTile(
                          dense: true,
                          leading: CountryFlag(c.code, width: 28),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.dial,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (c.code == widget.selected.code)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.magenta,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
