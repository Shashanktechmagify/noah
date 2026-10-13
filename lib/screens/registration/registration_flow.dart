import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/registration_data.dart';
import '../../data/world_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/language_dropdown.dart';
import '../events/events_widgets.dart' show fullDate;
import 'registration_video.dart';
import 'uploads.dart';
import 'registration_widgets.dart';

/// Error text for [key] once the member has typed something invalid.
String? _err(BuildContext context, String value, String? key) =>
    value.trim().isEmpty || key == null ? null : tr(context, key);

/// Rebuilds a step whenever [registration] changes. The steps are const, so
/// the parent rebuilding alone would never refresh selected chips or the
/// agree checkbox.
mixin _Live<T extends StatefulWidget> on State<T> {
  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    registration.addListener(_tick);
  }

  @override
  void dispose() {
    registration.removeListener(_tick);
    super.dispose();
  }
}

const _stepIcons = [
  Icons.person_outline,
  Icons.home_outlined,
  Icons.insert_drive_file_outlined,
  Icons.person_outline,
  Icons.check,
];

/// The six registration steps for a new member: details, address, ID proof,
/// photo, declaration and a video KYC.
class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  late int _step = widget.initialStep;

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _next() {
    // Accepting the declaration fixes the signing date.
    if (_step == 4) registration.sign();
    setState(() => _step++);
  }

  Widget _content(int step) => switch (step) {
    0 => const _DetailsStep(),
    1 => const _AddressStep(),
    2 => const _IdStep(),
    3 => const _PhotoStep(),
    4 => const _DeclarationStep(),
    _ => const VideoStep(),
  };

  @override
  Widget build(BuildContext context) {
    final last = _step == 5;
    return ListenableBuilder(
      listenable: registration,
      builder: (context, _) {
        final stepName = tr(context, 'reg_s${_step + 1}');
        return AuthScaffold(
          key: ValueKey(_step), // a new step starts scrolled to the top
          icon: last ? null : _stepIcons[_step],
          title: last ? '' : tr(context, 'reg_h${_step + 1}'),
          subtitle: last ? '' : tr(context, 'reg_h${_step + 1}s'),
          headerHeight: last ? 58 : 270,
          topRight: last ? null : const LanguageDropdown(),
          onBack: last ? null : _back,
          footer: last
              ? null
              : GradientButton(
                  label: tr(
                    context,
                    _step == 4 ? 'reg_continue_video' : 'continue',
                  ),
                  onPressed: registration.stepValid(_step) ? _next : null,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegProgress(step: _step + 1),
              const SizedBox(height: 14),
              Text(
                tr(
                  context,
                  'reg_step',
                  args: {'n': '${_step + 1}', 'name': stepName},
                ),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _content(_step),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 1: details
// ───────────────────────────────────────────────────────────────────────────

class _DetailsStep extends StatefulWidget {
  const _DetailsStep();

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> with _Live<_DetailsStep> {
  final _first = TextEditingController(text: registration.firstName);
  final _middle = TextEditingController(text: registration.middleName);
  final _last = TextEditingController(text: registration.lastName);
  final _email = TextEditingController(text: registration.email);
  final _ref = TextEditingController(text: registration.reference);

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _email, _ref]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          registration.dob ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      registration.dob = picked;
      registration.touch();
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final r = registration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegLabel(tr(context, 'reg_first'), required: true),
        RegInput(
          controller: _first,
          error: _err(context, r.firstName, nameError(r.firstName)),
          hint: tr(context, 'reg_first'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) {
            r.firstName = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_middle')),
        RegInput(
          controller: _middle,
          error: _err(
            context,
            r.middleName,
            nameError(r.middleName, required: false),
          ),
          hint: tr(context, 'reg_middle_ph'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) {
            r.middleName = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_last'), required: true),
        RegInput(
          controller: _last,
          error: _err(context, r.lastName, nameError(r.lastName)),
          hint: tr(context, 'reg_last'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) {
            r.lastName = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_email'), required: true),
        RegInput(
          controller: _email,
          error: _err(context, r.email, emailError(r.email)),
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) {
            r.email = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_gender'), required: true),
        RegChips(
          options: [
            ('male', tr(context, 'reg_male')),
            ('female', tr(context, 'reg_female')),
            ('other', tr(context, 'reg_other')),
          ],
          value: r.gender,
          onSelect: (v) {
            r.gender = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_dob'), required: true),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.dob == null ? 'dd-mm-yyyy' : _fmt(r.dob!),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: r.dob == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: r.dob == null ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
        ),
        if (dobError(r.dob) != null) RegError(tr(context, dobError(r.dob)!)),
        RegLabel(tr(context, 'reg_marital'), required: true),
        RegChips(
          options: [
            ('single', tr(context, 'reg_single')),
            ('married', tr(context, 'reg_married')),
            ('widow', tr(context, 'reg_widow')),
            ('widower', tr(context, 'reg_widower')),
            ('separated', tr(context, 'reg_separated')),
            ('divorced', tr(context, 'reg_divorced')),
          ],
          value: r.marital,
          onSelect: (v) {
            r.marital = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_ref')),
        RegInput(
          controller: _ref,
          error: _err(
            context,
            r.reference,
            nameError(r.reference, required: false),
          ),
          hint: tr(context, 'reg_ref_ph'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) {
            r.reference = v;
            r.touch();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            tr(context, 'reg_ref_help'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 2: address
// ───────────────────────────────────────────────────────────────────────────

class _AddressStep extends StatefulWidget {
  const _AddressStep();

  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep> with _Live<_AddressStep> {
  final _a1 = TextEditingController(text: registration.address1);
  final _a2 = TextEditingController(text: registration.address2);
  final _pin = TextEditingController(text: registration.pin);
  final _city = TextEditingController(text: registration.city);
  World? world = World.ready;

  @override
  void initState() {
    super.initState();
    if (world == null) {
      World.load().then((w) {
        if (mounted) setState(() => world = w);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_a1, _a2, _pin, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final states = world?.statesOf(r.country) ?? const <String>[];
    final cities = states.isEmpty
        ? const <String>[]
        : (world?.citiesOf(r.country, r.state) ?? const <String>[]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '* ',
                  style: TextStyle(color: Color(0xFFD6334B)),
                ),
                TextSpan(text: tr(context, 'reg_required')),
              ],
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
        RegLabel(tr(context, 'reg_addr1'), required: true),
        RegInput(
          controller: _a1,
          error: _err(context, r.address1, addressError(r.address1)),
          hint: tr(context, 'reg_addr1_ph'),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) {
            r.address1 = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_addr2')),
        RegInput(
          controller: _a2,
          hint: tr(context, 'reg_addr2_ph'),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) {
            r.address2 = v;
            r.touch();
          },
        ),
        RegLabel(tr(context, 'reg_country'), required: true),
        RegPicker(
          value: r.country,
          hint: tr(context, 'reg_pick_country'),
          title: tr(context, 'reg_country'),
          items: world?.countries ?? const [],
          loading: world == null,
          onSelect: (c) {
            r.country = c;
            r.state = '';
            r.city = '';
            r.touch();
            setState(() {});
          },
        ),
        if (states.isNotEmpty) ...[
          RegLabel(tr(context, 'reg_state'), required: true),
          RegPicker(
            value: r.state,
            hint: tr(context, 'reg_pick_state'),
            title: tr(context, 'reg_state'),
            items: states,
            onSelect: (st) {
              r.state = st;
              r.city = '';
              r.touch();
              setState(() {});
            },
          ),
        ],
        RegLabel(tr(context, 'reg_city'), required: true),
        if (cities.isNotEmpty)
          RegPicker(
            value: r.city,
            hint: tr(context, 'reg_pick_city'),
            title: tr(context, 'reg_city'),
            items: cities,
            enabled: states.isEmpty || r.state.isNotEmpty,
            onSelect: (c) {
              r.city = c;
              r.touch();
              setState(() {});
            },
          )
        else
          // Nothing listed for this place: type the city.
          RegInput(
            controller: _city,
            hint: tr(context, 'reg_city_ph'),
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              r.city = v;
              r.touch();
            },
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            tr(context, 'reg_city_help'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
        RegLabel(tr(context, 'reg_pin'), required: true),
        RegInput(
          controller: _pin,
          error: _err(context, r.pin, pinError(r.pin)),
          hint: tr(context, 'reg_pin_ph'),
          keyboardType: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (v) {
            r.pin = v;
            r.touch();
          },
        ),
      ],
    );
  }
}

List<TextInputFormatter> _idFormatters(String? type) => switch (type) {
  'aadhaar' => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(12),
    _GroupFormatter(4),
  ],
  'pan' => [
    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(10),
    _UpperFormatter(),
  ],
  'passport' => [
    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(8),
    _UpperFormatter(),
  ],
  'voter' => [
    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(10),
    _UpperFormatter(),
  ],
  _ => [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
    LengthLimitingTextInputFormatter(19),
    _UpperFormatter(),
  ],
};

class _UpperFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) => value.copyWith(text: value.text.toUpperCase());
}

/// Groups digits with spaces (e.g. Aadhaar 1234 5678 9012).
class _GroupFormatter extends TextInputFormatter {
  _GroupFormatter(this.size);

  final int size;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(' ', '');
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % size == 0) out.write(' ');
      out.write(digits[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 3: ID proof
// ───────────────────────────────────────────────────────────────────────────

const _idIcons = {
  'aadhaar': Icons.shield_outlined,
  'pan': Icons.insert_drive_file_outlined,
  'passport': Icons.public,
  'dl': Icons.directions_car_outlined,
  'voter': Icons.people_outline,
};

class _IdStep extends StatefulWidget {
  const _IdStep();

  @override
  State<_IdStep> createState() => _IdStepState();
}

class _IdStepState extends State<_IdStep> with _Live<_IdStep> {
  final _number = TextEditingController(text: registration.idNumber);

  String? _uploadError;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pickId() async {
    final picked = await pickDocument();
    if (picked == null || !mounted) return;
    setState(() => _uploadError = picked.errorKey);
    if (picked.ok) {
      registration.idFile = picked.name;
      registration.idPath = picked.path;
      registration.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final type = r.idType == null
        ? null
        : kIdTypes.firstWhere((t) => t.$1 == r.idType);
    final label = type == null ? '' : tr(context, type.$2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegLabel(tr(context, 'reg_id_label'), required: true),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in kIdTypes)
                  GestureDetector(
                    onTap: () {
                      if (r.idType != t.$1) {
                        r.idType = t.$1;
                        r.idNumber = '';
                        _number.clear();
                        r.touch();
                        setState(() {});
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: w,
                      height: 74,
                      decoration: BoxDecoration(
                        color: t.$1 == r.idType ? AppColors.tint : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: t.$1 == r.idType
                              ? AppColors.magenta
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _idIcons[t.$1],
                            size: 21,
                            color: t.$1 == r.idType
                                ? AppColors.magenta
                                : AppColors.muted,
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              tr(context, t.$2),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: t.$1 == r.idType
                                    ? AppColors.magenta
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (type == null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Center(
              child: Text(
                tr(context, 'reg_id_pick'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ),
          )
        else ...[
          RegLabel(
            tr(context, 'reg_id_number', args: {'id': label}),
            required: true,
          ),
          RegInput(
            controller: _number,
            hint: type.$3,
            error: _err(
              context,
              r.idNumber,
              idNumberError(r.idType, r.idNumber),
            ),
            keyboardType: r.idType == 'aadhaar'
                ? TextInputType.number
                : TextInputType.text,
            formatters: _idFormatters(r.idType),
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) {
              r.idNumber = v;
              r.touch();
            },
          ),
          RegLabel(
            tr(context, 'reg_id_photo', args: {'id': label}),
            required: true,
          ),
          if (_uploadError != null) RegError(tr(context, _uploadError!)),
          if (r.idFile == null)
            DashedBox(
              height: 112,
              onTap: _pickId,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.magenta, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'reg_upload_id'),
                    style: const TextStyle(
                      color: AppColors.magenta,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(context, 'reg_upload_hint'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F4EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E9D5B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFF1F8A4C)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.idFile!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tr(context, 'reg_uploaded'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickId,
                    child: Text(
                      tr(context, 'reg_replace'),
                      style: const TextStyle(
                        color: AppColors.magenta,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 4: photo
// ───────────────────────────────────────────────────────────────────────────

class _PhotoStep extends StatefulWidget {
  const _PhotoStep();

  @override
  State<_PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<_PhotoStep> with _Live<_PhotoStep> {
  String? _error;

  Future<void> _pick() async {
    final picked = await pickPhoto(context);
    if (picked == null || !mounted) return;
    setState(() => _error = picked.errorKey);
    if (picked.ok) {
      registration.photoFile = picked.name;
      registration.photoPath = picked.path;
      registration.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final has = r.photoFile != null;
    final initials = r.fullName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 168,
              height: 168,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: has ? AppColors.headerGradient : null,
                color: has ? null : AppColors.tint,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  has && r.photoPath != null && File(r.photoPath!).existsSync()
                  ? Image.file(
                      File(r.photoPath!),
                      width: 168,
                      height: 168,
                      fit: BoxFit.cover,
                    )
                  : has
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 72,
                      color: AppColors.muted,
                    ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pick,
              child: Text(
                tr(context, has ? 'reg_photo_change' : 'reg_photo_upload'),
                style: const TextStyle(
                  color: AppColors.magenta,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_error != null) RegError(tr(context, _error!)),
            if (has) ...[
              const SizedBox(height: 6),
              Text(
                r.photoFile!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 5: declaration
// ───────────────────────────────────────────────────────────────────────────

class _DeclarationStep extends StatefulWidget {
  const _DeclarationStep();

  @override
  State<_DeclarationStep> createState() => _DeclarationStepState();
}

class _DeclarationStepState extends State<_DeclarationStep>
    with _Live<_DeclarationStep> {
  final _sig = TextEditingController(text: registration.signature);
  final _scroll = ScrollController();
  AppLang? _docLang; // the language the document is shown in

  @override
  void dispose() {
    _sig.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openPdf() => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        tr(dialog, 'reg_s5'),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Text(tr(dialog, 'reg_pdf_note')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(
            tr(dialog, 'reg_ok'),
            style: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final app = AppLocale.of(context).lang;
    final doc =
        _docLang ?? (app == AppLang.hi || app == AppLang.mr ? app : AppLang.en);
    final paragraphs = trIn(doc, 'reg_decl_body').split('\n\n');
    final matches = r.signatureMatches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        // The document can be read in English, Hindi or Marathi.
        Row(
          children: [
            for (final l in [AppLang.en, AppLang.hi, AppLang.mr])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _docLang = l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: l == doc ? AppColors.magenta : AppColors.tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      l.native,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: l == doc ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trIn(doc, 'reg_s5'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${trIn(doc, 'reg_decl_by')} ',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        TextSpan(
                          text: r.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  for (final p in paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Color(0xFF3B3D55),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openPdf,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.insert_drive_file_outlined,
                  size: 18,
                  color: Color(0xFF555770),
                ),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'reg_decl_open'),
                  style: const TextStyle(
                    color: Color(0xFF555770),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            r.agreed = !r.agreed;
            r.touch();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: r.agreed ? AppColors.magenta : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: r.agreed ? AppColors.magenta : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: r.agreed ? AppColors.magenta : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: r.agreed
                      ? const Icon(Icons.check, color: Colors.white, size: 17)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(context, 'reg_decl_agree'),
                    style: const TextStyle(fontSize: 13.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        RegLabel(tr(context, 'reg_sig_label'), required: true),
        RegInput(
          controller: _sig,
          hint: r.fullName,
          onChanged: (v) {
            r.signature = v;
            r.touch();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            matches
                ? tr(context, 'reg_sig_match')
                : tr(context, 'reg_sig_hint', args: {'name': r.fullName}),
            style: TextStyle(
              fontSize: 12.5,
              color: matches ? const Color(0xFF1F8A4C) : AppColors.muted,
              fontWeight: matches ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        RegLabel(tr(context, 'reg_your_sig')),
        DashedBox(
          height: 92,
          child: matches
              ? Text(
                  r.signature.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontFamilyFallback: ['PlusJakartaSans'],
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                    fontSize: 25,
                    color: Color(0xFF2A2D44),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            tr(
              context,
              'reg_signed_on',
              args: {'date': fullDate(context, DateTime.now())},
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
