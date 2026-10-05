import 'dart:convert';

import 'cities.dart';
import 'format.dart';
import 'models.dart';
import 'sheets.dart';
import 'store.dart';
import 'xlsx_sheet.dart';

enum TransferKind {
  products,
  parties,
  sale,
  purchase,
  saleReturn,
  purchaseReturn,
  saleOrder,
  purchaseOrder,
  saleWaybill,
  purchaseWaybill,
  payments,
}

extension TransferKindText on TransferKind {
  String get title => switch (this) {
        TransferKind.products => 'Ürün kartları',
        TransferKind.parties => 'Cari kartlar',
        TransferKind.payments => 'Tahsilat ve ödeme',
        _ => docKindLabel(docKind!),
      };

  String get hint => switch (this) {
        TransferKind.products => 'Stok kodu aynıysa kart güncellenir, yeni kod kart açar.',
        TransferKind.parties => 'VKN veya ünvan aynıysa kart güncellenir. İl, haritadaki şehri belirler.',
        TransferKind.payments => 'Fiş no varsa atlanır. Yeni satır kasa veya banka bakiyesine işlenir.',
        _ => 'Aynı belge no atlanır. Durum Onaylı ise stok ve cari işlenir, boşsa taslak kalır.',
      };

  String get fileName => switch (this) {
        TransferKind.products => 'akim-urunler',
        TransferKind.parties => 'akim-cariler',
        TransferKind.payments => 'akim-tahsilat-odeme',
        TransferKind.sale => 'akim-satis-faturasi',
        TransferKind.purchase => 'akim-alis-faturasi',
        TransferKind.saleReturn => 'akim-satis-iadesi',
        TransferKind.purchaseReturn => 'akim-alis-iadesi',
        TransferKind.saleOrder => 'akim-satis-siparisi',
        TransferKind.purchaseOrder => 'akim-alis-siparisi',
        TransferKind.saleWaybill => 'akim-satis-irsaliyesi',
        TransferKind.purchaseWaybill => 'akim-alis-irsaliyesi',
      };

  DocKind? get docKind => switch (this) {
        TransferKind.sale => DocKind.sale,
        TransferKind.purchase => DocKind.purchase,
        TransferKind.saleReturn => DocKind.saleReturn,
        TransferKind.purchaseReturn => DocKind.purchaseReturn,
        TransferKind.saleOrder => DocKind.saleOrder,
        TransferKind.purchaseOrder => DocKind.purchaseOrder,
        TransferKind.saleWaybill => DocKind.saleWaybill,
        TransferKind.purchaseWaybill => DocKind.purchaseWaybill,
        _ => null,
      };
}

class ImportReport {
  int added = 0;
  int updated = 0;
  int skipped = 0;
  final List<String> notes = [];

  String summary() {
    final head = '$added eklendi, $updated güncellendi, $skipped atlandı';
    if (notes.isEmpty) return head;
    final extra = notes.length > 3 ? ' (+${notes.length - 3} uyarı)' : '';
    return '$head. ${notes.take(3).join(' ')}$extra';
  }
}

SheetTable buildTable(AppStore store, TransferKind kind) {
  final docKind = kind.docKind;
  if (docKind != null) return _docs(store, docKind);
  return switch (kind) {
    TransferKind.products => _products(store),
    TransferKind.parties => _parties(store),
    TransferKind.payments => _payments(store),
    _ => const SheetTable([], []),
  };
}

ImportReport importBytes(AppStore store, TransferKind kind, List<int> bytes, String filename) {
  final report = ImportReport();
  final SheetTable table;
  try {
    final lower = filename.toLowerCase();
    table = lower.endsWith('.csv') || lower.endsWith('.txt')
        ? SheetTable.parse(utf8.decode(bytes, allowMalformed: true))
        : decodeXlsx(bytes);
  } catch (_) {
    report.notes.add('Dosya okunamadı. Excel için .xlsx, diğer programlar için .csv kullanın.');
    return report;
  }
  if (table.headers.isEmpty) {
    report.notes.add('Dosyada başlık satırı yok.');
    return report;
  }
  importTable(store, kind, table, report);
  return report;
}

