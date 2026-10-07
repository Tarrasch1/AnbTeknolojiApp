import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toptanci_takip/main.dart';
import 'package:toptanci_takip/src/models.dart';
import 'package:toptanci_takip/src/store.dart';
import 'package:toptanci_takip/src/ui/docs_page.dart';
import 'package:toptanci_takip/src/ui/party_page.dart';
import 'package:toptanci_takip/src/ui/print_page.dart';
import 'package:toptanci_takip/src/ui/scope.dart';
import 'package:toptanci_takip/src/ui/statement_page.dart';
import 'package:toptanci_takip/src/ui/stock_page.dart';
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

  test('onaylı satış ve tahsilat düzeltilir, ekstrede ürün yazar', () {
    final store = _bare();
    final doc = TradeDoc(
      id: '',
      kind: DocKind.sale,
      status: DocStatus.draft,
      no: '',
      date: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 31),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
      note: 'Bayi sevkiyatı',
    );
    expect(store.addDraft(doc), isNull);
    expect(store.approveDoc(doc.id), isNull);
    expect(store.stockOf('p'), 9);
    final row = store.statement('c').singleWhere((item) => item.docId == doc.id);
    expect(row.detail, contains('Televizyon'));
    expect(row.detail, contains('1 adet'));
    expect(row.detail, contains('Bayi sevkiyatı'));
    final revised = TradeDoc(
      id: doc.id,
      kind: doc.kind,
      status: DocStatus.approved,
      no: doc.no,
      date: doc.date,
      dueDate: doc.dueDate,
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 2, unitPrice: 200, vatRate: 20)],
    );
    expect(store.reviseDoc(revised), isNull);
    expect(store.stockOf('p'), 8);
    expect(store.partyBalance('c'), closeTo(480, 0.01));
    final pay = Payment(
      id: 'pay',
      no: 'TH-1',
      date: DateTime(2026, 10, 2),
      accountId: 'kasa',
      direction: PayDirection.inbound,
      method: PayMethod.cash,
      amount: 100,
      partyId: 'c',
      note: 'Elden',
    );
    expect(store.addPayment(pay), isNull);
    pay.amount = 40;
    pay.note = 'Eksik tahsilat düzeltildi';
    expect(store.updatePayment(pay), isNull);
    expect(store.partyBalance('c'), closeTo(440, 0.01));
    final payRow = store.statement('c').last;
    expect(payRow.detail, contains('Eksik tahsilat düzeltildi'));
    expect(payRow.detail, contains('Nakit'));
  });

  test('tedarikçi borcu yaşlanır, toplu ödeme ve görüşme saklanır', () {
    final store = _bare();
    final due = DateTime.now().subtract(const Duration(days: 10));
    final doc = TradeDoc(
      id: '',
      kind: DocKind.purchase,
      status: DocStatus.draft,
      no: '',
      date: due,
      dueDate: due,
      partyId: 's',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 100, vatRate: 0)],
    );
    expect(store.addDraft(doc), isNull);
    expect(store.approveDoc(doc.id), isNull);
    expect(store.payableAging()['0-30 gün'], closeTo(100, 0.01));
    expect(store.payableAging()['Vadesi gelmemiş'], 0);
    expect(
      store.addCall(PartyCall(id: '', partyId: 's', date: DateTime(2026, 10, 7), kind: CallKind.promise, text: 'Yarın öder')),
      isNull,
    );
    final copy = AppStore(box: MemoryJsonBox());
    expect(copy.importJson(store.exportJson()), isNull);
    expect(copy.partyCalls('s').single.text, 'Yarın öder');
    expect(
      store.settleOpenDocs(
        partyId: 's',
        accountId: 'kasa',
        date: DateTime(2026, 10, 7),
        note: 'Toplu kapama',
        lines: [(docId: doc.id, amount: 100)],
      ),
      isNull,
    );
    expect(store.docRemaining(store.docById(doc.id)!), 0);
    expect(store.openDocs('s'), isEmpty);
  });

  testWidgets('ürün tablosu ve cari sekmeleri taşmadan durur', (tester) async {
    final store = AppStore(box: MemoryJsonBox());
    await store.ensureLoaded();
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(theme: buildAppTheme(), home: const Scaffold(body: StockPage())),
      ),
    );
    await tester.pump();
    expect(find.text('Stok kodu'), findsOneWidget);
    expect(find.text('Toplam satış bedeli'), findsOneWidget);
    expect(find.text('Dip toplam'), findsOneWidget);
    expect(find.text('Tüm markalar'), findsOneWidget);
    expect(find.text('Depolar'), findsNothing);
    expect(find.text('Sayım'), findsNothing);
    expect(find.text('Seri no'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(theme: buildAppTheme(), home: const Scaffold(body: PartyPage())),
      ),
    );
    await tester.pump();
    expect(find.text('Müşteri'), findsWidgets);
    expect(find.text('Tedarikçi'), findsWidgets);
    expect(find.text('Tümü'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(theme: buildAppTheme(), home: const StatementPage(partyId: 'c-yildiz')),
      ),
    );
    await tester.pump();
    expect(find.text('Not'), findsOneWidget);
    expect(find.textContaining('No-Frost'), findsWidgets);
    expect(find.text('Düzelt'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('stok yetmezse satış durur, kâr ve fiyatlar kilitlenir', () {
  final store = _bare();
  final tooMuch = TradeDoc(
    id: 'big',
    kind: DocKind.sale,
    status: DocStatus.draft,
    no: 'SF-BIG',
    date: DateTime(2026, 10, 1),
    dueDate: DateTime(2026, 11, 1),
    partyId: 'c',
    warehouseId: 'w',
    lines: [DocLine(productId: 'p', qty: 11, unitPrice: 200, vatRate: 20)],
  );
  expect(store.addDraft(tooMuch), isNull);
  expect(store.approveDoc('big'), contains('depoda'));
  expect(store.docById('big')!.status, DocStatus.draft);
  expect(store.stockOf('p'), 10);

  final sale = TradeDoc(
    id: 'sf',
    kind: DocKind.sale,
    status: DocStatus.draft,
    no: 'SF-1',
    date: DateTime(2026, 10, 1),
    dueDate: DateTime.now().subtract(const Duration(days: 5)),
    partyId: 'c',
    warehouseId: 'w',
    lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
  );
  expect(store.addDraft(sale), isNull);
  expect(store.approveDoc('sf'), isNull);
  expect(store.docById('sf')!.lines.single.unitCost, 100);
  expect(store.adjustPrices(brand: 'Samsung', percent: -60, sale: false, purchase: true).error, isNull);
  expect(store.products.first.purchasePrice, 40);
  expect(store.priceHistory('p').single.oldPurchase, 100);
  expect(store.priceHistory('p').single.newPurchase, 40);
  expect(store.grossProfit(), closeTo(100, 0.05));

  final current = store.docById('sf')!;
  final revised = TradeDoc(
    id: current.id,
    kind: current.kind,
    status: current.status,
    no: current.no,
    date: current.date,
    dueDate: current.dueDate,
    partyId: current.partyId,
    warehouseId: current.warehouseId,
    lines: [DocLine(productId: 'p', qty: 20, unitPrice: 200, vatRate: 20)],
  );
  expect(store.reviseDoc(revised), contains('depoda'));
  expect(store.stockOf('p'), 9);
  expect(store.docById('sf')!.lines.single.qty, 1);

  final buy = TradeDoc(
    id: 'af',
    kind: DocKind.purchase,
    status: DocStatus.draft,
    no: 'AF-1',
    date: DateTime(2026, 9, 1),
    dueDate: DateTime(2026, 10, 1),
    partyId: 's',
    warehouseId: 'w',
    lines: [DocLine(productId: 'p', qty: 1, unitPrice: 90, vatRate: 0)],
  );
  expect(store.addDraft(buy), isNull);
  expect(store.approveDoc('af'), isNull);
  expect(store.supplierPrices('p').single.price, 90);
  expect(store.supplierPrices('p').single.party.id, 's');
  expect(store.topParties(suppliers: false).single.party.id, 'c');
  expect(store.topParties(suppliers: true).single.party.id, 's');
  expect(store.collectionSheet().single.party.id, 'c');
  expect(store.collectionSheet().single.remaining, greaterThan(0));

  expect(store.addVisit(VisitPlan(id: '', partyId: 'c', date: DateTime.now(), kind: VisitKind.call, text: 'Ara')), isNull);
  expect(store.dueVisits().single.text, 'Ara');
  expect(
    store.addVisit(VisitPlan(id: '', partyId: 'c', date: DateTime.now().add(const Duration(days: 4)), kind: VisitKind.visit, text: 'Sonra')),
    isNull,
  );
  expect(store.dueVisits().length, 1);
  expect(store.completeVisit(store.dueVisits().single.id), isNull);
  expect(store.dueVisits(), isEmpty);

  final restored = AppStore(box: MemoryJsonBox());
  expect(restored.importJson(store.exportJson()), isNull);
  expect(restored.priceHistory('p').single.newPurchase, 40);
  expect(restored.docById('sf')!.lines.single.unitCost, 100);
  expect(restored.partyVisits('c'), hasLength(2));
  });

  test('uyuyan cari, sevkiyat, iade nedeni ve e-belge listelenir', () {
    final store = _bare();
    store.parties.first.phone = '0532 000 00 00';
    expect(store.dormantCustomers().map((row) => row.party.id), ['c']);
    expect(store.pendingEDocs(), isEmpty);
    expect(store.openShipments(), isEmpty);

    final sale = TradeDoc(
      id: 'sf',
      kind: DocKind.sale,
      status: DocStatus.draft,
      no: 'SF-1',
      date: DateTime.now(),
      dueDate: DateTime.now(),
      partyId: 'c',
      warehouseId: 'w',
      shipAddress: 'Depo kapısı',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
    );
    expect(store.addDraft(sale), isNull);
    expect(store.approveDoc('sf'), isNull);
    expect(store.dormantCustomers(), isEmpty);
    expect(store.openShipments().single.id, 'sf');
    expect(store.shipmentAddress(store.docById('sf')!), 'Depo kapısı');
    expect(store.customerPrices('p').single.price, 200);
    expect(store.customerPrices('p').single.party.id, 'c');
    expect(store.salesByCategory()['Televizyon'], closeTo(200, 0.05));
    expect(store.pendingEDocs().single.id, 'sf');
    expect(store.setEDoc('sf', EDocStatus.issued), isNull);
    expect(store.pendingEDocs(), isEmpty);
    expect(store.setDelivery('sf', DeliveryStatus.delivered), isNull);
    expect(store.openShipments(), isEmpty);

    final back = TradeDoc(
      id: 'ia',
      kind: DocKind.saleReturn,
      status: DocStatus.draft,
      no: 'IA-1',
      date: DateTime.now(),
      dueDate: DateTime.now(),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
    );
    expect(store.addDraft(back), isNull);
    expect(store.approveDoc('ia'), 'İade nedeni yazın');
    expect(store.docById('ia')!.status, DocStatus.draft);
    back.returnReason = 'Arızalı';
    expect(store.addDraft(back), isNull);
    expect(store.approveDoc('ia'), isNull);
    expect(store.topReturns().single.product.id, 'p');
    expect(store.topReturns().single.qty, 1);
    expect(store.docLineDetail(store.docById('ia')!), contains('Arızalı'));

    expect(store.addInstrument(Instrument(
      id: '',
      kind: InstrumentKind.check,
      direction: InstrumentDirection.received,
      no: 'CK-1',
      amount: 500,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      partyId: 'c',
    )), isNull);
    expect(store.upcomingInstruments().single.no, 'CK-1');

    final restored = AppStore(box: MemoryJsonBox());
    expect(restored.importJson(store.exportJson()), isNull);
    expect(restored.docById('ia')!.returnReason, 'Arızalı');
  });

  test('plasiyer, tahsilat günü, hedef ve bugünün vadesi tutulur', () {
    final store = _bare();
    store.parties.first.salesRep = 'Ayşe Kara';
    store.profile.monthlyTarget = 5000;
    final soldOn = DateTime.now().subtract(const Duration(days: 10));
    final sale = TradeDoc(
      id: 'sf',
      kind: DocKind.sale,
      status: DocStatus.draft,
      no: 'SF-1',
      date: soldOn,
      dueDate: DateTime.now(),
      partyId: 'c',
      warehouseId: 'w',
      lines: [DocLine(productId: 'p', qty: 1, unitPrice: 200, vatRate: 20)],
    );
    expect(store.addDraft(sale), isNull);
    expect(store.approveDoc('sf'), isNull);
    expect(store.dueTodaySales().single.id, 'sf');
    expect(store.overdueSales(), isEmpty);
    expect(store.collectionDays(), isEmpty);
    expect(store.salesByRep().single.name, 'Ayşe Kara');

    final gross = store.docById('sf')!.gross;
    expect(store.addPayment(Payment(
      id: '',
      no: '',
      date: DateTime.now(),
      accountId: 'kasa',
      direction: PayDirection.inbound,
      method: PayMethod.transfer,
      amount: gross,
      partyId: 'c',
      docId: 'sf',
    )), isNull);
    expect(store.docRemaining(store.docById('sf')!), closeTo(0, 0.01));
    expect(store.dueTodaySales(), isEmpty);
    expect(store.collectionDays().single.days, closeTo(10, 0.01));
    expect(store.collectionDays().single.invoices, 1);
    expect(store.markReconciled('c'), isNull);
    expect(store.parties.first.reconciledOn, isNotNull);

    final restored = AppStore(box: MemoryJsonBox());
    expect(restored.importJson(store.exportJson()), isNull);
    expect(restored.parties.first.salesRep, 'Ayşe Kara');
    expect(restored.parties.first.reconciledOn, isNotNull);
    expect(restored.profile.monthlyTarget, 5000);
    expect(restored.collectionDays().single.days, closeTo(10, 0.01));
  });

  test('açık sipariş, eski teklif, stok yaşı, iade oranı, kasa ve söz listelenir', () {
    final store = _bare();
    expect(store.stockAges().single.days, isNull);

    TradeDoc draft({
      required String id,
      required DocKind kind,
      required String no,
      required DateTime date,
      String partyId = 'c',
      double qty = 1,
      DateTime? promise,
    }) {
      return TradeDoc(
        id: id,
        kind: kind,
        status: DocStatus.draft,
        no: no,
        date: date,
        dueDate: date,
        partyId: partyId,
        warehouseId: 'w',
        promiseDate: promise,
        lines: [DocLine(productId: 'p', qty: qty, unitPrice: 200, vatRate: kind == DocKind.purchase || kind == DocKind.purchaseOrder ? 0 : 20)],
      );
    }

    final now = DateTime.now();
    expect(store.addDraft(draft(id: 'ss', kind: DocKind.saleOrder, no: 'SS-1', date: now)), isNull);
    expect(store.approveDoc('ss'), isNull);
    expect(store.openSaleOrders().single.id, 'ss');
    expect(store.addDraft(draft(id: 'as', kind: DocKind.purchaseOrder, no: 'AS-1', date: now, partyId: 's')), isNull);
    expect(store.approveDoc('as'), isNull);
    expect(store.openPurchaseOrders().single.id, 'as');
    expect(store.addDraft(draft(id: 'tk', kind: DocKind.saleQuote, no: 'TK-1', date: now.subtract(const Duration(days: 20)))), isNull);
    expect(store.approveDoc('tk'), isNull);
    expect(store.addDraft(draft(id: 'tk2', kind: DocKind.saleQuote, no: 'TK-2', date: now)), isNull);
    expect(store.approveDoc('tk2'), isNull);
    expect(store.staleQuotes().map((doc) => doc.id), ['tk']);

    expect(store.invoiceFrom('ss'), isNull);
    expect(store.openSaleOrders(), isEmpty);
    expect(store.docById('tk')!.status, DocStatus.approved);

    expect(store.addDraft(draft(id: 'af', kind: DocKind.purchase, no: 'AF-1', date: now.subtract(const Duration(days: 5)), partyId: 's')), isNull);
    expect(store.approveDoc('af'), isNull);
    expect(store.stockAges().single.days, 5);

    expect(store.addDraft(draft(id: 'sf', kind: DocKind.sale, no: 'SF-1', date: now, qty: 2, promise: now.subtract(const Duration(days: 1)))), isNull);
    expect(store.approveDoc('sf'), isNull);
    expect(store.duePromises().single.id, 'sf');
    final later = draft(id: 'sf2', kind: DocKind.sale, no: 'SF-2', date: now, promise: now.add(const Duration(days: 4)));
    expect(store.addDraft(later), isNull);
    expect(store.approveDoc('sf2'), isNull);
    expect(store.duePromises().map((doc) => doc.id), ['sf']);

    final back = draft(id: 'ia', kind: DocKind.saleReturn, no: 'IA-1', date: now);
    back.returnReason = 'Arızalı';
    expect(store.addDraft(back), isNull);
    expect(store.approveDoc('ia'), isNull);
    expect(store.returnRates().single.rate, closeTo(25, 0.05));

    expect(store.addPayment(Payment(
      id: '',
      no: '',
      date: now.subtract(const Duration(days: 1)),
      accountId: 'kasa',
      direction: PayDirection.inbound,
      method: PayMethod.cash,
      amount: 10,
      partyId: 'c',
    )), isNull);
    expect(store.cashClose(), isEmpty);
    expect(store.addPayment(Payment(
      id: '',
      no: '',
      date: now,
      accountId: 'kasa',
      direction: PayDirection.inbound,
      method: PayMethod.cash,
      amount: 40,
      partyId: 'c',
    )), isNull);
    expect(store.cashClose().single.inbound, closeTo(40, 0.01));
    expect(store.cashClose().single.outbound, 0);
  });

  test('limit, mutabakat kuyruğu, plasiyer süresi, alış sıçraması ve geciken alış', () {
    final store = _bare();
    final customer = store.parties.first;
    customer.creditLimit = 250;
    customer.salesRep = 'Ayşe Kara';
    final now = DateTime.now();

    TradeDoc draft({
      required String id,
      required DocKind kind,
      required String no,
      required DateTime date,
      String partyId = 'c',
      double price = 100,
    }) {
      return TradeDoc(
        id: id,
        kind: kind,
        status: DocStatus.draft,
        no: no,
        date: date,
        dueDate: date,
        partyId: partyId,
        warehouseId: 'w',
        lines: [DocLine(productId: 'p', qty: 1, unitPrice: price, vatRate: 0)],
      );
    }

    expect(store.addDraft(draft(id: 'ss', kind: DocKind.saleOrder, no: 'SS-1', date: now, price: 200)), isNull);
    expect(store.approveDoc('ss'), isNull);
    final sale = draft(id: 'sf', kind: DocKind.sale, no: 'SF-1', date: now, price: 100);
    expect(store.addDraft(sale), isNull);
    expect(store.limitWarnings(sale).single, contains('açık sipariş'));
    expect(store.approveDoc('sf'), isNull);
    customer.creditLimit = 50;
    expect(store.overLimitParties().single.over, closeTo(50, 0.05));
    expect(store.reconcileQueue().map((party) => party.id), ['c']);
    expect(store.markReconciled('c'), isNull);
    expect(store.reconcileQueue(), isEmpty);
    customer.reconciledOn = now.subtract(const Duration(days: 40));
    expect(store.reconcileQueue().single.id, 'c');

    expect(store.addPayment(Payment(
      id: '',
      no: '',
      date: now,
      accountId: 'kasa',
      direction: PayDirection.inbound,
      method: PayMethod.cash,
      amount: 100,
      partyId: 'c',
      docId: 'sf',
    )), isNull);
    expect(store.repCollectionDays().single.name, 'Ayşe Kara');
    expect(store.repCollectionDays().single.days, closeTo(0, 0.01));
    expect(store.repCollectionDays().single.invoices, 1);

    final product = store.products.first;
    store.upsertProduct(Product(
      id: product.id,
      sku: product.sku,
      name: product.name,
      brand: product.brand,
      category: product.category,
      purchasePrice: 120,
      salePrice: product.salePrice,
      vatRate: product.vatRate,
      warehouseId: product.warehouseId,
      trackSerial: product.trackSerial,
      warrantyMonths: product.warrantyMonths,
    ));
    expect(store.costJumps().single.product.id, 'p');
    store.priceHistory('p').first.date = now.subtract(const Duration(days: 2));
    final raised = store.products.first;
    store.upsertProduct(Product(
      id: raised.id,
      sku: raised.sku,
      name: raised.name,
      brand: raised.brand,
      category: raised.category,
      purchasePrice: 125,
      salePrice: raised.salePrice,
      vatRate: raised.vatRate,
      warehouseId: raised.warehouseId,
      trackSerial: raised.trackSerial,
      warrantyMonths: raised.warrantyMonths,
    ));
    expect(store.costJumps(), isEmpty);

    expect(store.addDraft(draft(id: 'as', kind: DocKind.purchaseOrder, no: 'AS-1', date: now.subtract(const Duration(days: 8)), partyId: 's')), isNull);
    expect(store.approveDoc('as'), isNull);
    expect(store.addDraft(draft(id: 'as2', kind: DocKind.purchaseOrder, no: 'AS-2', date: now, partyId: 's')), isNull);
    expect(store.approveDoc('as2'), isNull);
    expect(store.latePurchaseOrders().map((doc) => doc.id), ['as']);
    expect(store.openPurchaseOrders(), hasLength(2));
  });

  test('zarar satışı, alış vadesi, mükerrer VKN, pasif ürün, iskonto ve son hareket', () {
    final store = _bare();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    TradeDoc draft({
      required String id,
      required DocKind kind,
      required String no,
      required DateTime date,
      String partyId = 'c',
      double price = 100,
      double discount = 0,
      DateTime? due,
      String note = '',
      String reason = '',
    }) {
      return TradeDoc(
        id: id,
        kind: kind,
        status: DocStatus.draft,
        no: no,
        date: date,
        dueDate: due ?? date,
        partyId: partyId,
        warehouseId: 'w',
        note: note,
        returnReason: reason,
        lines: [DocLine(productId: 'p', qty: 1, unitPrice: price, discountRate: discount, vatRate: 0)],
      );
    }

    expect(store.addDraft(draft(id: 'sf', kind: DocKind.sale, no: 'SF-1', date: now, price: 50, note: 'acil sevkiyat', reason: 'kutu ezik')), isNull);
    expect(store.approveDoc('sf'), isNull);
    expect(store.addDraft(draft(id: 'old', kind: DocKind.sale, no: 'SF-0', date: DateTime(now.year - 1, 1, 15), price: 40)), isNull);
    expect(store.approveDoc('old'), isNull);
    expect(store.addDraft(draft(id: 'ok', kind: DocKind.sale, no: 'SF-2', date: now, price: 200, discount: 10)), isNull);
    expect(store.approveDoc('ok'), isNull);

    expect(store.belowCostSales().map((row) => row.doc.id), ['sf', 'old']);
    expect(store.belowCostSales().where((row) => row.doc.id == 'ok'), isEmpty);
    expect(store.belowCostSales(from: monthStart).map((row) => row.doc.id), ['sf']);
    expect(store.belowCostSales().firstWhere((row) => row.doc.id == 'sf').cost, closeTo(100, 0.01));

    expect(store.discountByParty().single.party.id, 'c');
    expect(store.discountByParty().single.discount, closeTo(20, 0.05));
    expect(store.discountByParty(from: monthStart).single.invoices, 1);

    expect(store.addDraft(draft(id: 'near', kind: DocKind.purchase, no: 'AF-1', date: now, partyId: 's', due: now.add(const Duration(days: 3)))), isNull);
    expect(store.approveDoc('near'), isNull);
    expect(store.addDraft(draft(id: 'far', kind: DocKind.purchase, no: 'AF-2', date: now, partyId: 's', due: now.add(const Duration(days: 20)))), isNull);
    expect(store.approveDoc('far'), isNull);
    expect(store.addDraft(draft(id: 'late', kind: DocKind.purchase, no: 'AF-3', date: now, partyId: 's', due: now.subtract(const Duration(days: 2)))), isNull);
    expect(store.approveDoc('late'), isNull);
    expect(store.duePurchaseWeek().map((doc) => doc.id), ['near']);

    store.parties.first.taxNo = '111 222';
    store.parties.last.taxNo = '111222';
    expect(store.duplicateTaxNos().single.parties.map((party) => party.id), containsAll(['c', 's']));
    store.parties.last.taxNo = '999';
    expect(store.duplicateTaxNos(), isEmpty);

    expect(store.addDraft(draft(id: 'ss', kind: DocKind.saleOrder, no: 'SS-1', date: now)), isNull);
    expect(store.approveDoc('ss'), isNull);
    store.products.first.active = false;
    expect(store.inactiveOpenDocs().map((row) => row.doc.id), ['ss']);
    expect(store.inactiveOpenDocs().single.products.single.id, 'p');

    expect(store.addPayment(Payment(
      id: 'port-pay',
      no: 'P-1',
      date: now,
      accountId: 'port',
      direction: PayDirection.inbound,
      method: PayMethod.check,
      amount: 99,
      partyId: 'c',
    )), isNull);
    expect(store.addPayment(Payment(
      id: 'cash-pay',
      no: 'P-2',
      date: now.subtract(const Duration(days: 1)),
      accountId: 'kasa',
      direction: PayDirection.inbound,
      method: PayMethod.cash,
      amount: 10,
      partyId: 'c',
    )), isNull);
    expect(store.lastCashMovement('c')?.amount, closeTo(10, 0.01));
    expect(store.addPayment(Payment(
      id: 'bank-pay',
      no: 'P-3',
      date: now,
      accountId: 'bank',
      direction: PayDirection.inbound,
      method: PayMethod.transfer,
      amount: 15,
      partyId: 'c',
    )), isNull);
    expect(store.lastCashMovement('c')?.amount, closeTo(15, 0.01));
    expect(store.lastCashMovement('c')?.method, PayMethod.transfer);

    final sale = store.docById('sf')!;
    expect(store.docMatchesQuery(sale, 'acil'), isTrue);
    expect(store.docMatchesQuery(sale, 'ezik'), isTrue);
    expect(store.docMatchesQuery(sale, 'televizyon'), isTrue);
    expect(store.docMatchesQuery(sale, 'yokboyle'), isFalse);
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
