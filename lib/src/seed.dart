import 'models.dart';
import 'store.dart';

void seedDemo(AppStore store) {
  store.profile = CompanyProfile(
    name: 'Akım Elektrikli Ev Aletleri Tic. Ltd. Şti.',
    shortName: 'Akım Elektrik',
    taxNo: '8450123456',
    taxOffice: 'İkitelli',
    phone: '0212 671 45 00',
    email: 'info@akimelektrik.example',
    address: 'İkitelli OSB Mah. Eskoop Sanayi Sitesi B Blok No:12',
    city: 'İstanbul',
    iban: 'TR12 0001 0002 3456 7890 1234 56',
    defaultVat: 20,
    defaultTermDays: 30,
    monthlyTarget: 2500000,
  );

  store.warehouses.addAll([
    Warehouse(
      id: 'w-merkez',
      name: 'Merkez Depo',
      city: 'İstanbul',
      address: 'İkitelli OSB',
    ),
    Warehouse(
      id: 'w-anadolu',
      name: 'Anadolu Depo',
      city: 'Kocaeli',
      address: 'Gebze Güzeller OSB',
    ),
    Warehouse(
      id: 'w-teshir',
      name: 'Teşhir Depo',
      city: 'İstanbul',
      address: 'Bayrampaşa showroom',
    ),
  ]);

  store.priceLists.addAll([
    PriceList(id: 'pl-liste', name: 'Liste', discountPercent: 0, note: 'Raf fiyatı'),
    PriceList(id: 'pl-bayi', name: 'Bayi', discountPercent: 8, note: 'Standart bayi iskontosu'),
    PriceList(id: 'pl-proje', name: 'Proje', discountPercent: 12, note: 'Toplu konut ve proje'),
  ]);

  store.accounts.addAll([
    CashAccount(id: 'acc-kasa', name: 'Nakit Kasa', role: AccountRole.cash),
    CashAccount(
      id: 'acc-ziraat',
      name: 'Ziraat Bankası',
      role: AccountRole.bank,
      iban: 'TR33 0001 0002 1111 2222 3333 44',
    ),
    CashAccount(
      id: 'acc-garanti',
      name: 'Garanti BBVA',
      role: AccountRole.bank,
      iban: 'TR44 0006 2000 1234 0006 0000 01',
    ),
    CashAccount(id: 'acc-portfoy', name: 'Alınan Çek / Senet', role: AccountRole.checkPortfolio),
    CashAccount(id: 'acc-verilen', name: 'Verilen Çek / Senet', role: AccountRole.issuedChecks),
  ]);

  Product product({
    required String id,
    required String sku,
    required String barcode,
    required String name,
    required String brand,
    required String category,
    required double buy,
    required double sell,
    required double min,
    int warranty = 24,
    String energy = 'A',
    int watt = 0,
    bool serial = true,
    bool install = false,
    String shelf = '',
    String color = 'Beyaz',
    double desi = 0,
    String origin = 'Türkiye',
  }) {
    final item = Product(
      id: id,
      sku: sku,
      barcode: barcode,
      name: name,
      brand: brand,
      category: category,
      energyClass: energy,
      warrantyMonths: warranty,
      watt: watt,
      color: color,
      origin: origin,
      desi: desi,
      needsInstall: install,
      trackSerial: serial,
      vatRate: 20,
      purchasePrice: buy,
      salePrice: sell,
      minStock: min,
      shelf: shelf,
      warehouseId: 'w-merkez',
    );
    store.products.add(item);
    return item;
  }

  product(
    id: 'p1',
    sku: 'ARC-NF-570',
    barcode: '8690842125701',
    name: 'Arçelik 570505 EB No-Frost Buzdolabı',
    brand: 'Arçelik',
    category: 'Buzdolabı',
    buy: 24500,
    sell: 28900,
    min: 4,
    warranty: 36,
    watt: 180,
    desi: 92,
    shelf: 'A-01',
  );
  product(
    id: 'p2',
    sku: 'BKO-NF-970',
    barcode: '8690842439704',
    name: 'Beko 970463 MB No-Frost Buzdolabı',
    brand: 'Beko',
    category: 'Buzdolabı',
    buy: 19800,
    sell: 23600,
    min: 3,
    watt: 170,
    desi: 88,
    shelf: 'A-02',
  );
  product(
    id: 'p3',
    sku: 'VST-CM-972',
    barcode: '8690842789720',
    name: 'Vestel CMI 97202 9 kg Çamaşır Makinesi',
    brand: 'Vestel',
    category: 'Çamaşır Makinesi',
    buy: 16200,
    sell: 19400,
    min: 4,
    watt: 2200,
    desi: 46,
    shelf: 'B-01',
  );
  product(
    id: 'p4',
    sku: 'SIE-WG-44',
    barcode: '4242005277441',
    name: 'Siemens WG44A2X0TR 9 kg Çamaşır Makinesi',
    brand: 'Siemens',
    category: 'Çamaşır Makinesi',
    buy: 21400,
    sell: 25500,
    min: 6,
    energy: 'B',
    watt: 2300,
    desi: 48,
    origin: 'Türkiye',
    shelf: 'B-04',
  );
  product(
    id: 'p5',
    sku: 'BSH-DW-46',
    barcode: '4242005293311',
    name: 'Bosch SMS4HVI33T Bulaşık Makinesi',
    brand: 'Bosch',
    category: 'Bulaşık Makinesi',
    buy: 14800,
    sell: 17600,
    min: 3,
    watt: 2400,
    desi: 42,
    shelf: 'B-08',
  );
  product(
    id: 'p6',
    sku: 'ARC-FRN-340',
    barcode: '8690842113401',
    name: 'Arçelik AFM 340 S Ankastre Fırın',
    brand: 'Arçelik',
    category: 'Ankastre Fırın',
    buy: 9200,
    sell: 11200,
    min: 2,
    install: true,
    watt: 2400,
    color: 'Siyah cam',
    desi: 28,
    shelf: 'C-01',
  );
  product(
    id: 'p7',
    sku: 'KUM-OC-410',
    barcode: '8699256784103',
    name: 'Kumtel KO-410 Set Üstü Ocak',
    brand: 'Kumtel',
    category: 'Ocak',
    buy: 3100,
    sell: 3890,
    min: 5,
    serial: false,
    watt: 7200,
    color: 'Inox',
    desi: 8,
    shelf: 'C-06',
  );
  product(
    id: 'p8',
    sku: 'BYM-KL-12',
    barcode: '8698400121208',
    name: 'Baymak Elegant Prime 12 Klima 12000 BTU',
    brand: 'Baymak',
    category: 'Klima',
    buy: 26800,
    sell: 31900,
    min: 2,
    install: true,
    watt: 1100,
    color: 'Beyaz',
    desi: 18,
    shelf: 'K-01',
  );
  product(
    id: 'p9',
    sku: 'DAI-SN-12',
    barcode: '4573535121206',
    name: 'Daikin Sensira FTXF35 12000 BTU',
    brand: 'Daikin',
    category: 'Klima',
    buy: 29400,
    sell: 34800,
    min: 3,
    install: true,
    energy: 'A',
    watt: 1000,
    origin: 'Çekya',
    desi: 16,
    shelf: 'K-03',
  );
  product(
    id: 'p10',
    sku: 'SAM-55-CU',
    barcode: '8806095127104',
    name: 'Samsung UE55CU7100 55" 4K TV',
    brand: 'Samsung',
    category: 'Televizyon',
    buy: 17100,
    sell: 20400,
    min: 3,
    energy: 'E',
    watt: 120,
    color: 'Siyah',
    origin: 'Mısır',
    desi: 22,
    shelf: 'T-01',
  );
  product(
    id: 'p11',
    sku: 'LG-50-UR',
    barcode: '8806091815002',
    name: 'LG 50UR78006LK 50" 4K TV',
    brand: 'LG',
    category: 'Televizyon',
    buy: 14900,
    sell: 17800,
    min: 2,
    energy: 'F',
    watt: 110,
    color: 'Siyah',
    origin: 'Polonya',
    desi: 18,
    shelf: 'T-04',
  );
  product(
    id: 'p12',
    sku: 'PHI-SV-715',
    barcode: '8720389007156',
    name: 'Philips PowerPro Compact Süpürge',
    brand: 'Philips',
    category: 'Elektrikli Süpürge',
    buy: 4200,
    sell: 5150,
    min: 4,
    serial: false,
    watt: 900,
    color: 'Mavi',
    desi: 6,
    shelf: 'E-01',
  );
  product(
    id: 'p13',
    sku: 'TEF-UT-569',
    barcode: '3045387256971',
    name: 'Tefal FV5697 Buharlı Ütü',
    brand: 'Tefal',
    category: 'Ütü',
    buy: 1450,
    sell: 1890,
    min: 8,
    serial: false,
    watt: 2700,
    color: 'Mavi',
    origin: 'Fransa',
    desi: 2,
    shelf: 'E-08',
  );
  product(
    id: 'p14',
    sku: 'ARZ-OK-RICH',
    barcode: '8697412123458',
    name: 'Arzum OKKA Rich Spin Pro Kahve Makinesi',
    brand: 'Arzum',
    category: 'Kahve Makinesi',
    buy: 2100,
    sell: 2690,
    min: 6,
    serial: false,
    watt: 700,
    color: 'Bakır',
    desi: 3,
    shelf: 'E-12',
  );
  product(
    id: 'p15',
    sku: 'PHI-AF-300',
    barcode: '8720389003004',
    name: 'Philips Airfryer 3000 XXL',
    brand: 'Philips',
    category: 'Airfryer',
    buy: 2800,
    sell: 3490,
    min: 5,
    serial: false,
    watt: 2225,
    color: 'Siyah',
    desi: 7,
    shelf: 'E-15',
  );
  product(
    id: 'p16',
    sku: 'ALT-SB-91',
    barcode: '8690842910914',
    name: 'Altus AL 91 YB Su Sebili',
    brand: 'Altus',
    category: 'Su Sebili',
    buy: 3600,
    sell: 4450,
    min: 4,
    serial: false,
    watt: 550,
    desi: 12,
    shelf: 'E-18',
  );

  Party party({
    required String id,
    required PartyType type,
    required String name,
    required String city,
    String taxNo = '',
    String taxOffice = '',
    String contact = '',
    String phone = '',
    String priceListId = '',
    double creditLimit = 0,
    int termDays = 30,
    String address = '',
    String salesRep = '',
  }) {
    final item = Party(
      id: id,
      type: type,
      name: name,
      taxNo: taxNo,
      taxOffice: taxOffice,
      contact: contact,
      phone: phone,
      city: city,
      address: address,
      creditLimit: creditLimit,
      termDays: termDays,
      priceListId: priceListId,
      salesRep: salesRep,
    );
    store.parties.add(item);
    return item;
  }

  party(
    id: 'c-yildiz',
    type: PartyType.customer,
    name: 'Yıldız Elektrik',
    city: 'İstanbul',
    taxNo: '9988776655',
    taxOffice: 'Bayrampaşa',
    contact: 'Hakan Yıldız',
    phone: '0532 111 22 33',
    priceListId: 'pl-bayi',
    creditLimit: 750000,
    address: 'Bayrampaşa Sanayi Cad. No:18',
    salesRep: 'Ayşe Kara',
  );
  party(
    id: 'c-ege',
    type: PartyType.customer,
    name: 'Ege Beyaz Eşya',
    city: 'İzmir',
    taxNo: '1122334455',
    taxOffice: 'Karşıyaka',
    contact: 'Selin Acar',
    phone: '0533 444 55 66',
    priceListId: 'pl-bayi',
    creditLimit: 400000,
    termDays: 45,
    address: 'Karşıyaka İskele Cad. No:7',
    salesRep: 'Ayşe Kara',
  );
  party(
    id: 'c-anka',
    type: PartyType.customer,
    name: 'Ankara Ankastre',
    city: 'Ankara',
    taxNo: '5566778899',
    taxOffice: 'Ostim',
    contact: 'Murat Kaya',
    phone: '0535 777 88 99',
    priceListId: 'pl-proje',
    creditLimit: 250000,
    termDays: 21,
    address: 'Ostim OSB 1177. Cad.',
    salesRep: 'Mehmet Usta',
  );
  party(
    id: 'c-kar',
    type: PartyType.customer,
    name: 'Karadeniz Klima',
    city: 'Samsun',
    taxNo: '6677889900',
    taxOffice: 'İlkadım',
    contact: 'Emre Demir',
    phone: '0542 300 40 50',
    priceListId: 'pl-bayi',
    creditLimit: 200000,
    address: 'İlkadım Sanayi Sitesi',
    salesRep: 'Mehmet Usta',
  );
  party(
    id: 's-arcelik',
    type: PartyType.supplier,
    name: 'Arçelik Pazarlama A.Ş.',
    city: 'İstanbul',
    taxNo: '0730011845',
    taxOffice: 'Büyük Mükellefler',
    contact: 'Bölge satış',
    phone: '0212 314 34 34',
    termDays: 45,
    address: 'Sütlüce',
  );
  party(
    id: 's-vestel',
    type: PartyType.supplier,
    name: 'Vestel Ticaret A.Ş.',
    city: 'Manisa',
    taxNo: '9250457988',
    taxOffice: 'Manisa',
    contact: 'Toptan sipariş',
    phone: '0236 233 01 31',
    termDays: 30,
    address: 'Organize Sanayi',
  );
  party(
    id: 's-ithal',
    type: PartyType.supplier,
    name: 'İthal Ev Teknolojileri A.Ş.',
    city: 'İstanbul',
    taxNo: '4801122334',
    taxOffice: 'Maslak',
    contact: 'Deniz Uçar',
    phone: '0212 285 00 10',
    termDays: 60,
    address: 'Maslak Meydan Sok.',
  );

  DocLine line(
    String productId,
    double qty,
    double price, {
    List<String> serials = const [],
    String note = '',
  }) {
    return DocLine(
      productId: productId,
      qty: qty,
      unitPrice: price,
      vatRate: 20,
      serials: serials,
      note: note,
    );
  }

  TradeDoc make({
    required String id,
    required DocKind kind,
    required String no,
    required DateTime date,
    required DateTime due,
    required String partyId,
    required List<DocLine> lines,
    String note = '',
    String returnReason = '',
    EDocStatus eDoc = EDocStatus.none,
    bool approve = true,
  }) {
    final doc = TradeDoc(
      id: id,
      kind: kind,
      status: DocStatus.draft,
      no: no,
      date: date,
      dueDate: due,
      partyId: partyId,
      warehouseId: 'w-merkez',
      lines: lines,
      note: note,
      returnReason: returnReason,
      eDoc: eDoc,
    );
    final draftError = store.addDraft(doc);
    if (draftError != null) {
      throw StateError(draftError);
    }
    if (approve) {
      final approveError = store.approveDoc(doc.id);
      if (approveError != null) throw StateError(approveError);
    }
    return doc;
  }

  make(
    id: 'd-af-arc',
    kind: DocKind.purchase,
    no: 'AF-2026-0001',
    date: DateTime(2026, 8, 12),
    due: DateTime(2026, 9, 26),
    partyId: 's-arcelik',
    note: 'Ağustos beyaz eşya sevkiyatı',
    lines: [
      line('p1', 8, 24500, serials: [
        'ARC5705050001',
        'ARC5705050002',
        'ARC5705050003',
        'ARC5705050004',
      ]),
      line('p2', 6, 19800),
      line('p6', 6, 9200),
    ],
  );
  make(
    id: 'd-af-ves',
    kind: DocKind.purchase,
    no: 'AF-2026-0002',
    date: DateTime(2026, 8, 18),
    due: DateTime(2026, 9, 17),
    partyId: 's-vestel',
    lines: [
      line('p3', 10, 16200),
      line('p7', 12, 3100),
      line('p16', 8, 3600),
    ],
  );
  make(
    id: 'd-af-ith',
    kind: DocKind.purchase,
    no: 'AF-2026-0003',
    date: DateTime(2026, 9, 3),
    due: DateTime(2026, 11, 2),
    partyId: 's-ithal',
    lines: [
      line('p4', 4, 21400),
      line('p5', 5, 14800),
      line('p8', 6, 26800, serials: ['BAY1200001', 'BAY1200002', 'BAY1200003']),
      line('p9', 4, 29400, serials: ['DAI1200001', 'DAI1200002']),
      line('p10', 6, 17100),
      line('p11', 5, 14900),
      line('p12', 10, 4200),
      line('p13', 15, 1450),
      line('p14', 12, 2100),
      line('p15', 10, 2800),
    ],
  );

  make(
    id: 'd-sf-y1',
    kind: DocKind.sale,
    no: 'SF-2026-0001',
    date: DateTime(2026, 8, 28),
    due: DateTime(2026, 9, 27),
    partyId: 'c-yildiz',
    eDoc: EDocStatus.issued,
    note: 'Bayi sevkiyatı',
    lines: [
      line('p1', 3, 26500, serials: ['ARC5705050001', 'ARC5705050002', 'ARC5705050003']),
      line('p3', 2, 17800),
    ],
  );
  make(
    id: 'd-sf-ege',
    kind: DocKind.sale,
    no: 'SF-2026-0002',
    date: DateTime(2026, 9, 15),
    due: DateTime(2026, 10, 30),
    partyId: 'c-ege',
    eDoc: EDocStatus.issued,
    lines: [
      line('p2', 2, 22000),
      line('p5', 2, 16500),
      line('p6', 2, 10500, note: 'Montaj bayiye ait'),
    ],
  );
  make(
    id: 'd-sf-kar',
    kind: DocKind.sale,
    no: 'SF-2026-0003',
    date: DateTime(2026, 9, 8),
    due: DateTime(2026, 10, 8),
    partyId: 'c-kar',
    eDoc: EDocStatus.queued,
    lines: [
      line('p8', 2, 29500, serials: ['BAY1200001', 'BAY1200002'], note: 'Montaj dahil'),
      line('p9', 1, 32000, serials: ['DAI1200001']),
    ],
  );
  make(
    id: 'd-sf-anka',
    kind: DocKind.sale,
    no: 'SF-2026-0004',
    date: DateTime(2026, 9, 22),
    due: DateTime(2026, 10, 13),
    partyId: 'c-anka',
    lines: [
      line('p6', 3, 9800, note: 'Proje iskontolu'),
      line('p7', 4, 3400),
    ],
  );
  make(
    id: 'd-sf-y2',
    kind: DocKind.sale,
    no: 'SF-2026-0005',
    date: DateTime(2026, 10, 2),
    due: DateTime(2026, 11, 1),
    partyId: 'c-yildiz',
    eDoc: EDocStatus.issued,
    lines: [
      line('p10', 2, 18800),
      line('p13', 4, 1750),
    ],
  );
  make(
    id: 'd-si-y1',
    kind: DocKind.saleReturn,
    no: 'SI-2026-0001',
    date: DateTime(2026, 10, 3),
    due: DateTime(2026, 10, 3),
    partyId: 'c-yildiz',
    note: 'SF-2026-0005 ütü iadesi, kutu hasarlı',
    returnReason: 'Kutu hasarlı',
    lines: [line('p13', 1, 1750)],
  );
  make(
    id: 'd-irs-y',
    kind: DocKind.saleWaybill,
    no: 'IRS-2026-0001',
    date: DateTime(2026, 10, 1),
    due: DateTime(2026, 10, 1),
    partyId: 'c-yildiz',
    note: 'Faturası kesilmedi',
    lines: [line('p12', 2, 4700)],
  );
  make(
    id: 'd-ss-anka',
    kind: DocKind.saleOrder,
    no: 'SS-2026-0001',
    date: DateTime(2026, 10, 4),
    due: DateTime(2026, 10, 20),
    partyId: 'c-anka',
    note: 'Proje teslimatı 20 Ekim',
    lines: [line('p8', 4, 29500)],
  );

  final vestel = store.docById('d-af-ves')!;
  store.addPayment(
    Payment(
      id: 'pay-ves',
      no: 'OD-2026-0001',
      date: DateTime(2026, 9, 10),
      partyId: 's-vestel',
      docId: vestel.id,
      accountId: 'acc-ziraat',
      direction: PayDirection.outbound,
      method: PayMethod.transfer,
      amount: vestel.gross,
      note: 'Vestel faturası kapandı',
    ),
  );
  store.addPayment(
    Payment(
      id: 'pay-arc',
      no: 'OD-2026-0002',
      date: DateTime(2026, 9, 20),
      partyId: 's-arcelik',
      docId: 'd-af-arc',
      accountId: 'acc-ziraat',
      direction: PayDirection.outbound,
      method: PayMethod.transfer,
      amount: 200000,
      note: 'Kısmi ödeme',
    ),
  );
  store.addPayment(
    Payment(
      id: 'pay-y2',
      no: 'TH-2026-0001',
      date: DateTime(2026, 10, 2),
      partyId: 'c-yildiz',
      docId: 'd-sf-y2',
      accountId: 'acc-garanti',
      direction: PayDirection.inbound,
      method: PayMethod.transfer,
      amount: 51420,
      note: 'İade düşülmüş tahsilat',
    ),
  );
  store.addPayment(
    Payment(
      id: 'pay-anka',
      no: 'TH-2026-0002',
      date: DateTime(2026, 9, 28),
      partyId: 'c-anka',
      docId: 'd-sf-anka',
      accountId: 'acc-garanti',
      direction: PayDirection.inbound,
      method: PayMethod.transfer,
      amount: 25000,
      note: 'Kısmi tahsilat',
    ),
  );
  store.addPayment(
    Payment(
      id: 'pay-devir',
      no: 'TH-2026-0003',
      date: DateTime(2026, 8, 1),
      accountId: 'acc-kasa',
      direction: PayDirection.inbound,
      method: PayMethod.cash,
      amount: 75000,
      note: 'Açılış devri',
    ),
  );
  store.addPayment(
    Payment(
      id: 'pay-nak',
      no: 'OD-2026-0003',
      date: DateTime(2026, 9, 30),
      accountId: 'acc-kasa',
      direction: PayDirection.outbound,
      method: PayMethod.cash,
      amount: 2500,
      note: 'Şehirler arası nakliye',
    ),
  );

  final yildizGross = store.docById('d-sf-y1')!.gross;
  store.addInstrument(
    Instrument(
      id: 'cek-y',
      kind: InstrumentKind.check,
      direction: InstrumentDirection.received,
      no: 'CHK-100245',
      bank: 'Türkiye İş Bankası',
      branch: 'Bayrampaşa',
      issuer: 'Yıldız Elektrik',
      amount: yildizGross,
      issueDate: DateTime(2026, 8, 28),
      dueDate: DateTime(2026, 9, 28),
      partyId: 'c-yildiz',
      docId: 'd-sf-y1',
      note: 'Karşılıksız döndü',
    ),
  );
  store.bounceInstrument('cek-y');

  final egeGross = store.docById('d-sf-ege')!.gross;
  store.addInstrument(
    Instrument(
      id: 'cek-ege',
      kind: InstrumentKind.check,
      direction: InstrumentDirection.received,
      no: 'CHK-558120',
      bank: 'Yapı Kredi',
      branch: 'Karşıyaka',
      issuer: 'Ege Beyaz Eşya',
      amount: egeGross,
      issueDate: DateTime(2026, 9, 15),
      dueDate: DateTime(2026, 10, 20),
      partyId: 'c-ege',
      docId: 'd-sf-ege',
    ),
  );
  store.collectInstrument('cek-ege', 'acc-ziraat');

  store.addInstrument(
    Instrument(
      id: 'cek-arc',
      kind: InstrumentKind.check,
      direction: InstrumentDirection.issued,
      no: 'KSD-00055',
      bank: 'Ziraat Bankası',
      branch: 'İkitelli',
      issuer: 'Akım Elektrik',
      amount: 100000,
      issueDate: DateTime(2026, 9, 25),
      dueDate: DateTime(2026, 10, 18),
      partyId: 's-arcelik',
      docId: 'd-af-arc',
    ),
  );
  store.addInstrument(
    Instrument(
      id: 'snt-kar',
      kind: InstrumentKind.promissory,
      direction: InstrumentDirection.received,
      no: 'SNT-2026-14',
      issuer: 'Karadeniz Klima',
      amount: 50000,
      issueDate: DateTime(2026, 9, 8),
      dueDate: DateTime(2026, 10, 6),
      partyId: 'c-kar',
      docId: 'd-sf-kar',
      note: 'Vadesi bu hafta',
    ),
  );

  store.transfer(
    productId: 'p11',
    fromId: 'w-merkez',
    toId: 'w-anadolu',
    qty: 2,
    note: 'Gebze showroom sevki',
  );

  store.upsertTicket(
    ServiceTicket(
      id: 'srv-1',
      no: 'SRV-2026-0001',
      date: DateTime(2026, 9, 26),
      partyId: 'c-kar',
      productId: 'p8',
      serial: 'BAY1200001',
      fault: 'Dış ünite gaz kaçağı, montaj kaynaklı',
      status: TicketStatus.inProgress,
      underWarranty: true,
      note: 'Yetkili servis yönlendirildi',
    ),
  );
  store.upsertTicket(
    ServiceTicket(
      id: 'srv-2',
      no: 'SRV-2026-0002',
      date: DateTime(2026, 10, 3),
      partyId: 'c-yildiz',
      productId: 'p10',
      fault: 'Kumanda ve ayak takımı eksik çıktı',
      resolution: 'Aksesuar gönderildi',
      status: TicketStatus.done,
      underWarranty: false,
      fee: 850,
      feeInvoiced: true,
      note: 'Garanti dışı aksesuar',
    ),
  );
}