void importTable(AppStore store, TransferKind kind, SheetTable table, ImportReport report) {
  final grid = _Grid(table);
  final docKind = kind.docKind;
  if (docKind != null) {
    _importDocs(store, docKind, grid, report);
  } else if (kind == TransferKind.products) {
    _importProducts(store, grid, report);
  } else if (kind == TransferKind.parties) {
    _importParties(store, grid, report);
  } else {
    _importPayments(store, grid, report);
  }
}

SheetTable _products(AppStore store) {
  return SheetTable(
    const [
      'Stok kodu',
      'Barkod',
      'Ürün',
      'Marka',
      'Kategori',
      'KDV %',
      'Alış fiyatı',
      'Satış fiyatı',
      'Min. stok',
      'Raf',
      'Seri takipli',
      'Garanti ay',
      'Enerji',
      'Aktif',
      'Not',
    ],
    [
      for (final product in store.products)
        [
          product.sku,
          product.barcode,
          product.name,
          product.brand,
          product.category,
          sheetNum(product.vatRate),
          sheetNum(product.purchasePrice),
          sheetNum(product.salePrice),
          sheetNum(product.minStock),
          product.shelf,
          product.trackSerial ? 'Evet' : 'Hayır',
          '${product.warrantyMonths}',
          product.energyClass,
          product.active ? 'Evet' : 'Hayır',
          product.note,
        ],
    ],
  );
}

SheetTable _parties(AppStore store) {
  return SheetTable(
    const [
      'Ünvan',
      'Tür',
      'VKN',
      'Vergi dairesi',
      'Yetkili',
      'Telefon',
      'E-posta',
      'İl',
      'Adres',
      'Risk limiti',
      'Vade gün',
      'Not',
      'Aktif',
    ],
    [
      for (final party in store.parties)
        [
          party.name,
          partyTypeLabel(party.type),
          party.taxNo,
          party.taxOffice,
          party.contact,
          party.phone,
          party.email,
          party.city,
          party.address,
          sheetNum(party.creditLimit),
          '${party.termDays}',
          party.note,
          party.active ? 'Evet' : 'Hayır',
        ],
    ],
  );
}

SheetTable _payments(AppStore store) {
  return SheetTable(
    const ['Fiş no', 'Tarih', 'Yön', 'Yöntem', 'Cari', 'VKN', 'Hesap', 'Tutar', 'Not'],
    [
      for (final payment in store.payments)
        [
          payment.no,
          shortDate(payment.date),
          payment.direction == PayDirection.inbound ? 'Tahsilat' : 'Ödeme',
          payMethodLabel(payment.method),
          payment.partyId.isEmpty ? '' : store.partyName(payment.partyId),
          store.partyById(payment.partyId)?.taxNo ?? '',
          store.accountById(payment.accountId)?.name ?? '',
          sheetNum(payment.amount),
          payment.note,
        ],
    ],
  );
}

SheetTable _docs(AppStore store, DocKind kind) {
  const headers = [
    'Belge no',
    'Tarih',
    'Vade',
    'Cari',
    'VKN',
    'İl',
    'Depo',
    'Durum',
    'Stok kodu',
    'Ürün',
    'Miktar',
    'Birim fiyat',
    'İskonto %',
    'KDV %',
    'Seri no',
    'Satır notu',
    'Belge notu',
  ];
  final rows = <List<String>>[];
  for (final doc in store.docs.where((item) => item.kind == kind)) {
    final party = store.partyById(doc.partyId);
    for (final line in doc.lines) {
      final product = store.productById(line.productId);
      rows.add([
        doc.no,
        shortDate(doc.date),
        shortDate(doc.dueDate),
        party?.name ?? '',
        party?.taxNo ?? '',
        party?.city ?? '',
        store.warehouseName(doc.warehouseId),
        docStatusLabel(doc.status),
        product?.sku ?? '',
        product?.name ?? '',
        sheetNum(line.qty),
        sheetNum(line.unitPrice),
        sheetNum(line.discountRate),
        sheetNum(line.vatRate),
        line.serials.join(', '),
        line.note,
        doc.note,
      ]);
    }
  }
  return SheetTable(headers, rows);
}

