import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// Six-segment progress bar; [step] (1-based) segments are filled.
class RegProgress extends StatelessWidget {
  const RegProgress({super.key, required this.step, this.total = 6});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 4,
            decoration: BoxDecoration(
              color: i < step ? AppColors.magenta : const Color(0xFFE3DDF1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Field caption: small, muted, with a red asterisk when required.
class RegLabel extends StatelessWidget {
  const RegLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.toUpperCase()),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFD6334B)),
            ),
        ],
      ),
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: spacing(context, 0.5),
      ),
    ),
  );
}

/// Rounded text input used across the registration steps.
class RegInput extends StatelessWidget {
  const RegInput({
    super.key,
    this.controller,
    this.focusNode,
    required this.hint,
    this.onChanged,
    this.keyboardType,
    this.formatters,
    this.textCapitalization = TextCapitalization.none,
    this.error,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization textCapitalization;

  /// Validation message shown under the field (red border).
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_box(), if (error != null) RegError(error!)],
  );

  Widget _box() => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: error == null ? AppColors.border : _errorRed),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
  );
}

const _errorRed = Color(0xFFD6334B);

/// Small red validation message.
class RegError extends StatelessWidget {
  const RegError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: _errorRed,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Single-choice pills (gender, marital status).
class RegChips extends StatelessWidget {
  const RegChips({
    super.key,
    required this.options,
    required this.value,
    required this.onSelect,
  });

  /// (id, label)
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final (id, label) in options)
        GestureDetector(
          onTap: () => onSelect(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: id == value ? AppColors.magenta : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: id == value ? AppColors.magenta : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: id == value ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
    ],
  );
}

/// A rounded rectangle with a dashed outline (upload and signature boxes).
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.height,
    this.onTap,
    this.color = const Color(0xFFC9BFE3),
  });

  final Widget child;
  final double? height;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: CustomPaint(
      painter: _DashedPainter(color),
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        child: child,
      ),
    ),
  );
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color;
}

/// A field that opens a searchable list (country, state, city).
class RegPicker extends StatelessWidget {
  const RegPicker({
    super.key,
    required this.value,
    required this.hint,
    required this.title,
    required this.items,
    required this.onSelect,
    this.enabled = true,
    this.loading = false,
  });

  final String value;
  final String hint;
  final String title;
  final List<String> items;
  final ValueChanged<String> onSelect;
  final bool enabled;
  final bool loading;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) =>
          _PickerSheet(title: title, items: items, value: value),
    );
    if (picked != null) onSelect(picked);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled && !loading && items.isNotEmpty
        ? () => _open(context)
        : null,
    child: Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF6F5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              loading ? '…' : (value.isEmpty ? hint : value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w600,
                color: value.isEmpty ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.ink),
        ],
      ),
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.value,
  });

  final String title;
  final List<String> items;
  final String value;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.items
        : widget.items.where((i) => i.toLowerCase().contains(q)).toList();
    final height = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text(
              widget.title,
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
                        autofocus: false,
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
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text(
                          shown[i],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: shown[i] == widget.value
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.magenta,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(shown[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
