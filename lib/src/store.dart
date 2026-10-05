import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cities.dart';
import 'format.dart';
import 'models.dart';
import 'seed.dart';

const _storageKey = 'akim_db_v1';

abstract class JsonBox {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryJsonBox implements JsonBox {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}

class PrefsJsonBox implements JsonBox {
  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

class SlowItem {
  SlowItem({required this.product, required this.onHand, required this.lastSale});

  final Product product;
  final double onHand;
  final DateTime? lastSale;
}

class ReorderNeed {
  ReorderNeed({
    required this.product,
    required this.onHand,
    required this.shortQty,
    required this.supplierId,
    required this.lastCost,
  });

  final Product product;
  final double onHand;
  final double shortQty;
  final String supplierId;
  final double lastCost;
}

class AppStore extends ChangeNotifier {
  AppStore({JsonBox? box}) : _box = box ?? PrefsJsonBox();

  final JsonBox _box;
  var _mute = false;
  var _seq = 0;
  var ready = false;

  CompanyProfile profile = CompanyProfile(name: '', shortName: '');
  final warehouses = <Warehouse>[];
  final products = <Product>[];
  final parties = <Party>[];
  final priceLists = <PriceList>[];
  final specialPrices = <SpecialPrice>[];
  final docs = <TradeDoc>[];
  final moves = <StockMove>[];
  final serials = <SerialUnit>[];
  final accounts = <CashAccount>[];
  final payments = <Payment>[];
  final instruments = <Instrument>[];
  final tickets = <ServiceTicket>[];