void _importProducts(AppStore store, _Grid grid, ImportReport report) {
  if (!grid.has(['stokkodu', 'sku', 'kod', 'urun', 'urunadi', 'ad'])) {
    report.notes.add('Ürün dosyasında Stok kodu veya Ürün sütunu yok.');
    return;
  }
  store.runQuiet(() {
    for (final row in grid.rows) {
      final sku = grid.cell(row, ['stokkodu', 'sku', 'kod']);
      final name = grid.cell(row, ['urun', 'urunadi', 'ad']);
      if (sku.isEmpty && name.isEmpty) {
        report.skipped++;
        continue;
      }
      final existing = _findProduct(store, sku, name);
      if (existing == null) {
        store.upsertProduct(Product(
          id: '',
          sku: sku.isEmpty ? name : sku,
          name: name.isEmpty ? sku : name,
          brand: grid.cell(row, ['marka']),
          category: _or(grid.cell(row, ['kategori']), 'Diğer'),
          barcode: grid.cell(row, ['barkod']),
          vatRate: _num(grid, row, ['kdv']) ?? store.profile.defaultVat,
          purchasePrice: _num(grid, row, ['alisfiyati', 'alis']) ?? 0,
          salePrice: _num(grid, row, ['satisfiyati', 'satis']) ?? 0,
          minStock: _num(grid, row, ['minstok']) ?? 0,
          shelf: grid.cell(row, ['raf']),
          trackSerial: _bool(grid.cell(row, ['seritakipli'])) ?? false,
          warrantyMonths: _num(grid, row, ['garantiay', 'garanti'])?.round() ?? 24,
          energyClass: _or(grid.cell(row, ['enerji']), 'A'),
          active: _bool(grid.cell(row, ['aktif'])) ?? true,
          note: grid.cell(row, ['not']),
          warehouseId: store.warehouses.isEmpty ? '' : store.warehouses.first.id,
        ));
        report.added++;
        continue;
      }
      _setText(grid, row, ['barkod'], (value) => existing.barcode = value);
      _setText(grid, row, ['urun', 'urunadi', 'ad'], (value) => existing.name = value);
      _setText(grid, row, ['marka'], (value) => existing.brand = value);
      _setText(grid, row, ['kategori'], (value) => existing.category = value);
      _setText(grid, row, ['raf'], (value) => existing.shelf = value);
      _setText(grid, row, ['enerji'], (value) => existing.energyClass = value);
      _setText(grid, row, ['not'], (value) => existing.note = value);
      final vat = _num(grid, row, ['kdv']);
      if (vat != null) existing.vatRate = vat;
      final buy = _num(grid, row, ['alisfiyati', 'alis']);
      if (buy != null) existing.purchasePrice = buy;
      final sell = _num(grid, row, ['satisfiyati', 'satis']);
      if (sell != null) existing.salePrice = sell;
      final minStock = _num(grid, row, ['minstok']);
      if (minStock != null) existing.minStock = minStock;
      final months = _num(grid, row, ['garantiay', 'garanti']);
      if (months != null) existing.warrantyMonths = months.round();
      final serial = _bool(grid.cell(row, ['seritakipli']));
      if (serial != null) existing.trackSerial = serial;
      final active = _bool(grid.cell(row, ['aktif']));
      if (active != null) existing.active = active;
      store.upsertProduct(existing);
      report.updated++;
    }
  });
}

