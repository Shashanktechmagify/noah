import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/registration_data.dart';
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
    this.leadingFor,
    this.searchable = true,
  });

  /// A widget shown before an item (e.g. a flag).
  final Widget? Function(String item)? leadingFor;
  final bool searchable;

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
      builder: (sheet) => _PickerSheet(
        title: title,
        items: items,
        value: value,
        leadingFor: leadingFor,
        searchable: searchable,
      ),
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
          if (leadingFor != null &&
              value.isNotEmpty &&
              leadingFor!(value) != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: leadingFor!(value),
            ),
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
    this.leadingFor,
    this.searchable = true,
  });

  final Widget? Function(String item)? leadingFor;
  final bool searchable;
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
    final height = widget.searchable
        ? MediaQuery.of(context).size.height * 0.75
        : (widget.items.length * 48.0 + 70).clamp(
            0.0,
            MediaQuery.of(context).size.height * 0.75,
          );
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
            if (!widget.searchable) const SizedBox(height: 8),
            if (widget.searchable)
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
                      const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.muted,
                      ),
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
                        leading: widget.leadingFor?.call(shown[i]),
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

/// "I, Mr … aged … years, resident of …" in [doc], with the member's own
/// name, age and place highlighted.
InlineSpan declarationIntro(
  AppLang doc, {
  TextStyle highlight = const TextStyle(fontWeight: FontWeight.w800),
}) {
  final r = registration;
  final values = {
    '{name}': r.displayName.isEmpty ? '………' : r.displayName,
    '{age}': r.age?.toString() ?? '……',
    '{place}': [r.city, r.country].where((e) => e.isNotEmpty).join(', '),
  };
  final spans = <InlineSpan>[];
  trIn(doc, 'reg_decl_intro').splitMapJoin(
    RegExp(r'\{(name|age|place)\}'),
    onMatch: (m) {
      spans.add(TextSpan(text: values[m[0]!], style: highlight));
      return '';
    },
    onNonMatch: (t) {
      spans.add(TextSpan(text: t));
      return '';
    },
  );
  return TextSpan(children: spans);
}

/// dd/mm/yyyy text for [d].
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Turns typed digits into dd/mm/yyyy as you type: 10092005 becomes 10/09/2005.
class DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 8 ? digits.substring(0, 8) : digits;
    final out = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 4) out.write('/');
      out.write(d[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Parses dd/mm/yyyy; null for anything incomplete or not a real date
/// (such as 31/02/2005).
DateTime? parseDate(String text) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
  if (m == null) return null;
  final day = int.parse(m[1]!);
  final month = int.parse(m[2]!);
  final year = int.parse(m[3]!);
  final d = DateTime(year, month, day);
  return d.day == day && d.month == month && d.year == year ? d : null;
}

/// A date you can type (slashes are added for you) or pick from a calendar.
/// [onChanged] gets the date, or null while it is incomplete or invalid.
class DateInputField extends StatefulWidget {
  const DateInputField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstYear = 1900,
    this.error,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final int firstYear;

  /// Extra message from the caller (e.g. "must be at least 18").
  final String? error;

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final _c = TextEditingController(
    text: widget.value == null ? '' : formatDate(widget.value!),
  );

  /// Typed text that is complete but not an acceptable date.
  bool get _badDate {
    if (_c.text.length < 10) return false;
    final d = parseDate(_c.text);
    return d == null || d.year < widget.firstYear || d.isAfter(DateTime.now());
  }

  @override
  void didUpdateWidget(DateInputField old) {
    super.didUpdateWidget(old);
    // The model changed from outside (e.g. the calendar): show it.
    final v = widget.value;
    if (v != null && parseDate(_c.text) != v) _c.text = formatDate(v);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _changed(String text) {
    final d = parseDate(text);
    final ok =
        d != null && d.year >= widget.firstYear && !d.isAfter(DateTime.now());
    setState(() {});
    widget.onChanged(ok ? d : null);
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      fieldHintText: 'dd/mm/yyyy',
      initialDate: widget.value ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(widget.firstYear),
      lastDate: now,
    );
    if (picked != null) {
      _c.text = formatDate(picked);
      _changed(_c.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _badDate ? tr(context, 'reg_err_date') : widget.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error == null ? AppColors.border : _errorRed,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  keyboardType: TextInputType.number,
                  inputFormatters: [DateSlashFormatter()],
                  onChanged: _changed,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'dd/mm/yyyy',
                    hintStyle: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _pick,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ],
          ),
        ),
        if (error != null) RegError(error),
      ],
    );
  }
}
