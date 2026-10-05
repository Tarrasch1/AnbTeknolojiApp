import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toptanci_takip/main.dart';
import 'package:toptanci_takip/src/models.dart';
import 'package:toptanci_takip/src/store.dart';
import 'package:toptanci_takip/src/ui/docs_page.dart';
import 'package:toptanci_takip/src/ui/print_page.dart';
import 'package:toptanci_takip/src/ui/scope.dart';
import 'package:toptanci_takip/src/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('örnek veri stok, çek ve yedek turunu korur', () async {
    final box = MemoryJsonBox();
    final store = AppStore(box: box);
    await store.ensureLoaded();

    expect(store.stockOf('p1'), 5);
    expect(store.criticalProducts().any((product) => product.id == 'p4'), isTrue);
    expect(store.stockOf('p11', warehouseId: 'w-anadolu'), 2);
    expect(store.stockOf('p11'), 5);

    final yildiz = store.partyBalance('c-yildiz');
    expect(yildiz, greaterThan(100000));
    final overdue = store.overdueSales();
    expect(overdue.map((doc) => doc.id), contains('d-sf-y1'));
    expect(store.docRemaining(store.docById('d-sf-y1')!), closeTo(store.docById('d-sf-y1')!.gross, 0.01));
    expect(store.partyBalance('c-ege'), closeTo(0, 0.05));
    expect(store.accountBalance('acc-portfoy'), closeTo(50000, 0.05));

    final raw = store.exportJson();
    final restored = AppStore(box: MemoryJsonBox());
    expect(restored.importJson(raw), isNull);
    expect(restored.stockOf('p1'), 5);
    expect(restored.partyBalance('c-yildiz'), closeTo(yildiz, 0.05));
    expect(store.vatSummary().salesVat, greaterThan(0));
    expect(store.agenda().any((item) => item.docId == 'd-sf-y1' && item.late), isTrue);
  });

  test('virman bakiyeyi taşır ve kasayı değiştirmez', () {
    final store = _bare();
    final sale = TradeDoc(
      id: 'sf',
      kind: DocKind.sale,
      status: DocStatus.draft,
      no: 'SF-1',
      date: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 11, 1),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 100, vatRate: 20)],
    );
    expect(store.addDraft(sale), isNull);
    expect(store.approveDoc('sf'), isNull);
    final cash = store.accountBalance('kasa');
    expect(store.transferParties('c', 's', 50, note: 'mahsup'), isNull);
    expect(store.partyBalance('c'), closeTo(70, 0.05));
    expect(store.partyBalance('s'), closeTo(50, 0.05));
    expect(store.accountBalance('kasa'), closeTo(cash, 0.05));
    final slice = store.statementBetween('c', DateTime(2026, 10, 1), DateTime(2026, 10, 31));
    expect(slice.opening, 0);
    expect(slice.rows, isNotEmpty);
  });

  test('irsaliye stoğu düşer, faturası cariyi işler ve stoğu ikinci kez düşmez', () {
    final store = _bare();
    final waybill = TradeDoc(
      id: 'irs',
      kind: DocKind.saleWaybill,
      status: DocStatus.draft,
      no: 'IRS-1',
      date: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 1),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 2, unitPrice: 100, vatRate: 20)],
    );
    expect(store.addDraft(waybill), isNull);
    expect(store.approveDoc('irs'), isNull);
    expect(store.stockOf('p'), 8);
    expect(store.partyBalance('c'), 0);

    expect(store.invoiceFrom('irs'), isNull);
    expect(store.stockOf('p'), 8);
    expect(store.docById('irs')!.status, DocStatus.invoiced);
    expect(store.partyBalance('c'), closeTo(240, 0.01));
  });

  test('satış iptali stoğu geri alır', () {
    final store = _bare();
    final sale = TradeDoc(
      id: 'sf',
      kind: DocKind.sale,
      status: DocStatus.draft,
      no: 'SF-1',
      date: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 9, 1),
      partyId: 'c',
      warehouseId: 'w',
      lines: [
        DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20, serials: ['SN1']),
      ],
    );
    store.addDraft(sale);
    store.approveDoc('sf');
    expect(store.stockOf('p'), 9);
    expect(store.serialByCode('SN1')!.status, SerialStatus.sold);
    expect(store.serialByCode('SN1')!.warrantyUntil, isNotNull);
    store.cancelDoc('sf');
    expect(store.stockOf('p'), 10);
    expect(store.partyBalance('c'), 0);
    expect(store.serialByCode('SN1')!.status, SerialStatus.inStock);
  });

  test('sayım farkı ve çek ciro tedarikçi borcunu düşer', () {
    final store = _bare();
    expect(store.applyCount('w', {'p': 7}), 1);
    expect(store.stockOf('p'), 7);

    final purchase = TradeDoc(
      id: 'af',
      kind: DocKind.purchase,
      status: DocStatus.draft,
      no: 'AF-1',
      date: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 10, 1),
      partyId: 's',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 100, vatRate: 0)],
    );
    store.addDraft(purchase);
    store.approveDoc('af');
    expect(store.partyBalance('s'), closeTo(-100, 0.01));

    expect(
      store.addInstrument(
        Instrument(
          id: 'cek',
          kind: InstrumentKind.check,
          direction: InstrumentDirection.received,
          no: 'C1',
          amount: 100,
          issueDate: DateTime(2026, 9, 2),
          dueDate: DateTime(2026, 10, 2),
          partyId: 'c',
        ),
      ),
      isNull,
    );
    expect(store.partyBalance('c'), closeTo(-100, 0.01));
    expect(store.endorseInstrument('cek', 's', docId: 'af'), isNull);
    expect(store.partyBalance('s'), closeTo(0, 0.01));
    expect(store.accountBalance('port'), closeTo(0, 0.01));
  });

  testWidgets('özet ekranı örnek firmayı gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WholesaleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Akım'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('belge detayı taşmadan açılır', (tester) async {
    final store = AppStore(box: MemoryJsonBox());
    await store.ensureLoaded();
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const DocDetailPage(docId: 'd-sf-y1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('SF-2026-0001'), findsWidgets);
    expect(find.text('Yıldız Elektrik'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Kopyala'), 300);
    expect(find.text('Kopyala'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('satış fişi formu taşmadan açılır', (tester) async {
    final store = AppStore(box: MemoryJsonBox());
    await store.ensureLoaded();
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const DocEditor(kind: DocKind.sale),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Satış faturası'), findsWidgets);
    expect(find.text('Belge bilgileri'), findsOneWidget);
    expect(find.text('Cari'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(700, 900));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('sipariş rezerve eder, limit uyarır, yavaş stok satışta düşer', () {
    final store = _bare();
    store.parties.first.creditLimit = 50;
    expect(store.slowProducts().map((item) => item.product.id), contains('p'));

    final order = TradeDoc(
      id: 'ss',
      kind: DocKind.saleOrder,
      status: DocStatus.draft,
      no: 'SS-1',
      date: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 15),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 3, unitPrice: 200, vatRate: 20)],
    );
    expect(store.addDraft(order), isNull);
    expect(store.approveDoc('ss'), isNull);
    expect(store.stockOf('p'), 10);
    expect(store.reservedOf('p'), 3);
    expect(store.availableOf('p'), 7);

    final sale = TradeDoc(
      id: 'sf',
      kind: DocKind.sale,
      status: DocStatus.draft,
      no: 'SF-1',
      date: DateTime(2026, 10, 2),
      dueDate: DateTime(2026, 11, 2),
      partyId: 'c',
      warehouseId: 'w',
      shipAddress: 'Şantiye',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
    );
    expect(store.limitWarnings(sale).single, contains('limit'));
    expect(store.addDraft(sale), isNull);
    expect(store.approveDoc('sf'), isNull);
    expect(store.stockOf('p'), 9);
    expect(store.reservedOf('p'), 3);
    expect(store.docById('sf')!.shipAddress, 'Şantiye');
    expect(store.frequentProducts('c').single.id, 'p');
    expect(store.productProfits().single.profit, greaterThan(0));
    expect(store.slowProducts().any((item) => item.product.id == 'p'), isFalse);

    final waybill = TradeDoc(
      id: 'irs',
      kind: DocKind.saleWaybill,
      status: DocStatus.draft,
      no: 'IRS-1',
      date: DateTime(2026, 10, 3),
      dueDate: DateTime(2026, 10, 3),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
    );
    expect(store.addDraft(waybill), isNull);
    expect(store.setDelivery('irs', DeliveryStatus.onTheWay), isNull);
    expect(store.docById('irs')!.deliveryStatus, DeliveryStatus.onTheWay);
  });

  test('özel fiyat, açık irsaliye, kasa sayımı ve ödeme sözü', () {
    final store = _bare();
    store.priceLists.add(PriceList(id: 'pl', name: 'Bayi', discountPercent: 10));
    store.parties.first.priceListId = 'pl';
    store.setSpecialPrice(partyId: 'c', productId: 'p', price: 150);
    expect(store.suggestPrice(store.products.first, store.parties.first, DocKind.sale), 150);

    final waybill = TradeDoc(
      id: 'irs',
      kind: DocKind.saleWaybill,
      status: DocStatus.draft,
      no: 'IRS-1',
      date: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 1),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 150, vatRate: 20)],
    );
    expect(store.addDraft(waybill), isNull);
    expect(store.approveDoc('irs'), isNull);
    expect(store.openWaybills().map((doc) => doc.id), contains('irs'));
    expect(store.stockOf('p'), 9);
    expect(store.invoiceFrom('irs'), isNull);
    expect(store.openWaybills(), isEmpty);
    expect(store.stockOf('p'), 9);

    final cari = store.partyBalance('c');
    expect(store.countCash(40), isNull);
    expect(store.accountBalance('kasa'), closeTo(40, 0.01));
    expect(store.partyBalance('c'), closeTo(cari, 0.01));
    expect(store.countCash(25), isNull);
    expect(store.accountBalance('kasa'), closeTo(25, 0.01));
    expect(store.partyBalance('c'), closeTo(cari, 0.01));

    final sale = store.docs.firstWhere((doc) => doc.kind == DocKind.sale);
    expect(store.setPromise(sale.id, DateTime(2026, 10, 20)), isNull);
    expect(store.docById(sale.id)!.promiseDate, DateTime(2026, 10, 20));
    expect(store.monthCompare().sales, greaterThan(0));
  });

  test('teklif stok ve cariyi değiştirmez, faturaya dönünce işler', () {
    final store = _bare();
    final quote = TradeDoc(
      id: 'tk',
      kind: DocKind.saleQuote,
      status: DocStatus.draft,
      no: 'TK-1',
      date: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 15),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 50, vatRate: 20)],
    );
    expect(store.addDraft(quote), isNull);
    expect(store.approveDoc('tk'), isNull);
    expect(store.stockOf('p'), 10);
    expect(store.partyBalance('c'), 0);
    expect(store.marginWarnings(quote).single, contains('alış'));
    expect(store.invoiceFrom('tk'), isNull);
    expect(store.docById('tk')!.status, DocStatus.invoiced);
    expect(store.stockOf('p'), 9);
    expect(store.partyBalance('c'), greaterThan(0));
  });

  test('alış önerisi eksik miktarı son tedarikçiye bağlar', () {
    final store = _bare();
    store.products.first.minStock = 20;
    final buy = TradeDoc(
      id: 'af',
      kind: DocKind.purchase,
      status: DocStatus.draft,
      no: 'AF-1',
      date: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 10, 1),
      partyId: 's',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 2, unitPrice: 80, vatRate: 20)],
    );
    expect(store.addDraft(buy), isNull);
    expect(store.approveDoc('af'), isNull);
    final need = store.reorderNeeds().single;
    expect(need.supplierId, 's');
    expect(need.lastCost, 80);
    expect(need.shortQty, closeTo(8, 0.01));
    expect(store.draftReorderOrders(), isNotEmpty);
    expect(store.docs.any((doc) => doc.kind == DocKind.purchaseOrder && doc.status == DocStatus.draft), isTrue);
    expect(store.stockOf('p'), 12);
  });

  test('toplu fiyat seçilen markayı yükseltir', () {
    final store = _bare();
    final result = store.adjustPrices(brand: 'Samsung', percent: 10);
    expect(result.error, isNull);
    expect(result.count, 1);
    expect(store.products.first.salePrice, closeTo(220, 0.01));
    expect(store.products.first.purchasePrice, 100);
    expect(store.adjustPrices(percent: 10).error, isNotNull);
  });

  testWidgets('yazdırma sayfası taşmadan açılır', (tester) async {
    final store = AppStore(box: MemoryJsonBox());
    await store.ensureLoaded();
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PrintPage(docId: 'd-sf-y1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('SF-2026-0001'), findsWidgets);
    expect(find.textContaining('GİB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AppStore _bare() {
  final store = AppStore(box: MemoryJsonBox());
  store.warehouses.add(Warehouse(id: 'w', name: 'Merkez', city: 'İstanbul'));
  store.warehouses.add(Warehouse(id: 'w2', name: 'Şube', city: 'Kocaeli'));
  store.products.add(
    Product(
      id: 'p',
      sku: 'TV',
      name: 'Televizyon',
      brand: 'Samsung',
      category: 'Televizyon',
      purchasePrice: 100,
      salePrice: 200,
      vatRate: 20,
      warrantyMonths: 24,
      trackSerial: true,
      warehouseId: 'w',
    ),
  );
  store.parties.add(Party(id: 'c', type: PartyType.customer, name: 'Müşteri', termDays: 30));
  store.parties.add(Party(id: 's', type: PartyType.supplier, name: 'Tedarikçi', termDays: 30));
  store.accounts.add(CashAccount(id: 'kasa', name: 'Kasa', role: AccountRole.cash));
  store.accounts.add(CashAccount(id: 'bank', name: 'Banka', role: AccountRole.bank));
  store.accounts.add(CashAccount(id: 'port', name: 'Portföy', role: AccountRole.checkPortfolio));
  store.accounts.add(CashAccount(id: 'ver', name: 'Verilen', role: AccountRole.issuedChecks));
  store.manualMove(productId: 'p', warehouseId: 'w', qty: 10, serialCodes: ['SN1']);
  return store;
}
