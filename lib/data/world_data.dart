import 'dart:convert';

import 'package:flutter/services.dart';

/// Every country with its states and cities (bundled, offline).
/// Source: assets/data/world.json, `[country, isoCode, [[state, [cities]]]]`.
class World {
  World._(this._data);

  final List<dynamic> _data;

  static World? _instance;

  /// Loaded once, on first use.
  static Future<World> load() async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString('assets/data/world.json');
    return _instance = World._(jsonDecode(raw) as List<dynamic>);
  }

  /// Already-loaded data, or null while loading.
  static World? get ready => _instance;

  late final List<String> countries = [
    for (final c in _data) (c as List)[0] as String,
  ];

  List<dynamic> _states(String country) {
    for (final c in _data) {
      if ((c as List)[0] == country) return c[2] as List<dynamic>;
    }
    return const [];
  }

  /// Two-letter ISO code of [country] (empty when unknown).
  String codeOf(String country) {
    for (final c in _data) {
      if ((c as List)[0] == country) return c[1] as String;
    }
    return '';
  }

  /// States of [country] (empty for countries without any).
  List<String> statesOf(String country) => [
    for (final s in _states(country)) (s as List)[0] as String,
  ];

  /// Cities of [state] in [country].
  List<String> citiesOf(String country, String state) {
    for (final s in _states(country)) {
      if ((s as List)[0] == state) {
        return List<String>.from(s[1] as List);
      }
    }
    return const [];
  }
}
