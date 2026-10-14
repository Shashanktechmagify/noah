import 'dart:convert';

import 'package:flutter/services.dart';

/// A country for phone numbers: name, ISO code and international dial code.
class DialCountry {
  const DialCountry(this.name, this.code, this.dial);

  final String name;
  final String code; // ISO 3166-1 alpha-2, e.g. IN
  final String dial; // e.g. +91

  bool get isIndia => code == 'IN';

  /// National number length for the countries we know exactly.
  static const _exact = {
    'IN': 10,
    'US': 10,
    'GB': 10,
    'AE': 9,
    'SG': 8,
    'AU': 9,
  };

  /// Most digits allowed in the national number.
  int get maxDigits => _exact[code] ?? 14;

  /// Whether [digits] (the national number, digits only) is a plausible length.
  bool validLength(int digits) {
    final exact = _exact[code];
    return exact != null ? digits == exact : digits >= 6 && digits <= 14;
  }
}

/// Every country with its dial code (bundled, offline).
/// Source: assets/data/dial.json, `[name, isoCode, dialCode]`.
class DialData {
  static List<DialCountry>? _all;

  /// The few countries available before the full list has loaded.
  static const fallback = [
    DialCountry('India', 'IN', '+91'),
    DialCountry('United States', 'US', '+1'),
    DialCountry('United Kingdom', 'GB', '+44'),
    DialCountry('United Arab Emirates', 'AE', '+971'),
    DialCountry('Singapore', 'SG', '+65'),
    DialCountry('Australia', 'AU', '+61'),
  ];

  static Future<List<DialCountry>> load() async {
    if (_all != null) return _all!;
    final raw = await rootBundle.loadString('assets/data/dial.json');
    return _all = (jsonDecode(raw) as List)
        .map((e) => DialCountry(e[0] as String, e[1] as String, e[2] as String))
        .toList();
  }

  /// All countries once loaded, otherwise the [fallback] list.
  static List<DialCountry> get countries => _all ?? fallback;

  static DialCountry byCode(String code) =>
      countries.firstWhere((c) => c.code == code, orElse: () => fallback.first);
}
