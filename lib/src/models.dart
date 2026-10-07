double round2(double v) => (v * 100).roundToDouble() / 100.0;

DateTime addMonths(DateTime date, int months) {
  final total = date.month - 1 + months;
  final year = date.year + total ~/ 12;
  final month = total % 12 + 1;
  final last = DateTime(year, month + 1, 0).day;
  final day = date.day < last ? date.day : last;
  return DateTime(year, month, day);
}

T enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final name = raw?.toString();
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

const applianceCategories = <String>[
  'Buzdolabı',
  'Çamaşır Makinesi',
  'Kurutma Makinesi',
  'Bulaşık Makinesi',
  'Ankastre Fırın',
  'Ocak',
  'Davlumbaz',
  'Klima',
  'Televizyon',
  'Elektrikli Süpürge',
  'Ütü',
  'Kahve Makinesi',
  'Airfryer',
  'Su Sebili',
  'Isıtıcı',
  'Vantilatör',
  'Aydınlatma',
  'Yedek Parça',
];

const applianceBrands = <String>[
  'Arçelik',
  'Beko',
  'Altus',
  'Vestel',
  'Profilo',
  'Bosch',
  'Siemens',
  'Samsung',
  'LG',
  'Philips',
  'Tefal',
  'Arzum',
  'Fakir',
  'Kumtel',
  'Baymak',
  'Daikin',
  'Grundig',
  'Karaca',
];

const energyClasses = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'Yok'];

enum PartyType { customer, supplier, both }

enum DocKind {
  sale,
  purchase,
  saleReturn,
  purchaseReturn,
  saleOrder,
  purchaseOrder,
  saleWaybill,
  purchaseWaybill,
  saleQuote,
}

enum DocStatus { draft, approved, cancelled, invoiced }

enum EDocStatus { none, queued, issued, cancelled }

enum DeliveryStatus { none, preparing, onTheWay, delivered }

enum MoveType { document, manual, transfer, count, service }

enum SerialStatus { inStock, sold, service, returned }

enum PayDirection { inbound, outbound }

enum PayMethod { cash, transfer, card, check, note }

enum AccountRole { cash, bank, checkPortfolio, issuedChecks }

enum InstrumentKind { check, promissory }

enum InstrumentDirection { received, issued }

enum InstrumentStatus { portfolio, deposited, collected, paid, bounced, endorsed, returned }

enum TicketStatus { open, inProgress, waitingPart, done, cancelled }

bool kindAffectsStock(DocKind kind) {
  return kind != DocKind.saleOrder && kind != DocKind.purchaseOrder && kind != DocKind.saleQuote;
}

bool kindAffectsCari(DocKind kind) {
  return kind == DocKind.sale ||
      kind == DocKind.purchase ||
      kind == DocKind.saleReturn ||
      kind == DocKind.purchaseReturn;
}

bool kindIsInbound(DocKind kind) {
  return kind == DocKind.purchase ||
      kind == DocKind.saleReturn ||
      kind == DocKind.purchaseWaybill;
}

class CompanyProfile {
  CompanyProfile({
    required this.name,
    required this.shortName,
    this.taxNo = '',
    this.taxOffice = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.iban = '',
    this.defaultVat = 20,
    this.defaultTermDays = 30,
    this.monthlyTarget = 0,
  });

  String name;
  String shortName;
  String taxNo;
  String taxOffice;
  String phone;
  String email;
  String address;
  String city;
  String iban;
  double defaultVat;
  int defaultTermDays;
  double monthlyTarget;

  Map<String, dynamic> toJson() => {
        'name': name,
        'shortName': shortName,
        'taxNo': taxNo,
        'taxOffice': taxOffice,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'iban': iban,
        'defaultVat': defaultVat,
        'defaultTermDays': defaultTermDays,
        'monthlyTarget': monthlyTarget,
      };

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        name: json['name'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        taxNo: json['taxNo'] as String? ?? '',
        taxOffice: json['taxOffice'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        iban: json['iban'] as String? ?? '',
        defaultVat: (json['defaultVat'] as num?)?.toDouble() ?? 20,
        defaultTermDays: (json['defaultTermDays'] as num?)?.toInt() ?? 30,
        monthlyTarget: (json['monthlyTarget'] as num?)?.toDouble() ?? 0,
      );
}

class Warehouse {
  Warehouse({
    required this.id,
    required this.name,
    this.city = '',
    this.address = '',
  });

