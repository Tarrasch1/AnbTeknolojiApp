import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:toptanci_takip/src/cities.dart';
import 'package:toptanci_takip/src/provinces.dart';
import 'package:toptanci_takip/src/sheets.dart';
import 'package:toptanci_takip/src/store.dart';
import 'package:toptanci_takip/src/transfer.dart';
import 'package:toptanci_takip/src/xlsx_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il adları ve 81 il aynı anahtara iner', () async {
    expect(foldCity('İstanbul'), 'istanbul');
    expect(foldCity('İzmir'), 'izmir');
    expect(foldCity('Afyon'), 'afyonkarahisar');
    expect(foldCity('K. Maraş'), 'kahramanmaras');

    final provinces = await loadProvinces();
    expect(provinces, hasLength(81));
    expect(provinces.map((item) => item.key).toSet(), hasLength(81));
    expect(provinces.any((item) => item.name == 'İstanbul' && item.key == 'istanbul'), isTrue);
  });

  test('şehir satışı toplam satışın payına bölünür', () async {
    final store = AppStore(box: MemoryJsonBox());
    await store.ensureLoaded();
    final total = store.salesTotal();
    final cities = store.salesByCity();
    final summed = cities.fold<double>(0, (sum, city) => sum + city.sales);
    expect(summed, closeTo(total, 0.05));
    final istanbul = cities.firstWhere((city) => city.key == 'istanbul');
    expect(istanbul.firms.any((firm) => firm.party.name == 'Yıldız Elektrik'), isTrue);
    expect(istanbul.percentOf(total), inInclusiveRange(0, 100));
  });

  test('csv ve excel satış faturası stoğu bir kez düşürür', () async {
    final store = AppStore(box: MemoryJsonBox());
    await store.ensureLoaded();
    final before = store.stockOf('p1');
    const csv = '''
Belge no;Tarih;Vade;Cari;VKN;İl;Depo;Durum;Stok kodu;Ürün;Miktar;Birim fiyat;İskonto %;KDV %
SF-EXCEL;05.10.2026;05.11.2026;Yıldız Elektrik;9988776655;İstanbul;Merkez Depo;Onaylı;ARC-NF-570;Buzdolabı;1;1000;0;20
''';
    final first = importBytes(store, TransferKind.sale, utf8.encode(csv), 'satis.csv');
    expect(first.added, 1, reason: first.summary());
    expect(store.stockOf('p1'), before - 1);

    final second = importBytes(store, TransferKind.sale, utf8.encode(csv), 'satis.csv');
    expect(second.skipped, 1);
    expect(store.stockOf('p1'), before - 1);

    final quoted = parseCsv('A;B\n"x;y";1\n');
    expect(quoted[1][0], 'x;y');

    final bytes = encodeXlsx(buildTable(store, TransferKind.products));
    final table = decodeXlsx(bytes);
    expect(table.headers.first, 'Stok kodu');
    expect(table.rows.any((row) => row.isNotEmpty && row.first == 'ARC-NF-570'), isTrue);
  });
}
