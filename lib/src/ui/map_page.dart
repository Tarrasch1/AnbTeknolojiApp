import 'package:flutter/material.dart';

import '../cities.dart';
import '../format.dart';
import '../provinces.dart';
import '../store.dart';
import 'cards.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final Future<List<ProvinceShape>> _future = loadProvinces();
  String? _hover;
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Column(
      children: [
        const PageIntro(
          title: 'Türkiye haritası',
          hint: '81 il. Üzerine gelince il öne çıkar. Tıklayınca firmalar ve toplam satış içindeki pay görünür.',
          icon: Icons.map_outlined,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FutureBuilder<List<ProvinceShape>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const EmptyHint('Harita yüklenemedi.');
                final provinces = snapshot.data;
                if (provinces == null) return const Center(child: CircularProgressIndicator());
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final map = _mapCard(store, provinces);
                    final detail = _detailCard(store, provinces);
                    if (!wide) {
                      final mapHeight = (constraints.maxHeight * 0.5).clamp(200.0, 360.0);
                      return Column(
                        children: [
                          SizedBox(height: mapHeight, child: map),
                          const SizedBox(height: 12),
                          Expanded(child: detail),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 3, child: map),
                        const SizedBox(width: 12),
                        SizedBox(width: 360, child: detail),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapCard(AppStore store, List<ProvinceShape> provinces) {
    final sales = <String, double>{
      for (final city in store.salesByCity()) city.key: city.sales,
    };
    final total = store.salesTotal();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return MouseRegion(
                    cursor: _hover == null ? MouseCursor.defer : SystemMouseCursors.click,
                    onHover: (event) {
                      final next = _hit(provinces, size, event.localPosition);
                      if (next != _hover) setState(() => _hover = next);
                    },
                    onExit: (_) {
                      if (_hover != null) setState(() => _hover = null);
                    },
                    child: GestureDetector(
                      onTapUp: (details) => setState(() => _selected = _hit(provinces, size, details.localPosition)),
                      child: CustomPaint(
                        size: size,
                        painter: _TurkeyPainter(
                          provinces: provinces,
                          sales: sales,
                          total: total,
                          hover: _hover,
                          selected: _selected,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Koyu mavi, satış payı yüksek iller. Üzerine gelince il öne çıkar.',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCard(AppStore store, List<ProvinceShape> provinces) {
    ProvinceShape? province;
    for (final item in provinces) {
      if (item.key == _selected) province = item;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: province == null
          ? const EmptyHint('Haritadan bir il seçin. O ildeki firmalar ve satış payı burada açılır.')
          : _cityDetail(store, province),
    );
  }

  Widget _cityDetail(AppStore store, ProvinceShape province) {
    CitySales? city;
    for (final item in store.salesByCity()) {
      if (item.key == province.key) city = item;
    }
    final sales = city?.sales ?? 0;
    final total = store.salesTotal();
    final share = total.abs() < 0.009 ? 0.0 : sales / total * 100;
    final firms = city?.firms ?? const <CityFirmSale>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(province.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy)),
        const SizedBox(height: 8),
        Text(percentLabel(share), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: kNavy, height: 1)),
        const SizedBox(height: 4),
        Text('toplam satış içindeki pay', style: TextStyle(color: kMuted.withOpacity(0.95))),
        const SizedBox(height: 10),
        Text(cityShareSentence(province.name, money(sales), share), style: const TextStyle(height: 1.35)),
        const SizedBox(height: 4),
        Text('Firma geneli ${money(total)}', style: const TextStyle(color: kMuted)),
        const SizedBox(height: 14),
        Text(firms.isEmpty ? 'Bu ilde kayıtlı firma yok' : 'Firmalar', style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
        const SizedBox(height: 8),
        if (firms.isEmpty)
          const Text('Cari kartındaki il, bu şehirle aynı yazılırsa firma burada listelenir.', style: TextStyle(color: kMuted))
        else
          for (final firm in firms)
            RecordRow(
              icon: Icons.storefront_outlined,
              tone: partyTone(firm.party.type),
              title: firm.party.name,
              subtitle: '${partyTypeLabel(firm.party.type)} · ${firm.party.city.isEmpty ? province.name : firm.party.city}',
              trailing: firm.sales == 0 ? 'Satış yok' : money(firm.sales),
              trailingColor: firm.sales < 0 ? kBad : (firm.sales == 0 ? kMuted : kGood),
            ),
      ],
    );
  }
}

String? _hit(List<ProvinceShape> provinces, Size size, Offset point) {
  for (var i = provinces.length - 1; i >= 0; i--) {
    if (_path(provinces[i], size, 1).contains(point)) return provinces[i].key;
  }
  return null;
}

Offset _project(Offset unit, Size size) {
  const pad = 8.0;
  return Offset(
    pad + unit.dx / 10000 * (size.width - pad * 2),
    pad + unit.dy / 10000 * (size.height - pad * 2),
  );
}

Offset _center(ProvinceShape province, Size size) {
  var ring = province.rings.first;
  for (final item in province.rings) {
    if (item.length > ring.length) ring = item;
  }
  var x = 0.0;
  var y = 0.0;
  for (final point in ring) {
    final mapped = _project(point, size);
    x += mapped.dx;
    y += mapped.dy;
  }
  return Offset(x / ring.length, y / ring.length);
}

Path _path(ProvinceShape province, Size size, double scale) {
  final center = _center(province, size);
  final path = Path();
  for (final ring in province.rings) {
    for (var i = 0; i < ring.length; i++) {
      var point = _project(ring[i], size);
      if (scale != 1) point = center + (point - center) * scale;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
  }
  return path;
}

class _TurkeyPainter extends CustomPainter {
  _TurkeyPainter({
    required this.provinces,
    required this.sales,
    required this.total,
    required this.hover,
    required this.selected,
  });

  final List<ProvinceShape> provinces;
  final Map<String, double> sales;
  final double total;
  final String? hover;
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    var maxSales = 0.0;
    for (final amount in sales.values) {
      if (amount > maxSales) maxSales = amount;
    }
    final ordered = [...provinces]..sort((a, b) => _rank(a).compareTo(_rank(b)));
    for (final province in ordered) {
      final amount = sales[province.key] ?? 0;
      final active = province.key == hover;
      final chosen = province.key == selected;
      final path = _path(province, size, active ? 1.08 : 1);
      if (active) {
        canvas.drawPath(
          path.shift(const Offset(0, 5)),
          Paint()
            ..color = kNavy.withOpacity(0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      final fill = chosen ? kNavy : _fill(amount, maxSales);
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active || chosen ? 2.2 : 0.8
          ..color = active || chosen ? (chosen ? Colors.white : kNavy) : const Color(0xFFB7C6D8),
      );
      if (active || chosen) _label(canvas, size, province, amount, chosen);
    }
  }

  int _rank(ProvinceShape province) {
    if (province.key == hover) return 2;
    if (province.key == selected) return 1;
    return 0;
  }

  Color _fill(double amount, double maxSales) {
    if (amount < -0.009) return const Color(0xFFF8E8E6);
    if (maxSales <= 0 || amount <= 0) return const Color(0xFFE7EEF6);
    final t = (amount / maxSales).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFD7E6F8), kNavy, 0.22 + t * 0.78)!;
  }

  void _label(Canvas canvas, Size size, ProvinceShape province, double amount, bool chosen) {
    final share = total.abs() < 0.009 ? 0.0 : amount / total * 100;
    final text = TextPainter(
      text: TextSpan(
        text: '${province.name}\n${percentLabel(share)}',
        style: TextStyle(color: chosen ? Colors.white : kInk, fontSize: 12, fontWeight: FontWeight.w800, height: 1.25),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);
    final anchor = _center(province, size);
    final origin = Offset(
      (anchor.dx - text.width / 2).clamp(4.0, size.width - text.width - 4),
      (anchor.dy - text.height / 2).clamp(4.0, size.height - text.height - 4),
    );
    final rect = RRect.fromRectAndRadius(origin.translate(-6, -4) & Size(text.width + 12, text.height + 8), const Radius.circular(8));
    canvas.drawRRect(rect, Paint()..color = chosen ? kNavy : Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = kNavy,
    );
    text.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(covariant _TurkeyPainter oldDelegate) {
    return oldDelegate.hover != hover ||
        oldDelegate.selected != selected ||
        oldDelegate.total != total ||
        oldDelegate.sales.length != sales.length;
  }
}
