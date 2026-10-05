import 'dart:convert';

import 'package:flutter/services.dart';

import 'cities.dart';

class ProvinceShape {
  const ProvinceShape({required this.name, required this.key, required this.rings});

  final String name;
  final String key;
  final List<List<Offset>> rings;
}

Future<List<ProvinceShape>>? _cached;

Future<List<ProvinceShape>> loadProvinces() => _cached ??= _readProvinces();

Future<List<ProvinceShape>> _readProvinces() async {
  final raw = await rootBundle.loadString('assets/turkey_provinces.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final list = data['provinces'] as List;
  return [
    for (final item in list)
      ProvinceShape(
        name: (item as Map)['name'] as String,
        key: foldCity(item['name'] as String),
        rings: [
          for (final ring in item['rings'] as List)
            [
              for (final point in ring as List)
                Offset(((point as List)[0] as num).toDouble(), (point[1] as num).toDouble()),
            ],
        ],
      ),
  ];
}