void _importParties(AppStore store, _Grid grid, ImportReport report) {
  if (!grid.has(['unvan', 'cari', 'ad'])) {
    report.notes.add('Cari dosyasında Ünvan sütunu yok.');
    return;
  }
  store.runQuiet(() {
    for (final row in grid.rows) {
      final name = grid.cell(row, ['unvan', 'cari', 'ad']);
      final taxNo = grid.cell(row, ['vkn', 'tckn', 'vergino']);
      if (name.isEmpty && taxNo.isEmpty) {
        report.skipped++;
        continue;
      }
      final existing = _findParty(store, name, taxNo);
      if (existing == null) {
        store.upsertParty(Party(
          id: '',
          type: _partyType(grid.cell(row, ['tur', 'tip'])),
          name: name.isEmpty ? taxNo : name,
          taxNo: taxNo,
          taxOffice: grid.cell(row, ['vergidairesi']),
          contact: grid.cell(row, ['yetkili']),
          phone: grid.cell(row, ['telefon']),
          email: grid.cell(row, ['eposta', 'email']),
          city: grid.cell(row, ['il', 'sehir']),
          address: grid.cell(row, ['adres']),
          creditLimit: _num(grid, row, ['risklimiti', 'limit']) ?? 0,
          termDays: _num(grid, row, ['vadegun', 'vade'])?.round() ?? store.profile.defaultTermDays,
          note: grid.cell(row, ['not']),
          active: _bool(grid.cell(row, ['aktif'])) ?? true,
        ));
        report.added++;
        continue;
      }
      _setText(grid, row, ['unvan', 'cari'], (value) => existing.name = value);
      _setText(grid, row, ['vkn', 'tckn', 'vergino'], (value) => existing.taxNo = value);
      _setText(grid, row, ['vergidairesi'], (value) => existing.taxOffice = value);
      _setText(grid, row, ['yetkili'], (value) => existing.contact = value);
      _setText(grid, row, ['telefon'], (value) => existing.phone = value);
      _setText(grid, row, ['eposta', 'email'], (value) => existing.email = value);
      _setText(grid, row, ['il', 'sehir'], (value) => existing.city = value);
      _setText(grid, row, ['adres'], (value) => existing.address = value);
      _setText(grid, row, ['not'], (value) => existing.note = value);
      if (grid.has(['tur', 'tip']) && grid.cell(row, ['tur', 'tip']).isNotEmpty) {
        existing.type = _partyType(grid.cell(row, ['tur', 'tip']));
      }
      final limit = _num(grid, row, ['risklimiti', 'limit']);
      if (limit != null) existing.creditLimit = limit;
      final term = _num(grid, row, ['vadegun', 'vade']);
      if (term != null) existing.termDays = term.round();
      final active = _bool(grid.cell(row, ['aktif']));
      if (active != null) existing.active = active;
      store.upsertParty(existing);
      report.updated++;
    }
  });
}

void _importPayments(AppStore store, _Grid grid, ImportReport report) {
  if (!grid.has(['tutar'])) {
    report.notes.add('Ödeme dosyasında Tutar sütunu yok.');
    return;
  }
  store.runQuiet(() {
    for (final row in grid.rows) {
      final amount = _num(grid, row, ['tutar']);
      if (amount == null || amount <= 0) {
        report.skipped++;
        report.notes.add('Tutarı boş olan satır atlandı.');
        continue;
      }
      final no = grid.cell(row, ['fisno', 'belgeno', 'no']);
      if (no.isNotEmpty && store.payments.any((item) => item.no.toLowerCase() == no.toLowerCase())) {
        report.skipped++;
        continue;
      }
      final party = _partyForRow(store, grid, row, customer: true);
      final account = _account(store, grid.cell(row, ['hesap']));
      if (account == null) {
        report.skipped++;
        report.notes.add('Kasa veya banka hesabı yok.');
        continue;
      }
      final direction = _direction(grid.cell(row, ['yon']));
      final error = store.addPayment(Payment(
        id: '',
        no: no,
        date: _date(grid.cell(row, ['tarih'])) ?? DateTime.now(),
        accountId: account.id,
        direction: direction,
        method: _method(grid.cell(row, ['yontem'])),
        amount: amount,
        partyId: party?.id ?? '',
        note: grid.cell(row, ['not']),
      ));
      if (error != null) {
        report.skipped++;
        report.notes.add(error);
      } else {
        report.added++;
      }
    }
  });
}