  String id;
  String name;
  String city;
  String address;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'address': address,
      };

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
}

class Product {
  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.brand,
    required this.category,
    this.barcode = '',
    this.energyClass = 'A',
    this.warrantyMonths = 24,
    this.watt = 0,
    this.color = '',
    this.origin = 'Türkiye',
    this.desi = 0,
    this.needsInstall = false,
    this.trackSerial = false,
    this.vatRate = 20,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.minStock = 0,
    this.shelf = '',
    this.warehouseId = '',
    this.active = true,
    this.note = '',
  });

  String id;
  String sku;
  String barcode;
  String name;
  String brand;
  String category;
  String energyClass;
  int warrantyMonths;
  int watt;
  String color;
  String origin;
  double desi;
  bool needsInstall;
  bool trackSerial;
  double vatRate;
  double purchasePrice;
  double salePrice;
  double minStock;
  String shelf;
  String warehouseId;
  bool active;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'category': category,
        'energyClass': energyClass,
        'warrantyMonths': warrantyMonths,
        'watt': watt,
        'color': color,
        'origin': origin,
        'desi': desi,
        'needsInstall': needsInstall,
        'trackSerial': trackSerial,
        'vatRate': vatRate,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'minStock': minStock,
        'shelf': shelf,
        'warehouseId': warehouseId,
        'active': active,
        'note': note,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        sku: json['sku'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        category: json['category'] as String? ?? '',
        energyClass: json['energyClass'] as String? ?? 'A',
        warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 24,
        watt: (json['watt'] as num?)?.toInt() ?? 0,
        color: json['color'] as String? ?? '',
        origin: json['origin'] as String? ?? '',
        desi: (json['desi'] as num?)?.toDouble() ?? 0,
        needsInstall: json['needsInstall'] as bool? ?? false,
        trackSerial: json['trackSerial'] as bool? ?? false,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 20,
        purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
        salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
        minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
        shelf: json['shelf'] as String? ?? '',
        warehouseId: json['warehouseId'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        note: json['note'] as String? ?? '',
      );
}

class Party {
  Party({
    required this.id,
    required this.type,
    required this.name,
    this.taxNo = '',
    this.taxOffice = '',
    this.contact = '',
    this.phone = '',
    this.email = '',
    this.city = '',
    this.address = '',
    this.creditLimit = 0,
    this.termDays = 30,
    this.priceListId = '',
    this.note = '',
    this.active = true,
    this.salesRep = '',
    this.reconciledOn,
  });

  String id;
  PartyType type;
  String name;
  String taxNo;
  String taxOffice;
  String contact;
  String phone;
  String email;
  String city;
  String address;
  double creditLimit;
  int termDays;
  String priceListId;
  String note;
  bool active;
  String salesRep;
  DateTime? reconciledOn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'taxNo': taxNo,
        'taxOffice': taxOffice,
        'contact': contact,
        'phone': phone,
        'email': email,
        'city': city,
        'address': address,
        'creditLimit': creditLimit,
        'termDays': termDays,
        'priceListId': priceListId,
        'note': note,
        'active': active,
        'salesRep': salesRep,
        'reconciledOn': reconciledOn?.toIso8601String(),
      };

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        id: json['id'] as String,
        type: enumByName(PartyType.values, json['type'], PartyType.customer),
        name: json['name'] as String? ?? '',
        taxNo: json['taxNo'] as String? ?? '',
        taxOffice: json['taxOffice'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        city: json['city'] as String? ?? '',
        address: json['address'] as String? ?? '',
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        termDays: (json['termDays'] as num?)?.toInt() ?? 30,
        priceListId: json['priceListId'] as String? ?? '',
        note: json['note'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        salesRep: json['salesRep'] as String? ?? '',
        reconciledOn: json['reconciledOn'] == null ? null : DateTime.parse(json['reconciledOn'] as String),
      );
}