  String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  Future<void> ensureLoaded() async {
    if (ready) return;
    final raw = await _box.read(_storageKey);
    if (raw == null || raw.isEmpty) {
      _mute = true;
      seedDemo(this);
      _mute = false;
      await save();
    } else {
      readJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    ready = true;
    notifyListeners();
  }

  Future<void> save() async {
    try {
      await _box.write(_storageKey, exportJson());
    } catch (error) {
      debugPrint('Kayıt yazılamadı: $error');
    }
  }

  void _touch() {
    if (_mute) return;
    notifyListeners();
    save();
  }

  void runQuiet(void Function() body) {
    _mute = true;
    try {
      body();
    } finally {
      _mute = false;
    }
    _touch();
  }

  void _replaceAll() {
    warehouses.clear();
    products.clear();
    parties.clear();
    priceLists.clear();
    specialPrices.clear();
    docs.clear();
    moves.clear();
    serials.clear();
    accounts.clear();
    payments.clear();
    instruments.clear();
    tickets.clear();
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'profile': profile.toJson(),
        'warehouses': warehouses.map((e) => e.toJson()).toList(),
        'products': products.map((e) => e.toJson()).toList(),
        'parties': parties.map((e) => e.toJson()).toList(),
        'priceLists': priceLists.map((e) => e.toJson()).toList(),
        'specialPrices': specialPrices.map((e) => e.toJson()).toList(),
        'docs': docs.map((e) => e.toJson()).toList(),
        'moves': moves.map((e) => e.toJson()).toList(),
        'serials': serials.map((e) => e.toJson()).toList(),
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'instruments': instruments.map((e) => e.toJson()).toList(),
        'tickets': tickets.map((e) => e.toJson()).toList(),
      };

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  void readJson(Map<String, dynamic> json) {
    _replaceAll();
    profile = CompanyProfile.fromJson(json['profile'] as Map<String, dynamic>);
    for (final item in json['warehouses'] as List? ?? const []) {
      warehouses.add(Warehouse.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['products'] as List? ?? const []) {
      products.add(Product.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['parties'] as List? ?? const []) {
      parties.add(Party.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['priceLists'] as List? ?? const []) {
      priceLists.add(PriceList.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['specialPrices'] as List? ?? const []) {
      specialPrices.add(SpecialPrice.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['docs'] as List? ?? const []) {
      docs.add(TradeDoc.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['moves'] as List? ?? const []) {
      moves.add(StockMove.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['serials'] as List? ?? const []) {
      serials.add(SerialUnit.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['accounts'] as List? ?? const []) {
      accounts.add(CashAccount.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['payments'] as List? ?? const []) {
      payments.add(Payment.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['instruments'] as List? ?? const []) {
      instruments.add(Instrument.fromJson(item as Map<String, dynamic>));
    }
    for (final item in json['tickets'] as List? ?? const []) {
      tickets.add(ServiceTicket.fromJson(item as Map<String, dynamic>));
    }
  }

  String? importJson(String raw) {
    try {
      readJson(jsonDecode(raw) as Map<String, dynamic>);
      ready = true;
      _touch();
      return null;
    } catch (error) {
      return 'Yedek okunamadı';
    }
  }

  Future<void> resetDemo() async {
    _mute = true;
    _replaceAll();
    seedDemo(this);
    _mute = false;
    ready = true;
    await save();
    notifyListeners();
  }

  Product? productById(String id) {
    for (final item in products) {
      if (item.id == id) return item;
    }
    return null;
  }

  Party? partyById(String id) {
    for (final item in parties) {
      if (item.id == id) return item;
    }
    return null;
  }

  Warehouse? warehouseById(String id) {
    for (final item in warehouses) {
      if (item.id == id) return item;
    }
    return null;
  }

  CashAccount? accountById(String id) {
    for (final item in accounts) {
      if (item.id == id) return item;
    }
    return null;
  }

  TradeDoc? docById(String id) {
    for (final item in docs) {
      if (item.id == id) return item;
    }
    return null;
  }

  PriceList? priceListById(String id) {
    for (final item in priceLists) {
      if (item.id == id) return item;
    }
    return null;
  }

  CashAccount? accountByRole(AccountRole role) {
    for (final item in accounts) {
      if (item.role == role) return item;
    }
    return null;
  }

  String productName(String id) => productById(id)?.name ?? 'Silinmiş ürün';
  String partyName(String id) => id.isEmpty ? '—' : (partyById(id)?.name ?? 'Silinmiş cari');
  String warehouseName(String id) => warehouseById(id)?.name ?? 'Depo';

  double stockOf(String productId, {String? warehouseId}) {
    var qty = 0.0;
    for (final move in moves) {
      if (move.productId != productId) continue;
      if (warehouseId != null && move.warehouseId != warehouseId) continue;
      qty += move.qty;
    }
    return (qty * 1000).roundToDouble() / 1000.0;
  }

  double reservedOf(String productId, {String? warehouseId, String exceptDocId = ''}) {
    var qty = 0.0;
    for (final doc in docs) {
      if (doc.id == exceptDocId) continue;
      if (doc.kind != DocKind.saleOrder || doc.status != DocStatus.approved) continue;
      if (warehouseId != null && doc.warehouseId != warehouseId) continue;
      for (final line in doc.lines) {
        if (line.productId == productId) qty += line.qty;
      }
    }
    return (qty * 1000).roundToDouble() / 1000.0;
  }

  double availableOf(String productId, {String? warehouseId, String exceptDocId = ''}) {
    final free = stockOf(productId, warehouseId: warehouseId) - reservedOf(productId, warehouseId: warehouseId, exceptDocId: exceptDocId);
    return (free * 1000).roundToDouble() / 1000.0;
  }

  double suggestPrice(Product product, Party? party, DocKind kind) {
    final buying = kind == DocKind.purchase ||
        kind == DocKind.purchaseReturn ||
        kind == DocKind.purchaseOrder ||
        kind == DocKind.purchaseWaybill;
    if (buying) return product.purchasePrice;
    if (party != null) {
      final special = specialPrice(party.id, product.id);
      if (special != null) return special.price;
    }
    final list = party == null ? null : priceListById(party.priceListId);
    if (list == null || !list.active) return product.salePrice;
    return round2(product.salePrice * (1 - list.discountPercent / 100));
  }

  String nextNo(DocKind kind) {
    final year = DateTime.now().year;
    final count = docs.where((doc) => doc.kind == kind && doc.date.year == year).length + 1;
    return '${docPrefix(kind)}-$year-${count.toString().padLeft(4, '0')}';
  }

  String nextPayNo(PayDirection direction) {
    final year = DateTime.now().year;
    final prefix = direction == PayDirection.inbound ? 'TH' : 'OD';
    final count = payments
            .where((item) => item.direction == direction && item.date.year == year && item.partyId.isNotEmpty)
            .length +
        1;
    return '$prefix-$year-${count.toString().padLeft(4, '0')}';
  }

  String nextTicketNo() {
    final year = DateTime.now().year;
    final count = tickets.where((item) => item.date.year == year).length + 1;
    return 'SRV-$year-${count.toString().padLeft(4, '0')}';
  }

  void saveProfile(CompanyProfile value) {
    profile = value;
    _touch();
  }

  void upsertWarehouse(Warehouse warehouse) {
    if (warehouse.id.isEmpty) warehouse.id = newId();
    final index = warehouses.indexWhere((item) => item.id == warehouse.id);
    if (index >= 0) {
      warehouses[index] = warehouse;
    } else {
      warehouses.add(warehouse);
    }
    _touch();
  }

  String? removeWarehouse(String id) {
    if (warehouses.length <= 1) return 'Son depo silinemez';
    final used = moves.any((move) => move.warehouseId == id) ||
        docs.any((doc) => doc.warehouseId == id) ||
        products.any((product) => product.warehouseId == id);
    if (used) return 'Hareketi olan depo silinemez';
    warehouses.removeWhere((item) => item.id == id);
    _touch();
    return null;
  }

  void upsertProduct(Product product) {
    if (product.id.isEmpty) product.id = newId();
    final index = products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.add(product);
    }
    _touch();
  }

  String? removeProduct(String id) {
    final used = moves.any((move) => move.productId == id) ||
        docs.any((doc) => doc.lines.any((line) => line.productId == id));
    final product = productById(id);
    if (product == null) return 'Ürün yok';
    if (used) {
      product.active = false;
      _touch();
      return 'Hareketi olan ürün pasife alındı';
    }
    products.removeWhere((item) => item.id == id);
    _touch();
    return null;
  }

  void upsertParty(Party party) {
    if (party.id.isEmpty) party.id = newId();
    final index = parties.indexWhere((item) => item.id == party.id);
    if (index >= 0) {
      parties[index] = party;
    } else {
      parties.add(party);
    }
    _touch();
  }

  String? removeParty(String id) {
    final used = docs.any((doc) => doc.partyId == id) ||
        payments.any((item) => item.partyId == id) ||
        instruments.any((item) => item.partyId == id);
    final party = partyById(id);
    if (party == null) return 'Cari yok';
    if (used) {
      party.active = false;
      _touch();
      return 'Hareketi olan cari pasife alındı';
    }
    parties.removeWhere((item) => item.id == id);
    _touch();
    return null;
  }

  void upsertPriceList(PriceList list) {
    if (list.id.isEmpty) list.id = newId();
    final index = priceLists.indexWhere((item) => item.id == list.id);
    if (index >= 0) {
      priceLists[index] = list;
    } else {
      priceLists.add(list);
    }
    _touch();
  }

  SpecialPrice? specialPrice(String partyId, String productId) {
    for (final item in specialPrices) {
      if (item.partyId == partyId && item.productId == productId) return item;
    }
    return null;
  }

  void setSpecialPrice({required String partyId, required String productId, required double price}) {
    final existing = specialPrice(partyId, productId);
    if (existing != null) {
      existing.price = round2(price);
    } else {
      specialPrices.add(SpecialPrice(id: newId(), partyId: partyId, productId: productId, price: round2(price)));
    }
    _touch();
  }

  void removeSpecialPrice(String partyId, String productId) {
    specialPrices.removeWhere((item) => item.partyId == partyId && item.productId == productId);
    _touch();
  }

  List<TradeDoc> openWaybills() {
    return docs.where((doc) {
      final waybill = doc.kind == DocKind.saleWaybill || doc.kind == DocKind.purchaseWaybill;
      return waybill && doc.status == DocStatus.approved;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String? setPromise(String id, DateTime? date) {
    final doc = docById(id);
    if (doc == null) return 'Belge yok';
    if (doc.kind != DocKind.sale) return 'Söz yalnız satış faturasına yazılır';
    doc.promiseDate = date;
    _touch();
    return null;
  }

  String? countCash(double counted) {
    final account = accountByRole(AccountRole.cash);
    if (account == null) return 'Kasa tanımlı değil';
    final system = accountBalance(account.id);
    final diff = round2(counted - system);
    if (diff.abs() < 0.009) return 'Fark yok';
    final inbound = diff > 0;
    final year = DateTime.now().year;
    final seq = payments.where((item) => item.note.startsWith('Kasa sayımı') && item.date.year == year).length + 1;
    return addPayment(Payment(
      id: '',
      no: 'KS-$year-${seq.toString().padLeft(4, '0')}',
      date: DateTime.now(),
      accountId: account.id,
      direction: inbound ? PayDirection.inbound : PayDirection.outbound,
      method: PayMethod.cash,
      amount: diff.abs(),
      note: 'Kasa sayımı ${inbound ? 'fazlası' : 'eksiği'}',
    ));
  }

  ({double sales, double profit, double prevSales, double prevProfit}) monthCompare() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);
    final prevFrom = DateTime(now.year, now.month - 1, 1);
    final prevTo = DateTime(now.year, now.month, 0);
    return (
      sales: salesTotal(from: from, to: to),
      profit: grossProfit(from: from, to: to),
      prevSales: salesTotal(from: prevFrom, to: prevTo),
      prevProfit: grossProfit(from: prevFrom, to: prevTo),
    );
  }

  void removePriceList(String id) {
    priceLists.removeWhere((item) => item.id == id);
    for (final party in parties) {
      if (party.priceListId == id) party.priceListId = '';
    }
    _touch();
  }

  String? addDraft(TradeDoc doc) {
    if (doc.partyId.isEmpty) return 'Cari seçin';
    if (doc.warehouseId.isEmpty) return 'Depo seçin';
    if (doc.lines.isEmpty) return 'En az bir kalem ekleyin';
    if (doc.lines.any((line) => line.qty <= 0)) return 'Miktar sıfırdan büyük olmalı';
    if (doc.id.isEmpty) doc.id = newId();
    if (doc.no.isEmpty) doc.no = nextNo(doc.kind);
    final index = docs.indexWhere((item) => item.id == doc.id);
    if (index >= 0) {
      if (docs[index].status != DocStatus.draft) return 'Onaylı belge düzenlenemez';
      doc.status = DocStatus.draft;
      docs[index] = doc;
    } else {
      doc.status = DocStatus.draft;
      docs.add(doc);
    }
    _touch();
    return null;
  }

  String? approveDoc(String id) {
    final doc = docById(id);
    if (doc == null) return 'Belge yok';
    if (doc.status == DocStatus.approved || doc.status == DocStatus.invoiced) return null;
    if (doc.status == DocStatus.cancelled) return 'İptal edilmiş belge onaylanamaz';
    if (doc.lines.isEmpty) return 'Kalem yok';
    doc.status = DocStatus.approved;
    final source = doc.sourceDocId.isEmpty ? null : docById(doc.sourceDocId);
    final coveredByWaybill = source != null &&
        (source.kind == DocKind.saleWaybill || source.kind == DocKind.purchaseWaybill);
    if (kindAffectsStock(doc.kind) && !doc.stockPosted && !coveredByWaybill) {
      _postStock(doc, reverse: false);
      doc.stockPosted = true;
    }
    if (source != null &&
        source.status == DocStatus.approved &&
        (source.kind == DocKind.saleOrder ||
            source.kind == DocKind.purchaseOrder ||
            source.kind == DocKind.saleWaybill ||
            source.kind == DocKind.purchaseWaybill ||
            source.kind == DocKind.saleQuote)) {
      source.status = DocStatus.invoiced;
    }
    _touch();
    return null;
  }

  String? cancelDoc(String id) {
    final doc = docById(id);
    if (doc == null) return 'Belge yok';
    if (doc.status == DocStatus.cancelled) return null;
    if (doc.status == DocStatus.invoiced) return 'Faturalanmış belge iptal edilemez';
    final spawned = docs.any(
      (item) => item.sourceDocId == doc.id && item.status != DocStatus.cancelled,
    );
    if (spawned) return 'Bu belgeye bağlı fatura varken iptal edilemez';
    if (doc.stockPosted) {
      _postStock(doc, reverse: true);
      doc.stockPosted = false;
    }
    doc.status = DocStatus.cancelled;
    _touch();
    return null;
  }

  String? setEDoc(String id, EDocStatus status) {
    final doc = docById(id);
    if (doc == null) return 'Belge yok';
    doc.eDoc = status;
    _touch();
    return null;
  }

  String? invoiceFrom(String id) {
    final source = docById(id);
    if (source == null) return 'Belge yok';
    final DocKind? target = switch (source.kind) {
      DocKind.saleOrder || DocKind.saleWaybill || DocKind.saleQuote => DocKind.sale,
      DocKind.purchaseOrder || DocKind.purchaseWaybill => DocKind.purchase,
      _ => null,
    };
    if (target == null) return 'Bu belge faturalanamaz';
    if (source.status != DocStatus.approved) return 'Önce belgeyi onaylayın';
    final party = partyById(source.partyId);
    final now = DateTime.now();
    final invoice = TradeDoc(
      id: newId(),
      kind: target,
      status: DocStatus.draft,
      no: '',
      date: now,
      dueDate: now.add(Duration(days: party?.termDays ?? profile.defaultTermDays)),
      partyId: source.partyId,
      warehouseId: source.warehouseId,
      lines: source.lines.map((line) => line.copy()).toList(),
      note: '${docKindLabel(source.kind)} ${source.no}',
      shipping: source.shipping,
      sourceDocId: source.id,
    );
    final draftError = addDraft(invoice);
    if (draftError != null) return draftError;
    return approveDoc(invoice.id);
  }

  void _postStock(TradeDoc doc, {required bool reverse}) {
    final inbound = kindIsInbound(doc.kind);
    final direction = (inbound ? 1 : -1) * (reverse ? -1 : 1);
    for (final line in doc.lines) {
      moves.add(
        StockMove(
          id: newId(),
          date: DateTime.now(),
          productId: line.productId,
          warehouseId: doc.warehouseId,
          type: MoveType.document,
          qty: direction * line.qty,
          unitCost: line.unitPrice,
          docId: doc.id,
          note: '${reverse ? 'İptal ' : ''}${doc.no}',
        ),
      );
      _applySerials(doc, line, inbound: inbound, reverse: reverse);
    }
  }

  SerialUnit? serialByCode(String code) {
    final key = code.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final item in serials) {
      if (item.serial.toLowerCase() == key) return item;
    }
    return null;
  }

  void _applySerials(
    TradeDoc doc,
    DocLine line, {
    required bool inbound,
    required bool reverse,
  }) {
    final product = productById(line.productId);
    for (final raw in line.serials) {
      final code = raw.trim();
      if (code.isEmpty) continue;
      final existing = serialByCode(code);
      if (!reverse && inbound) {
        if (existing == null) {
          serials.add(
            SerialUnit(
              id: newId(),
              serial: code,
              productId: line.productId,
              warehouseId: doc.warehouseId,
              status: SerialStatus.inStock,
              docId: doc.id,
            ),
          );
        } else {
          existing
            ..status = SerialStatus.inStock
            ..warehouseId = doc.warehouseId
            ..partyId = ''
            ..soldAt = null
            ..warrantyUntil = null
            ..docId = doc.id;
        }
      } else if (!reverse && !inbound) {
        final sold = doc.kind == DocKind.purchaseReturn ? SerialStatus.returned : SerialStatus.sold;
        final warranty = doc.kind == DocKind.sale && product != null
            ? addMonths(doc.date, product.warrantyMonths)
            : null;
        if (existing == null) {
          serials.add(
            SerialUnit(
              id: newId(),
              serial: code,
              productId: line.productId,
              warehouseId: doc.warehouseId,
              status: sold,
              partyId: doc.partyId,
              soldAt: doc.kind == DocKind.sale ? doc.date : null,
              warrantyUntil: warranty,
              docId: doc.id,
            ),
          );
        } else {
          existing
            ..status = sold
            ..partyId = doc.partyId
            ..docId = doc.id;
          if (doc.kind == DocKind.sale) {
            existing
              ..soldAt = doc.date
              ..warrantyUntil = warranty;
          }
        }
      } else if (reverse && inbound) {
        if (existing == null) continue;
        if (doc.kind == DocKind.saleReturn) {
          existing
            ..status = SerialStatus.sold
            ..partyId = doc.partyId;
        } else {
          existing.status = SerialStatus.returned;
        }
      } else if (existing != null) {
        existing
          ..status = SerialStatus.inStock
          ..warehouseId = doc.warehouseId
          ..partyId = ''
          ..soldAt = null
          ..warrantyUntil = null;
      }
    }
  }

  String? manualMove({
    required String productId,
    required String warehouseId,
    required double qty,
    double unitCost = 0,
    String note = '',
    List<String> serialCodes = const [],
  }) {
    if (qty == 0) return 'Miktar sıfır olamaz';
    if (productById(productId) == null) return 'Ürün yok';
    moves.add(
      StockMove(
        id: newId(),
        date: DateTime.now(),
        productId: productId,
        warehouseId: warehouseId,
        type: MoveType.manual,
        qty: qty,
        unitCost: unitCost,
        note: note.isEmpty ? (qty > 0 ? 'Manuel giriş' : 'Manuel çıkış') : note,
      ),
    );
    if (qty > 0) {
      for (final raw in serialCodes) {
        final code = raw.trim();
        if (code.isEmpty || serialByCode(code) != null) continue;
        serials.add(
          SerialUnit(
            id: newId(),
            serial: code,
            productId: productId,
            warehouseId: warehouseId,
          ),
        );
      }
    }
    _touch();
    return null;
  }

  String? transfer({
    required String productId,
    required String fromId,
    required String toId,
    required double qty,
    String note = '',
  }) {
    if (fromId == toId) return 'Depolar farklı olmalı';
    if (qty <= 0) return 'Miktar sıfırdan büyük olmalı';
    final group = newId();
    final text = note.isEmpty ? 'Depo transferi' : note;
    moves.add(
      StockMove(
        id: newId(),
        date: DateTime.now(),
        productId: productId,
        warehouseId: fromId,
        type: MoveType.transfer,
        qty: -qty,
        transferId: group,
        note: text,
      ),
    );
    moves.add(
      StockMove(
        id: newId(),
        date: DateTime.now(),
        productId: productId,
        warehouseId: toId,
        type: MoveType.transfer,
        qty: qty,
        transferId: group,
        note: text,
      ),
    );
    _touch();
    return null;
  }

  int applyCount(String warehouseId, Map<String, double> counted, {String note = 'Sayım'}) {
    var changes = 0;
    for (final entry in counted.entries) {
      final delta = ((entry.value - stockOf(entry.key, warehouseId: warehouseId)) * 1000).roundToDouble() / 1000.0;
      if (delta.abs() < 0.0001) continue;
      moves.add(
        StockMove(
          id: newId(),
          date: DateTime.now(),
          productId: entry.key,
          warehouseId: warehouseId,
          type: MoveType.count,
          qty: delta,
          note: note,
        ),
      );
      changes++;
    }
    if (changes > 0) _touch();
    return changes;
  }

  List<String> stockWarnings(TradeDoc doc) {
    if (!kindAffectsStock(doc.kind) || kindIsInbound(doc.kind)) return const [];
    final warnings = <String>[];
    for (final line in doc.lines) {
      final onHand = stockOf(line.productId, warehouseId: doc.warehouseId);
      final reserved = reservedOf(line.productId, warehouseId: doc.warehouseId, exceptDocId: doc.sourceDocId);
      final free = ((onHand - reserved) * 1000).roundToDouble() / 1000.0;
      if (free + 0.0001 < line.qty) {
        final name = productName(line.productId);
        warnings.add(
          reserved > 0.0001
              ? '$name: satılabilir ${qtyText(free)} (elde ${qtyText(onHand)}, rezerve ${qtyText(reserved)}), çıkış ${qtyText(line.qty)}'
              : '$name: depoda ${qtyText(onHand)}, çıkış ${qtyText(line.qty)}',
        );
      }
    }
    return warnings;
  }

  List<String> limitWarnings(TradeDoc doc) {
    if (doc.kind != DocKind.sale) return const [];
    final party = partyById(doc.partyId);
    if (party == null || party.creditLimit <= 0) return const [];
    final next = partyBalance(party.id) + doc.gross;
    if (next <= party.creditLimit + 0.009) return const [];
    return ['${party.name}: limit ${money(party.creditLimit)}, belge sonrası ${money(next)}'];
  }

  String? setDelivery(String id, DeliveryStatus status) {
    final doc = docById(id);
    if (doc == null) return 'Belge yok';
    doc.deliveryStatus = status;
    _touch();
    return null;
  }

  List<Product> frequentProducts(String partyId, {int limit = 6}) {
    if (partyId.isEmpty) return const [];
    final qty = <String, double>{};
    for (final doc in docs) {
      if (doc.partyId != partyId || doc.status != DocStatus.approved || doc.kind != DocKind.sale) continue;
      for (final line in doc.lines) {
        qty[line.productId] = (qty[line.productId] ?? 0) + line.qty;
      }
    }
    final ids = qty.keys.toList()..sort((a, b) => qty[b]!.compareTo(qty[a]!));
    return [
      for (final id in ids.take(limit))
        if (productById(id) != null && productById(id)!.active) productById(id)!,
    ];
  }

  List<SlowItem> slowProducts({int days = 90}) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final last = <String, DateTime>{};
    for (final doc in docs) {
      if (doc.status != DocStatus.approved) continue;
      if (doc.kind != DocKind.sale && doc.kind != DocKind.saleWaybill) continue;
      for (final line in doc.lines) {
        final prev = last[line.productId];
        if (prev == null || doc.date.isAfter(prev)) last[line.productId] = doc.date;
      }
    }
    final items = <SlowItem>[];
    for (final product in products) {
      if (!product.active) continue;
      final onHand = stockOf(product.id);
      if (onHand <= 0.0001) continue;
      final sold = last[product.id];
      if (sold != null && day.difference(DateTime(sold.year, sold.month, sold.day)).inDays < days) continue;
      items.add(SlowItem(product: product, onHand: onHand, lastSale: sold));
    }
    items.sort((a, b) => (a.lastSale ?? DateTime(2000)).compareTo(b.lastSale ?? DateTime(2000)));
    return items;
  }

  List<({Product product, double qty, double profit})> productProfits({DateTime? from, DateTime? to}) {
    final qty = <String, double>{};
    final profit = <String, double>{};
    for (final doc in docs) {
      if (doc.status != DocStatus.approved || !_inRange(doc.date, from, to)) continue;
      if (doc.kind != DocKind.sale && doc.kind != DocKind.saleReturn) continue;
      final sign = doc.kind == DocKind.sale ? 1.0 : -1.0;
      for (final line in doc.lines) {
        final cost = (productById(line.productId)?.purchasePrice ?? 0) * line.qty;
        qty[line.productId] = (qty[line.productId] ?? 0) + sign * line.qty;
        profit[line.productId] = (profit[line.productId] ?? 0) + sign * (line.net - cost);
      }
    }
    final rows = <({Product product, double qty, double profit})>[];
    for (final entry in profit.entries) {
      final product = productById(entry.key);
      if (product == null) continue;
      rows.add((product: product, qty: qty[entry.key] ?? 0, profit: round2(entry.value)));
    }
    rows.sort((a, b) => a.profit.compareTo(b.profit));
    return rows;
  }

  List<String> marginWarnings(TradeDoc doc) {
    final selling = doc.kind == DocKind.sale ||
        doc.kind == DocKind.saleOrder ||
        doc.kind == DocKind.saleWaybill ||
        doc.kind == DocKind.saleQuote;
    if (!selling) return const [];
    final warnings = <String>[];
    for (final line in doc.lines) {
      final product = productById(line.productId);
      if (product == null || product.purchasePrice <= 0 || line.qty <= 0) continue;
      final netUnit = line.net / line.qty;
      if (netUnit + 0.009 < product.purchasePrice) {
        warnings.add('${product.name}: satış ${money(netUnit)}, alış ${money(product.purchasePrice)}');
      }
    }
    return warnings;
  }

  List<ReorderNeed> reorderNeeds() {
    final needs = <ReorderNeed>[];
    for (final product in products) {
      if (!product.active || product.minStock <= 0) continue;
      final onHand = stockOf(product.id);
      final short = ((product.minStock - onHand) * 1000).roundToDouble() / 1000.0;
      if (short <= 0.0001) continue;
      var supplierId = '';
      var lastCost = 0.0;
      DateTime? latest;
      for (final doc in docs) {
        if (doc.status != DocStatus.approved) continue;
        if (doc.kind != DocKind.purchase && doc.kind != DocKind.purchaseWaybill) continue;
        final hits = doc.lines.where((line) => line.productId == product.id).toList();
        if (hits.isEmpty) continue;
        if (latest != null && !doc.date.isAfter(latest)) continue;
        latest = doc.date;
        supplierId = doc.partyId;
        lastCost = hits.last.unitPrice;
      }
      needs.add(ReorderNeed(
        product: product,
        onHand: onHand,
        shortQty: short,
        supplierId: supplierId,
        lastCost: lastCost,
      ));
    }
    needs.sort((a, b) => b.shortQty.compareTo(a.shortQty));
    return needs;
  }

  List<String> draftReorderOrders() {
    final groups = <String, List<ReorderNeed>>{};
    for (final need in reorderNeeds()) {
      if (need.supplierId.isEmpty) continue;
      groups.putIfAbsent(need.supplierId, () => []).add(need);
    }
    if (warehouses.isEmpty) return const [];
    final nos = <String>[];
    final now = DateTime.now();
    for (final entry in groups.entries) {
      final party = partyById(entry.key);
      final doc = TradeDoc(
        id: '',
        kind: DocKind.purchaseOrder,
        status: DocStatus.draft,
        no: '',
        date: now,
        dueDate: now.add(Duration(days: party?.termDays ?? profile.defaultTermDays)),
        partyId: entry.key,
        warehouseId: warehouses.first.id,
        lines: [
          for (final need in entry.value)
            DocLine(
              productId: need.product.id,
              qty: need.shortQty,
              unitPrice: need.lastCost > 0 ? need.lastCost : need.product.purchasePrice,
              vatRate: need.product.vatRate,
            ),
        ],
      );
      if (addDraft(doc) == null) nos.add(doc.no);
    }
    return nos;
  }

  ({String? error, int count}) adjustPrices({
    String brand = '',
    String category = '',
    required double percent,
    bool sale = true,
    bool purchase = false,
  }) {
    if (!sale && !purchase) return (error: 'Satış veya alış fiyatını seçin', count: 0);
    if (percent == 0) return (error: 'Yüzde sıfır olamaz', count: 0);
    if (brand.isEmpty && category.isEmpty) return (error: 'Marka veya kategori seçin', count: 0);
    final factor = 1 + percent / 100;
    if (factor < 0) return (error: 'Fiyat eksiye düşemez', count: 0);
    var count = 0;
    for (final product in products) {
      if (brand.isNotEmpty && product.brand != brand) continue;
      if (category.isNotEmpty && product.category != category) continue;
      if (sale) product.salePrice = round2(product.salePrice * factor);
      if (purchase) product.purchasePrice = round2(product.purchasePrice * factor);
      count++;
    }
    if (count == 0) return (error: 'Bu filtrede ürün yok', count: 0);
    _touch();
    return (error: null, count: count);
  }

  double partyBalance(String partyId) {
    var balance = 0.0;
    for (final doc in docs) {
      if (doc.partyId != partyId || doc.status != DocStatus.approved) continue;
      balance += _cariDelta(doc);
    }
    for (final payment in payments) {
      if (payment.partyId != partyId) continue;
      balance += payment.direction == PayDirection.inbound ? -payment.amount : payment.amount;
    }
    for (final ticket in tickets) {
      if (ticket.partyId == partyId && ticket.feeInvoiced) balance += ticket.fee;
    }
    return round2(balance);
  }

  double _cariDelta(TradeDoc doc) {
    switch (doc.kind) {
      case DocKind.sale:
        return doc.gross;
      case DocKind.saleReturn:
        return -doc.gross;
      case DocKind.purchase:
        return -doc.gross;
      case DocKind.purchaseReturn:
        return doc.gross;
      default:
        return 0;
    }
  }

  PayDirection closingDirection(DocKind kind) {
    switch (kind) {
      case DocKind.sale:
      case DocKind.purchaseReturn:
        return PayDirection.inbound;
      default:
        return PayDirection.outbound;
    }
  }

  double docPaid(TradeDoc doc) {
    final closing = closingDirection(doc.kind);
    var paid = 0.0;
    for (final payment in payments) {
      if (payment.docId != doc.id) continue;
      paid += payment.direction == closing ? payment.amount : -payment.amount;
    }
    return round2(paid);
  }

  double docRemaining(TradeDoc doc) {
    if (doc.status != DocStatus.approved || !kindAffectsCari(doc.kind)) return 0;
    return round2(doc.gross - docPaid(doc));
  }

  List<LedgerRow> statement(String partyId) {
    final rows = <LedgerRow>[];
    for (final doc in docs) {
      if (doc.partyId != partyId || doc.status != DocStatus.approved) continue;
      final gross = doc.gross;
      switch (doc.kind) {
        case DocKind.sale:
          rows.add(LedgerRow(doc.date, 'Satış ${doc.no}', gross, 0));
        case DocKind.saleReturn:
          rows.add(LedgerRow(doc.date, 'Satış iadesi ${doc.no}', 0, gross));
        case DocKind.purchase:
          rows.add(LedgerRow(doc.date, 'Alış ${doc.no}', 0, gross));
        case DocKind.purchaseReturn:
          rows.add(LedgerRow(doc.date, 'Alış iadesi ${doc.no}', gross, 0));
        default:
          break;
      }
    }
    for (final payment in payments) {
      if (payment.partyId != partyId) continue;
      final title = '${payment.direction == PayDirection.inbound ? 'Tahsilat' : 'Ödeme'} ${payment.no}';
      if (payment.direction == PayDirection.inbound) {
        rows.add(LedgerRow(payment.date, title, 0, payment.amount));
      } else {
        rows.add(LedgerRow(payment.date, title, payment.amount, 0));
      }
    }
    for (final ticket in tickets) {
      if (ticket.partyId != partyId || !ticket.feeInvoiced || ticket.fee <= 0) continue;
      rows.add(LedgerRow(ticket.date, 'Servis ${ticket.no}', ticket.fee, 0));
    }
    rows.sort((a, b) => a.date.compareTo(b.date));
    return rows;
  }

  ({double opening, List<LedgerRow> rows}) statementBetween(String partyId, DateTime? from, DateTime? to) {
    final openingDay = from == null ? null : DateTime(from.year, from.month, from.day);
    final closingDay = to == null ? null : DateTime(to.year, to.month, to.day);
    var opening = 0.0;
    final rows = <LedgerRow>[];
    for (final row in statement(partyId)) {
      final day = DateTime(row.date.year, row.date.month, row.date.day);
      final before = openingDay != null && day.isBefore(openingDay);
      final after = closingDay != null && day.isAfter(closingDay);
      if (before) {
        opening = round2(opening + row.debit - row.credit);
      } else if (!after) {
        rows.add(row);
      }
    }
    return (opening: round2(opening), rows: rows);
  }

  String? transferParties(String fromId, String toId, double amount, {String note = ''}) {
    if (fromId.isEmpty || toId.isEmpty) return 'İki cari seçin';
    if (fromId == toId) return 'Aynı cariye virman olmaz';
    if (amount <= 0) return 'Tutar girin';
    if (partyById(fromId) == null || partyById(toId) == null) return 'Cari bulunamadı';
    final account = accountByRole(AccountRole.cash);
    if (account == null) return 'Kasa tanımlı değil';
    final group = newId();
    final now = DateTime.now();
    final fromName = partyName(fromId);
    final toName = partyName(toId);
    final extra = note.trim().isEmpty ? '' : ' · ${note.trim()}';
    payments.add(Payment(
      id: newId(),
      no: nextPayNo(PayDirection.inbound),
      date: now,
      accountId: account.id,
      direction: PayDirection.inbound,
      method: PayMethod.transfer,
      amount: amount,
      partyId: fromId,
      groupId: group,
      note: 'Virman → $toName$extra',
    ));
    payments.add(Payment(
      id: newId(),
      no: nextPayNo(PayDirection.outbound),
      date: now,
      accountId: account.id,
      direction: PayDirection.outbound,
      method: PayMethod.transfer,
      amount: amount,
      partyId: toId,
      groupId: group,
      note: 'Virman ← $fromName$extra',
    ));
    _touch();
    return null;
  }

  ({double salesVat, double purchaseVat}) vatSummary({DateTime? from, DateTime? to}) {
    var salesVat = 0.0;
    var purchaseVat = 0.0;
    for (final doc in docs) {
      if (doc.status != DocStatus.approved || !_inRange(doc.date, from, to)) continue;
      switch (doc.kind) {
        case DocKind.sale:
          salesVat += doc.vatTotal;
        case DocKind.saleReturn:
          salesVat -= doc.vatTotal;
        case DocKind.purchase:
          purchaseVat += doc.vatTotal;
        case DocKind.purchaseReturn:
          purchaseVat -= doc.vatTotal;
        default:
          break;
      }
    }
    return (salesVat: round2(salesVat), purchaseVat: round2(purchaseVat));
  }

  List<AgendaEntry> agenda({int withinDays = 21}) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final until = day.add(Duration(days: withinDays));
    final items = <AgendaEntry>[];
    for (final doc in docs) {
      if (doc.kind != DocKind.sale || doc.status != DocStatus.approved) continue;
      final remaining = docRemaining(doc);
      if (remaining <= 0.009) continue;
      final due = DateTime(doc.dueDate.year, doc.dueDate.month, doc.dueDate.day);
      if (due.isAfter(until)) continue;
      items.add(AgendaEntry(
        day: due,
        title: doc.no,
        subtitle: '${partyName(doc.partyId)} · satış faturası${doc.promiseDate == null ? '' : ' · söz ${shortDate(doc.promiseDate!)}'}',
        amount: remaining,
        late: due.isBefore(day),
        partyId: doc.partyId,
        docId: doc.id,
        check: false,
      ));
    }
    for (final item in instruments) {
      final open = item.status == InstrumentStatus.portfolio || item.status == InstrumentStatus.deposited;
      if (!open) continue;
      final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
      if (due.isAfter(until)) continue;
      final received = item.direction == InstrumentDirection.received;
      final label = item.kind == InstrumentKind.check ? 'çek' : 'senet';
      items.add(AgendaEntry(
        day: due,
        title: item.no,
        subtitle: '${partyName(item.partyId)} · ${received ? 'alınan' : 'verilen'} $label',
        amount: item.amount,
        late: due.isBefore(day),
        partyId: item.partyId,
        check: true,
      ));
    }
    items.sort((a, b) => a.day.compareTo(b.day));
    return items;
  }

  bool partyFits(Party party, DocKind kind) {
    if (!party.active) return false;
    final selling = kind == DocKind.sale ||
        kind == DocKind.saleReturn ||
        kind == DocKind.saleOrder ||
        kind == DocKind.saleWaybill ||
        kind == DocKind.saleQuote;
    if (selling) return party.type != PartyType.supplier;
    return party.type != PartyType.customer;
  }

  String? addPayment(Payment payment) {
    if (payment.amount <= 0) return 'Tutar girin';
    if (accountById(payment.accountId) == null) return 'Hesap seçin';
    if (payment.id.isEmpty) payment.id = newId();
    if (payment.no.isEmpty) payment.no = nextPayNo(payment.direction);
    payments.add(payment);
    _touch();
    return null;
  }

  double accountBalance(String accountId) {
    var balance = 0.0;
    for (final payment in payments) {
      if (payment.accountId != accountId) continue;
      balance += payment.direction == PayDirection.inbound ? payment.amount : -payment.amount;
    }
    return round2(balance);
  }

  void upsertAccount(CashAccount account) {
    if (account.id.isEmpty) account.id = newId();
    final index = accounts.indexWhere((item) => item.id == account.id);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    _touch();
  }

  String? addInstrument(Instrument instrument) {
    if (instrument.amount <= 0) return 'Tutar girin';
    if (instrument.partyId.isEmpty) return 'Cari seçin';
    if (instrument.no.trim().isEmpty) return 'Evrak no girin';
    final role = instrument.direction == InstrumentDirection.received
        ? AccountRole.checkPortfolio
        : AccountRole.issuedChecks;
    final account = accountByRole(role);
    if (account == null) return 'Çek hesabı tanımlı değil';
    if (instrument.id.isEmpty) instrument.id = newId();
    instrument.status = InstrumentStatus.portfolio;
    instrument.accountId = account.id;
    instruments.add(instrument);
    payments.add(
      Payment(
        id: newId(),
        no: nextPayNo(
          instrument.direction == InstrumentDirection.received
              ? PayDirection.inbound
              : PayDirection.outbound,
        ),
        date: instrument.issueDate,
        partyId: instrument.partyId,
        docId: instrument.docId,
        accountId: account.id,
        direction: instrument.direction == InstrumentDirection.received
            ? PayDirection.inbound
            : PayDirection.outbound,
        method: instrument.kind == InstrumentKind.check ? PayMethod.check : PayMethod.note,
        amount: instrument.amount,
        instrumentId: instrument.id,
        note: '${instrument.no} kaydı',
      ),
    );
    _touch();
    return null;
  }

  bool _openInstrument(Instrument item) {
    return item.status == InstrumentStatus.portfolio || item.status == InstrumentStatus.deposited;
  }

  String? markDeposited(String id) {
    final item = _instrument(id);
    if (item == null) return 'Evrak yok';
    if (item.direction != InstrumentDirection.received || item.status != InstrumentStatus.portfolio) {
      return 'Yalnız portföydeki alınan evrak tahsile verilir';
    }
    item.status = InstrumentStatus.deposited;
    _touch();
    return null;
  }

  String? collectInstrument(String id, String bankAccountId) {
    final item = _instrument(id);
    if (item == null) return 'Evrak yok';
    if (item.direction != InstrumentDirection.received || !_openInstrument(item)) {
      return 'Bu evrak tahsil edilemez';
    }
    if (accountById(bankAccountId)?.role != AccountRole.bank &&
        accountById(bankAccountId)?.role != AccountRole.cash) {
      return 'Kasa veya banka seçin';
    }
    _transfer(item.accountId, bankAccountId, item.amount, 'Tahsil ${item.no}');
    item.status = InstrumentStatus.collected;
    _touch();
    return null;
  }

  String? payInstrument(String id, String bankAccountId) {
    final item = _instrument(id);
    if (item == null) return 'Evrak yok';
    if (item.direction != InstrumentDirection.issued || item.status != InstrumentStatus.portfolio) {
      return 'Bu evrak ödenemez';
    }
    final bank = accountById(bankAccountId);
    if (bank == null || (bank.role != AccountRole.bank && bank.role != AccountRole.cash)) {
      return 'Kasa veya banka seçin';
    }
    _transfer(bankAccountId, item.accountId, item.amount, 'Ödeme ${item.no}');
    item.status = InstrumentStatus.paid;
    _touch();
    return null;
  }

  String? bounceInstrument(String id) {
    final item = _instrument(id);
    if (item == null) return 'Evrak yok';
    if (!_openInstrument(item)) return 'Kapalı evrak karşılıksız işaretlenemez';
    if (item.direction == InstrumentDirection.received) {
      payments.add(
        Payment(
          id: newId(),
          no: nextPayNo(PayDirection.outbound),
          date: DateTime.now(),
          partyId: item.partyId,
          docId: item.docId,
          accountId: item.accountId,
          direction: PayDirection.outbound,
          method: item.kind == InstrumentKind.check ? PayMethod.check : PayMethod.note,
          amount: item.amount,
          instrumentId: item.id,
          note: 'Karşılıksız ${item.no}',
        ),
      );
    } else {
      payments.add(
        Payment(
          id: newId(),
          no: nextPayNo(PayDirection.inbound),
          date: DateTime.now(),
          partyId: item.partyId,
          docId: item.docId,
          accountId: item.accountId,
          direction: PayDirection.inbound,
          method: item.kind == InstrumentKind.check ? PayMethod.check : PayMethod.note,
          amount: item.amount,
          instrumentId: item.id,
          note: 'Karşılıksız ${item.no}',
        ),
      );
    }
    item.status = InstrumentStatus.bounced;
    _touch();
    return null;
  }

  String? endorseInstrument(String id, String supplierId, {String docId = ''}) {
    final item = _instrument(id);
    if (item == null) return 'Evrak yok';
    if (item.direction != InstrumentDirection.received || item.status != InstrumentStatus.portfolio) {
      return 'Yalnız portföydeki alınan evrak ciro edilir';
    }
    if (partyById(supplierId)?.type == PartyType.customer) return 'Ciro için tedarikçi seçin';
    payments.add(
      Payment(
        id: newId(),
        no: nextPayNo(PayDirection.outbound),
        date: DateTime.now(),
        partyId: supplierId,
        docId: docId,
        accountId: item.accountId,
        direction: PayDirection.outbound,
        method: item.kind == InstrumentKind.check ? PayMethod.check : PayMethod.note,
        amount: item.amount,
        instrumentId: item.id,
        note: 'Ciro ${item.no}',
      ),
    );
    item
      ..status = InstrumentStatus.endorsed
      ..endorsedToPartyId = supplierId;
    _touch();
    return null;
  }

  String? returnInstrument(String id) {
    final item = _instrument(id);
    if (item == null) return 'Evrak yok';
    if (item.direction != InstrumentDirection.received || item.status != InstrumentStatus.portfolio) {
      return 'Yalnız portföydeki evrak iade edilir';
    }
    payments.add(
      Payment(
        id: newId(),
        no: nextPayNo(PayDirection.outbound),
        date: DateTime.now(),
        partyId: item.partyId,
        docId: item.docId,
        accountId: item.accountId,
        direction: PayDirection.outbound,
        method: item.kind == InstrumentKind.check ? PayMethod.check : PayMethod.note,
        amount: item.amount,
        instrumentId: item.id,
        note: 'İade ${item.no}',
      ),
    );
    item.status = InstrumentStatus.returned;
    _touch();
    return null;
  }

  Instrument? _instrument(String id) {
    for (final item in instruments) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _transfer(String fromId, String toId, double amount, String note) {
    final group = newId();
    payments.add(
      Payment(
        id: newId(),
        no: 'VR-${payments.length + 1}',
        date: DateTime.now(),
        accountId: fromId,
        direction: PayDirection.outbound,
        method: PayMethod.transfer,
        amount: amount,
        groupId: group,
        note: note,
      ),
    );
    payments.add(
      Payment(
        id: newId(),
        no: 'VR-${payments.length + 1}',
        date: DateTime.now(),
        accountId: toId,
        direction: PayDirection.inbound,
        method: PayMethod.transfer,
        amount: amount,
        groupId: group,
        note: note,
      ),
    );
  }

  void upsertTicket(ServiceTicket ticket) {
    if (ticket.id.isEmpty) ticket.id = newId();
    if (ticket.no.isEmpty) ticket.no = nextTicketNo();
    final index = tickets.indexWhere((item) => item.id == ticket.id);
    if (index >= 0) {
      tickets[index] = ticket;
    } else {
      tickets.add(ticket);
    }
    final unit = serialByCode(ticket.serial);
    if (unit != null) {
      if (ticket.status == TicketStatus.open ||
          ticket.status == TicketStatus.inProgress ||
          ticket.status == TicketStatus.waitingPart) {
        unit.status = SerialStatus.service;
      } else if (ticket.status == TicketStatus.done || ticket.status == TicketStatus.cancelled) {
        unit.status = unit.soldAt == null ? SerialStatus.inStock : SerialStatus.sold;
      }
    }
    _touch();
  }

  WarrantyLookup? lookupSerial(String query) {
    final unit = serialByCode(query);
    if (unit == null) return null;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    var inWarranty = false;
    int? daysLeft;
    final until = unit.warrantyUntil;
    if (until != null) {
      final end = DateTime(until.year, until.month, until.day);
      daysLeft = end.difference(day).inDays;
      inWarranty = !end.isBefore(day);
    }
    return WarrantyLookup(
      serial: unit,
      product: productById(unit.productId),
      party: unit.partyId.isEmpty ? null : partyById(unit.partyId),
      inWarranty: inWarranty,
      daysLeft: daysLeft,
    );
  }

  double stockValue({String? warehouseId}) {
    var total = 0.0;
    for (final product in products) {
      final qty = stockOf(product.id, warehouseId: warehouseId);
      if (qty > 0) total += qty * product.purchasePrice;
    }
    return round2(total);
  }

  double totalReceivable() {
    var total = 0.0;
    for (final party in parties) {
      final balance = partyBalance(party.id);
      if (balance > 0) total += balance;
    }
    return round2(total);
  }

  double totalPayable() {
    var total = 0.0;
    for (final party in parties) {
      final balance = partyBalance(party.id);
      if (balance < 0) total += -balance;
    }
    return round2(total);
  }

  bool _inRange(DateTime date, DateTime? from, DateTime? to) {
    final day = DateTime(date.year, date.month, date.day);
    if (from != null && day.isBefore(DateTime(from.year, from.month, from.day))) return false;
    if (to != null && day.isAfter(DateTime(to.year, to.month, to.day))) return false;
    return true;
  }

  double salesTotal({DateTime? from, DateTime? to}) {
    var total = 0.0;
    for (final doc in docs) {
      if (doc.status != DocStatus.approved || !_inRange(doc.date, from, to)) continue;
      if (doc.kind == DocKind.sale) total += doc.gross;
      if (doc.kind == DocKind.saleReturn) total -= doc.gross;
    }
    return round2(total);
  }

  List<CitySales> salesByCity() {
    final byParty = <String, double>{};
    for (final doc in docs) {
      if (doc.status != DocStatus.approved) continue;
      if (doc.kind != DocKind.sale && doc.kind != DocKind.saleReturn) continue;
      final sign = doc.kind == DocKind.sale ? 1.0 : -1.0;
      byParty[doc.partyId] = (byParty[doc.partyId] ?? 0) + sign * doc.gross;
    }
    final grouped = <String, List<CityFirmSale>>{};
    final totals = <String, double>{};
    for (final party in parties) {
      final key = foldCity(party.city);
      if (key.isEmpty) continue;
      final sales = round2(byParty[party.id] ?? 0);
      grouped.putIfAbsent(key, () => []).add(CityFirmSale(party, sales));
      totals[key] = (totals[key] ?? 0) + sales;
    }
    return [
      for (final entry in grouped.entries)
        CitySales(
          key: entry.key,
          sales: round2(totals[entry.key] ?? 0),
          firms: [...entry.value]..sort((a, b) => b.sales.compareTo(a.sales)),
        ),
    ]..sort((a, b) => b.sales.compareTo(a.sales));
  }

  double grossProfit({DateTime? from, DateTime? to}) {
    var profit = 0.0;
    for (final doc in docs) {
      if (doc.status != DocStatus.approved || !_inRange(doc.date, from, to)) continue;
      if (doc.kind != DocKind.sale && doc.kind != DocKind.saleReturn) continue;
      final sign = doc.kind == DocKind.sale ? 1.0 : -1.0;
      for (final line in doc.lines) {
        final cost = (productById(line.productId)?.purchasePrice ?? 0) * line.qty;
        profit += sign * (line.net - cost);
      }
    }
    return round2(profit);
  }

  List<Product> criticalProducts() {
    return products.where((product) => product.active && stockOf(product.id) <= product.minStock).toList();
  }

  List<TradeDoc> overdueSales() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    return docs.where((doc) {
      if (doc.kind != DocKind.sale || doc.status != DocStatus.approved) return false;
      final due = DateTime(doc.dueDate.year, doc.dueDate.month, doc.dueDate.day);
      if (!due.isBefore(day)) return false;
      return docRemaining(doc) > 0.009;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Instrument> upcomingInstruments({int withinDays = 14}) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final horizon = day.add(Duration(days: withinDays));
    return instruments.where((item) {
      if (item.status != InstrumentStatus.portfolio && item.status != InstrumentStatus.deposited) {
        return false;
      }
      final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
      return !due.isAfter(horizon);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Map<String, double> receivableAging() {
    final buckets = <String, double>{
      'Vadesi gelmemiş': 0,
      '1-30 gün': 0,
      '31-60 gün': 0,
      '61-90 gün': 0,
      '90+ gün': 0,
    };
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    for (final doc in docs) {
      if (doc.kind != DocKind.sale || doc.status != DocStatus.approved) continue;
      final remaining = docRemaining(doc);
      if (remaining <= 0.009) continue;
      final due = DateTime(doc.dueDate.year, doc.dueDate.month, doc.dueDate.day);
      final days = day.difference(due).inDays;
      final key = days <= 0
          ? 'Vadesi gelmemiş'
          : days <= 30
              ? '1-30 gün'
              : days <= 60
                  ? '31-60 gün'
                  : days <= 90
                      ? '61-90 gün'
                      : '90+ gün';
      buckets[key] = round2(buckets[key]! + remaining);
    }
    return buckets;
  }

  List<({Product product, double qty, double revenue})> topSellers({
    DateTime? from,
    DateTime? to,
    int limit = 5,
  }) {
    final totals = <String, (double, double)>{};
    for (final doc in docs) {
      if (doc.status != DocStatus.approved || !_inRange(doc.date, from, to)) continue;
      if (doc.kind != DocKind.sale && doc.kind != DocKind.saleReturn) continue;
      final sign = doc.kind == DocKind.sale ? 1.0 : -1.0;
      for (final line in doc.lines) {
        final prev = totals[line.productId] ?? (0.0, 0.0);
        totals[line.productId] = (prev.$1 + sign * line.qty, prev.$2 + sign * line.net);
      }
    }
    final rows = <({Product product, double qty, double revenue})>[];
    for (final entry in totals.entries) {
      final product = productById(entry.key);
      if (product == null) continue;
      rows.add((product: product, qty: entry.value.$1, revenue: round2(entry.value.$2)));
    }
    rows.sort((a, b) => b.revenue.compareTo(a.revenue));
    if (rows.length > limit) return rows.sublist(0, limit);
    return rows;
  }

  Map<String, double> salesByBrand({DateTime? from, DateTime? to}) {
    final totals = <String, double>{};
    for (final doc in docs) {
      if (doc.status != DocStatus.approved || !_inRange(doc.date, from, to)) continue;
      if (doc.kind != DocKind.sale && doc.kind != DocKind.saleReturn) continue;
      final sign = doc.kind == DocKind.sale ? 1.0 : -1.0;
      for (final line in doc.lines) {
        final brand = productById(line.productId)?.brand ?? 'Diğer';
        totals[brand] = round2((totals[brand] ?? 0) + sign * line.net);
      }
    }
    return totals;
  }

  List<SearchHit> search(String query) {
    final key = query.trim().toLowerCase();
    if (key.length < 2) return const [];
    final hits = <SearchHit>[];
    for (final product in products) {
      final blob = '${product.name} ${product.sku} ${product.barcode} ${product.brand}'.toLowerCase();
      if (blob.contains(key)) {
        hits.add(SearchHit('product', product.id, product.name, '${product.brand} · ${product.sku}'));
      }
    }
    for (final party in parties) {
      final blob = '${party.name} ${party.taxNo} ${party.city} ${party.phone}'.toLowerCase();
      if (blob.contains(key)) {
        hits.add(SearchHit('party', party.id, party.name, partyTypeLabel(party.type)));
      }
    }
    for (final doc in docs) {
      if (doc.no.toLowerCase().contains(key)) {
        hits.add(SearchHit('doc', doc.id, doc.no, '${docKindShort(doc.kind)} · ${partyName(doc.partyId)}'));
      }
    }
    for (final unit in serials) {
      if (unit.serial.toLowerCase().contains(key)) {
        hits.add(SearchHit('serial', unit.id, unit.serial, productName(unit.productId)));
      }
    }
    if (hits.length > 20) return hits.sublist(0, 20);
    return hits;
  }
}