void _importDocs(AppStore store, DocKind kind, _Grid grid, ImportReport report) {
  if (!grid.has(['belgeno', 'no']) || !grid.has(['miktar']) || !grid.has(['stokkodu', 'sku', 'kod', 'urun', 'urunadi'])) {
    report.notes.add('Belge dosyasında Belge no, Miktar ve Stok kodu sütunları olmalı.');
    return;
  }
  if (!grid.has(['cari', 'unvan']) && !grid.has(['vkn', 'tckn', 'vergino'])) {
    report.notes.add('Belge dosyasında Cari veya VKN sütunu olmalı.');
    return;
  }
  final groups = <String, List<List<String>>>{};
  for (final row in grid.rows) {
    final no = grid.cell(row, ['belgeno', 'no']);
    if (no.isEmpty) {
      report.skipped++;
      continue;
    }
    groups.putIfAbsent(no, () => []).add(row);
  }
  store.runQuiet(() {
    for (final entry in groups.entries) {
      final no = entry.key;
      if (store.docs.any((doc) => doc.kind == kind && doc.no.toLowerCase() == no.toLowerCase())) {
        report.skipped++;
        continue;
      }
      final first = entry.value.first;
      final selling = kind == DocKind.sale ||
          kind == DocKind.saleReturn ||
          kind == DocKind.saleOrder ||
          kind == DocKind.saleWaybill;
      final party = _partyForRow(store, grid, first, customer: selling);
      final warehouse = _warehouse(store, grid.cell(first, ['depo']));
      if (party == null || warehouse == null) {
        report.skipped++;
        report.notes.add('$no için cari veya depo bulunamadı.');
        continue;
      }
      final city = grid.cell(first, ['il', 'sehir']);
      if (city.isNotEmpty) party.city = city;
      final lines = <DocLine>[];
      for (final row in entry.value) {
        final product = _productForRow(store, grid, row, warehouse.id, selling);
        final qty = _num(grid, row, ['miktar']);
        if (product == null || qty == null || qty <= 0) {
          report.notes.add('$no satırında ürün veya miktar eksik.');
          continue;
        }
        final fallback = selling ? product.salePrice : product.purchasePrice;
        lines.add(DocLine(
          productId: product.id,
          qty: qty,
          unitPrice: _num(grid, row, ['birimfiyat', 'fiyat']) ?? fallback,
          discountRate: _num(grid, row, ['iskonto']) ?? 0,
          vatRate: _num(grid, row, ['kdv']) ?? product.vatRate,
          serials: _serials(grid.cell(row, ['serino', 'seri'])),
          note: grid.cell(row, ['satirnotu']),
        ));
      }
      if (lines.isEmpty) {
        report.skipped++;
        continue;
      }
      final date = _date(grid.cell(first, ['tarih'])) ?? DateTime.now();
      final due = _date(grid.cell(first, ['vade'])) ?? date.add(Duration(days: party.termDays));
      final doc = TradeDoc(
        id: '',
        kind: kind,
        status: DocStatus.draft,
        no: no,
        date: date,
        dueDate: due,
        partyId: party.id,
        warehouseId: warehouse.id,
        lines: lines,
        note: grid.cell(first, ['belgenotu', 'not']),
      );
      final error = store.addDraft(doc);
      if (error != null) {
        report.skipped++;
        report.notes.add('$no: $error');
        continue;
      }
      final status = _status(grid.cell(first, ['durum']));
      if (status == DocStatus.approved) {
        final approveError = store.approveDoc(doc.id);
        if (approveError != null) report.notes.add('$no: $approveError');
      } else if (status == DocStatus.cancelled) {
        store.cancelDoc(doc.id);
      } else if (status == DocStatus.invoiced) {
        doc.status = DocStatus.invoiced;
      }
      report.added++;
    }
  });
}

class _Grid {
  _Grid(SheetTable table) : rows = table.rows {
    for (var i = 0; i < table.headers.length; i++) {
      header[headerKey(table.headers[i])] = i;
    }
  }

  final Map<String, int> header = {};
  final List<List<String>> rows;

  bool has(List<String> keys) => keys.any(header.containsKey);

  String cell(List<String> row, List<String> keys) {
    for (final key in keys) {
      final index = header[key];
      if (index == null || index >= row.length) continue;
      final value = row[index].trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}

void _setText(_Grid grid, List<String> row, List<String> keys, void Function(String value) assign) {
  if (!grid.has(keys)) return;
  final value = grid.cell(row, keys);
  if (value.isNotEmpty) assign(value);
}

double? _num(_Grid grid, List<String> row, List<String> keys) => parseNum(grid.cell(row, keys));

String _or(String value, String fallback) => value.isEmpty ? fallback : value;

bool? _bool(String raw) {
  final key = foldCity(raw);
  if (key.isEmpty) return null;
  if (key == 'evet' || key == 'e' || key == '1' || key == 'true' || key == 'var' || key == 'aktif') return true;
  if (key == 'hayir' || key == 'h' || key == '0' || key == 'false' || key == 'yok' || key == 'pasif') return false;
  return null;
}

PartyType _partyType(String raw) {
  final key = foldCity(raw);
  if ((key.contains('tedarik') && key.contains('musteri')) || key == 'both' || key == 'herikisi') {
    return PartyType.both;
  }
  if (key.contains('tedarik') || key == 'supplier') return PartyType.supplier;
  return PartyType.customer;
}

PayDirection _direction(String raw) {
  final key = foldCity(raw);
  if (key.contains('odeme') || key.contains('giden') || key == 'outbound') return PayDirection.outbound;
  return PayDirection.inbound;
}

PayMethod _method(String raw) {
  final key = foldCity(raw);
  if (key.contains('havale') || key.contains('eft') || key.contains('transfer')) return PayMethod.transfer;
  if (key.contains('kart')) return PayMethod.card;
  if (key.contains('senet')) return PayMethod.note;
  if (key.contains('cek')) return PayMethod.check;
  return PayMethod.cash;
}

DocStatus? _status(String raw) {
  final key = foldCity(raw);
  if (key.isEmpty || key.startsWith('taslak')) return DocStatus.draft;
  if (key.startsWith('onay')) return DocStatus.approved;
  if (key.startsWith('iptal')) return DocStatus.cancelled;
  if (key.startsWith('fatura')) return DocStatus.invoiced;
  return DocStatus.draft;
}

DateTime? _date(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})$').firstMatch(text);
  if (match != null) {
    return DateTime(int.parse(match.group(3)!), int.parse(match.group(2)!), int.parse(match.group(1)!));
  }
  return DateTime.tryParse(text);
}