class PriceList {
  PriceList({
    required this.id,
    required this.name,
    this.discountPercent = 0,
    this.note = '',
    this.active = true,
  });

  String id;
  String name;
  double discountPercent;
  String note;
  bool active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'discountPercent': discountPercent,
        'note': note,
        'active': active,
      };

  factory PriceList.fromJson(Map<String, dynamic> json) => PriceList(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
        active: json['active'] as bool? ?? true,
      );
}

class SpecialPrice {
  SpecialPrice({
    required this.id,
    required this.partyId,
    required this.productId,
    required this.price,
  });

  String id;
  String partyId;
  String productId;
  double price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'partyId': partyId,
        'productId': productId,
        'price': price,
      };

  factory SpecialPrice.fromJson(Map<String, dynamic> json) => SpecialPrice(
        id: json['id'] as String? ?? '',
        partyId: json['partyId'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

class DocLine {
  DocLine({
    required this.productId,
    required this.qty,
    required this.unitPrice,
    this.discountRate = 0,
    this.vatRate = 20,
    List<String>? serials,
    this.note = '',
    this.unitCost,
  }) : serials = serials ?? <String>[];

  String productId;
  double qty;
  double unitPrice;
  double discountRate;
  double vatRate;
  List<String> serials;
  String note;
  double? unitCost;

  double get net => round2(qty * unitPrice * (1 - discountRate / 100));
  double get vatAmount => round2(net * vatRate / 100);
  double get gross => round2(net + vatAmount);

  DocLine copy() => DocLine(
        productId: productId,
        qty: qty,
        unitPrice: unitPrice,
        discountRate: discountRate,
        vatRate: vatRate,
        serials: List<String>.from(serials),
        note: note,
        unitCost: unitCost,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'qty': qty,
        'unitPrice': unitPrice,
        'discountRate': discountRate,
        'vatRate': vatRate,
        'serials': serials,
        'note': note,
        'unitCost': unitCost,
      };

  factory DocLine.fromJson(Map<String, dynamic> json) => DocLine(
        productId: json['productId'] as String? ?? '',
        qty: (json['qty'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 20,
        serials: (json['serials'] as List?)?.map((e) => e.toString()).toList(),
        note: json['note'] as String? ?? '',
        unitCost: json['unitCost'] == null ? null : (json['unitCost'] as num).toDouble(),
      );
}

class TradeDoc {
  TradeDoc({
    required this.id,
    required this.kind,
    required this.status,
    required this.no,
    required this.date,
    required this.dueDate,
    required this.partyId,
    required this.warehouseId,
    List<DocLine>? lines,
    this.note = '',
    this.shipping = 0,
    this.stockPosted = false,
    this.sourceDocId = '',
    this.eDoc = EDocStatus.none,
    this.shipAddress = '',
    this.deliveryStatus = DeliveryStatus.none,
    this.promiseDate,
    this.returnReason = '',
  }) : lines = lines ?? <DocLine>[];

  String id;
  DocKind kind;
  DocStatus status;
  String no;
  DateTime date;
  DateTime dueDate;
  String partyId;
  String warehouseId;
  List<DocLine> lines;
  String note;
  double shipping;
  bool stockPosted;
  String sourceDocId;
  EDocStatus eDoc;
  String shipAddress;
  DeliveryStatus deliveryStatus;
  DateTime? promiseDate;
  String returnReason;

  double get net => round2(lines.fold(0.0, (sum, line) => sum + line.net));
  double get vatTotal => round2(lines.fold(0.0, (sum, line) => sum + line.vatAmount));
  double get gross => round2(lines.fold(0.0, (sum, line) => sum + line.gross) + shipping);

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'status': status.name,
        'no': no,
        'date': date.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'partyId': partyId,
        'warehouseId': warehouseId,
        'lines': lines.map((e) => e.toJson()).toList(),
        'note': note,
        'shipping': shipping,
        'stockPosted': stockPosted,
        'sourceDocId': sourceDocId,
        'eDoc': eDoc.name,
        'shipAddress': shipAddress,
        'deliveryStatus': deliveryStatus.name,
        'promiseDate': promiseDate?.toIso8601String(),
        'returnReason': returnReason,
      };

  factory TradeDoc.fromJson(Map<String, dynamic> json) => TradeDoc(
        id: json['id'] as String,
        kind: enumByName(DocKind.values, json['kind'], DocKind.sale),
        status: enumByName(DocStatus.values, json['status'], DocStatus.draft),
        no: json['no'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        partyId: json['partyId'] as String? ?? '',
        warehouseId: json['warehouseId'] as String? ?? '',
        lines: (json['lines'] as List?)
            ?.map((e) => DocLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        note: json['note'] as String? ?? '',
        shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
        stockPosted: json['stockPosted'] as bool? ?? false,
        sourceDocId: json['sourceDocId'] as String? ?? '',
        eDoc: enumByName(EDocStatus.values, json['eDoc'], EDocStatus.none),
        shipAddress: json['shipAddress'] as String? ?? '',
        deliveryStatus: enumByName(DeliveryStatus.values, json['deliveryStatus'], DeliveryStatus.none),
        promiseDate: json['promiseDate'] == null ? null : DateTime.parse(json['promiseDate'] as String),
        returnReason: json['returnReason'] as String? ?? '',
      );
}

class StockMove {
  StockMove({
    required this.id,
    required this.date,
    required this.productId,
    required this.warehouseId,
    required this.type,
    required this.qty,
    this.unitCost = 0,
    this.docId = '',
    this.transferId = '',
    this.note = '',
  });

  String id;
  DateTime date;
  String productId;
  String warehouseId;
  MoveType type;
  double qty;
  double unitCost;
  String docId;
  String transferId;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'productId': productId,
        'warehouseId': warehouseId,
        'type': type.name,
        'qty': qty,
        'unitCost': unitCost,
        'docId': docId,
        'transferId': transferId,
        'note': note,
      };

  factory StockMove.fromJson(Map<String, dynamic> json) => StockMove(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        productId: json['productId'] as String? ?? '',
        warehouseId: json['warehouseId'] as String? ?? '',
        type: enumByName(MoveType.values, json['type'], MoveType.manual),
        qty: (json['qty'] as num?)?.toDouble() ?? 0,
        unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
        docId: json['docId'] as String? ?? '',
        transferId: json['transferId'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

class SerialUnit {
  SerialUnit({
    required this.id,
    required this.serial,
    required this.productId,
    this.warehouseId = '',
    this.status = SerialStatus.inStock,
    this.partyId = '',
    this.soldAt,
    this.warrantyUntil,
    this.docId = '',
    this.note = '',
  });

  String id;
  String serial;
  String productId;
  String warehouseId;
  SerialStatus status;
  String partyId;
  DateTime? soldAt;
  DateTime? warrantyUntil;
  String docId;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'serial': serial,
        'productId': productId,
        'warehouseId': warehouseId,
        'status': status.name,
        'partyId': partyId,
        'soldAt': soldAt?.toIso8601String(),
        'warrantyUntil': warrantyUntil?.toIso8601String(),
        'docId': docId,
        'note': note,
      };

  factory SerialUnit.fromJson(Map<String, dynamic> json) => SerialUnit(
        id: json['id'] as String,
        serial: json['serial'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        warehouseId: json['warehouseId'] as String? ?? '',
        status: enumByName(SerialStatus.values, json['status'], SerialStatus.inStock),
        partyId: json['partyId'] as String? ?? '',
        soldAt: json['soldAt'] == null ? null : DateTime.parse(json['soldAt'] as String),
        warrantyUntil: json['warrantyUntil'] == null
            ? null
            : DateTime.parse(json['warrantyUntil'] as String),
        docId: json['docId'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

class CashAccount {
  CashAccount({
    required this.id,
    required this.name,
    required this.role,
    this.iban = '',
    this.note = '',
  });

  String id;
  String name;
  AccountRole role;
  String iban;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'iban': iban,
        'note': note,
      };

  factory CashAccount.fromJson(Map<String, dynamic> json) => CashAccount(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        role: enumByName(AccountRole.values, json['role'], AccountRole.cash),
        iban: json['iban'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

class Payment {
  Payment({
    required this.id,
    required this.no,
    required this.date,
    required this.accountId,
    required this.direction,
    required this.method,
    required this.amount,
    this.partyId = '',
    this.docId = '',
    this.instrumentId = '',
    this.groupId = '',
    this.note = '',
  });

  String id;
  String no;
  DateTime date;
  String partyId;
  String docId;
  String accountId;
  PayDirection direction;
  PayMethod method;
  double amount;
  String instrumentId;
  String groupId;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'no': no,
        'date': date.toIso8601String(),
        'partyId': partyId,
        'docId': docId,
        'accountId': accountId,
        'direction': direction.name,
        'method': method.name,
        'amount': amount,
        'instrumentId': instrumentId,
        'groupId': groupId,
        'note': note,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        no: json['no'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        partyId: json['partyId'] as String? ?? '',
        docId: json['docId'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        direction: enumByName(PayDirection.values, json['direction'], PayDirection.inbound),
        method: enumByName(PayMethod.values, json['method'], PayMethod.cash),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        instrumentId: json['instrumentId'] as String? ?? '',
        groupId: json['groupId'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

class Instrument {
  Instrument({
    required this.id,
    required this.kind,
    required this.direction,
    required this.no,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    required this.partyId,
    this.status = InstrumentStatus.portfolio,
    this.bank = '',
    this.branch = '',
    this.issuer = '',
    this.accountId = '',
    this.docId = '',
    this.endorsedToPartyId = '',
    this.note = '',
  });

  String id;
  InstrumentKind kind;
  InstrumentDirection direction;
  InstrumentStatus status;
  String no;
  String bank;
  String branch;
  String issuer;
  double amount;
  DateTime issueDate;
  DateTime dueDate;
  String partyId;
  String accountId;
  String docId;
  String endorsedToPartyId;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'direction': direction.name,
        'status': status.name,
        'no': no,
        'bank': bank,
        'branch': branch,
        'issuer': issuer,
        'amount': amount,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'partyId': partyId,
        'accountId': accountId,
        'docId': docId,
        'endorsedToPartyId': endorsedToPartyId,
        'note': note,
      };

  factory Instrument.fromJson(Map<String, dynamic> json) => Instrument(
        id: json['id'] as String,
        kind: enumByName(InstrumentKind.values, json['kind'], InstrumentKind.check),
        direction: enumByName(
          InstrumentDirection.values,
          json['direction'],
          InstrumentDirection.received,
        ),
        status: enumByName(InstrumentStatus.values, json['status'], InstrumentStatus.portfolio),
        no: json['no'] as String? ?? '',
        bank: json['bank'] as String? ?? '',
        branch: json['branch'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        issueDate: DateTime.parse(json['issueDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        partyId: json['partyId'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        docId: json['docId'] as String? ?? '',
        endorsedToPartyId: json['endorsedToPartyId'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

class ServiceTicket {
  ServiceTicket({
    required this.id,
    required this.no,
    required this.date,
    required this.partyId,
    required this.productId,
    this.serial = '',
    this.fault = '',
    this.resolution = '',
    this.status = TicketStatus.open,
    this.underWarranty = false,
    this.fee = 0,
    this.feeInvoiced = false,
    this.note = '',
  });

  String id;
  String no;
  DateTime date;
  String partyId;
  String productId;
  String serial;
  String fault;
  String resolution;
  TicketStatus status;
  bool underWarranty;
  double fee;
  bool feeInvoiced;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'no': no,
        'date': date.toIso8601String(),
        'partyId': partyId,
        'productId': productId,
        'serial': serial,
        'fault': fault,
        'resolution': resolution,
        'status': status.name,
        'underWarranty': underWarranty,
        'fee': fee,
        'feeInvoiced': feeInvoiced,
        'note': note,
      };

  factory ServiceTicket.fromJson(Map<String, dynamic> json) => ServiceTicket(
        id: json['id'] as String,
        no: json['no'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        partyId: json['partyId'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        serial: json['serial'] as String? ?? '',
        fault: json['fault'] as String? ?? '',
        resolution: json['resolution'] as String? ?? '',
        status: enumByName(TicketStatus.values, json['status'], TicketStatus.open),
        underWarranty: json['underWarranty'] as bool? ?? false,
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
        feeInvoiced: json['feeInvoiced'] as bool? ?? false,
        note: json['note'] as String? ?? '',
      );
}

enum CallKind { call, promise, note }

enum VisitKind { call, visit }

class PriceChange {
  PriceChange({
    required this.id,
    required this.productId,
    required this.date,
    required this.oldPurchase,
    required this.newPurchase,
    required this.oldSale,
    required this.newSale,
  });

  String id;
  String productId;
  DateTime date;
  double oldPurchase;
  double newPurchase;
  double oldSale;
  double newSale;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'date': date.toIso8601String(),
        'oldPurchase': oldPurchase,
        'newPurchase': newPurchase,
        'oldSale': oldSale,
        'newSale': newSale,
      };

  factory PriceChange.fromJson(Map<String, dynamic> json) => PriceChange(
        id: json['id'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        oldPurchase: (json['oldPurchase'] as num?)?.toDouble() ?? 0,
        newPurchase: (json['newPurchase'] as num?)?.toDouble() ?? 0,
        oldSale: (json['oldSale'] as num?)?.toDouble() ?? 0,
        newSale: (json['newSale'] as num?)?.toDouble() ?? 0,
      );
}

class VisitPlan {
  VisitPlan({
    required this.id,
    required this.partyId,
    required this.date,
    required this.kind,
    required this.text,
    this.done = false,
  });

  String id;
  String partyId;
  DateTime date;
  VisitKind kind;
  String text;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'partyId': partyId,
        'date': date.toIso8601String(),
        'kind': kind.name,
        'text': text,
        'done': done,
      };

  factory VisitPlan.fromJson(Map<String, dynamic> json) => VisitPlan(
        id: json['id'] as String? ?? '',
        partyId: json['partyId'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        kind: enumByName(VisitKind.values, json['kind'], VisitKind.call),
        text: json['text'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );
}

class PartyCall {
  PartyCall({
    required this.id,
    required this.partyId,
    required this.date,
    required this.kind,
    required this.text,
  });

  String id;
  String partyId;
  DateTime date;
  CallKind kind;
  String text;

  Map<String, dynamic> toJson() => {
        'id': id,
        'partyId': partyId,
        'date': date.toIso8601String(),
        'kind': kind.name,
        'text': text,
      };

  factory PartyCall.fromJson(Map<String, dynamic> json) => PartyCall(
        id: json['id'] as String? ?? '',
        partyId: json['partyId'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        kind: enumByName(CallKind.values, json['kind'], CallKind.note),
        text: json['text'] as String? ?? '',
      );
}

class LedgerRow {
  LedgerRow(this.date, this.title, this.debit, this.credit, {this.detail = '', this.docId = '', this.paymentId = ''});

  final DateTime date;
  final String title;
  final double debit;
  final double credit;
  final String detail;
  final String docId;
  final String paymentId;
}

class AgendaEntry {
  AgendaEntry({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.late,
    required this.partyId,
    this.docId = '',
    required this.check,
  });

  final DateTime day;
  final String title;
  final String subtitle;
  final double amount;
  final bool late;
  final String partyId;
  final String docId;
  final bool check;
}

class SearchHit {
  SearchHit(this.kind, this.id, this.title, this.subtitle);

  final String kind;
  final String id;
  final String title;
  final String subtitle;
}

class WarrantyLookup {
  WarrantyLookup({
    required this.serial,
    required this.product,
    required this.party,
    required this.inWarranty,
    required this.daysLeft,
  });

  final SerialUnit serial;
  final Product? product;
  final Party? party;
  final bool inWarranty;
  final int? daysLeft;
}