List<String> _serials(String raw) {
  return raw.split(RegExp(r'[,;]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
}

Product? _findProduct(AppStore store, String sku, String name) {
  final code = sku.trim().toLowerCase();
  if (code.isNotEmpty) {
    for (final product in store.products) {
      if (product.sku.toLowerCase() == code) return product;
    }
  }
  final key = foldCity(name);
  if (key.isEmpty) return null;
  for (final product in store.products) {
    if (foldCity(product.name) == key) return product;
  }
  return null;
}

Party? _findParty(AppStore store, String name, String taxNo) {
  final tax = taxNo.replaceAll(RegExp(r'\s'), '');
  if (tax.isNotEmpty) {
    for (final party in store.parties) {
      if (party.taxNo.replaceAll(RegExp(r'\s'), '') == tax) return party;
    }
  }
  final key = foldCity(name);
  if (key.isEmpty) return null;
  for (final party in store.parties) {
    if (foldCity(party.name) == key) return party;
  }
  return null;
}

Party? _partyForRow(AppStore store, _Grid grid, List<String> row, {required bool customer}) {
  final name = grid.cell(row, ['cari', 'unvan', 'ad']);
  final taxNo = grid.cell(row, ['vkn', 'tckn', 'vergino']);
  final existing = _findParty(store, name, taxNo);
  if (existing != null) return existing;
  if (name.isEmpty && taxNo.isEmpty) return null;
  final party = Party(
    id: '',
    type: customer ? PartyType.customer : PartyType.supplier,
    name: name.isEmpty ? taxNo : name,
    taxNo: taxNo,
    city: grid.cell(row, ['il', 'sehir']),
  );
  store.upsertParty(party);
  return party;
}

Product? _productForRow(AppStore store, _Grid grid, List<String> row, String warehouseId, bool selling) {
  final sku = grid.cell(row, ['stokkodu', 'sku', 'kod']);
  final name = grid.cell(row, ['urun', 'urunadi', 'ad']);
  final existing = _findProduct(store, sku, name);
  if (existing != null) return existing;
  if (sku.isEmpty && name.isEmpty) return null;
  final price = _num(grid, row, ['birimfiyat', 'fiyat']) ?? 0;
  final product = Product(
    id: '',
    sku: sku.isEmpty ? name : sku,
    name: name.isEmpty ? sku : name,
    brand: '',
    category: 'Diğer',
    vatRate: _num(grid, row, ['kdv']) ?? store.profile.defaultVat,
    purchasePrice: selling ? 0 : price,
    salePrice: selling ? price : 0,
    warehouseId: warehouseId,
  );
  store.upsertProduct(product);
  return product;
}

Warehouse? _warehouse(AppStore store, String name) {
  if (store.warehouses.isEmpty) return null;
  final key = foldCity(name);
  if (key.isEmpty) return store.warehouses.first;
  for (final warehouse in store.warehouses) {
    if (foldCity(warehouse.name) == key) return warehouse;
  }
  return store.warehouses.first;
}

CashAccount? _account(AppStore store, String name) {
  final key = foldCity(name);
  if (key.isNotEmpty) {
    for (final account in store.accounts) {
      if (foldCity(account.name) == key) return account;
    }
  }
  for (final account in store.accounts) {
    if (account.role == AccountRole.cash) return account;
  }
  return store.accounts.isEmpty ? null : store.accounts.first;
}
