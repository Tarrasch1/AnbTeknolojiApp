import 'models.dart';

String money(num value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return '${negative ? '-' : ''}$whole,${parts[1]} ₺';
}

String qtyText(double value) {
  if ((value - value.round()).abs() < 0.001) return value.round().toString();
  return value.toStringAsFixed(2);
}

String shortDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}

String numField(double value) {
  if ((value - value.round()).abs() < 0.0001) return value.round().toString();
  return value.toStringAsFixed(2);
}

double? parseNum(String raw) {
  var text = raw.trim().replaceAll(' ', '').replaceAll('₺', '');
  if (text.isEmpty) return null;
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }
  return double.tryParse(text);
}

String partyTypeLabel(PartyType type) {
  switch (type) {
    case PartyType.customer:
      return 'Müşteri';
    case PartyType.supplier:
      return 'Tedarikçi';
    case PartyType.both:
      return 'Müşteri ve tedarikçi';
  }
}

String docKindLabel(DocKind kind) {
  switch (kind) {
    case DocKind.sale:
      return 'Satış faturası';
    case DocKind.purchase:
      return 'Alış faturası';
    case DocKind.saleReturn:
      return 'Satış iadesi';
    case DocKind.purchaseReturn:
      return 'Alış iadesi';
    case DocKind.saleOrder:
      return 'Satış siparişi';
    case DocKind.purchaseOrder:
      return 'Alış siparişi';
    case DocKind.saleWaybill:
      return 'Satış irsaliyesi';
    case DocKind.purchaseWaybill:
      return 'Alış irsaliyesi';
    case DocKind.saleQuote:
      return 'Satış teklifi';
  }
}

String docKindShort(DocKind kind) {
  switch (kind) {
    case DocKind.sale:
      return 'Satış';
    case DocKind.purchase:
      return 'Alış';
    case DocKind.saleReturn:
      return 'Satış iade';
    case DocKind.purchaseReturn:
      return 'Alış iade';
    case DocKind.saleOrder:
      return 'Alınan sipariş';
    case DocKind.purchaseOrder:
      return 'Verilen sipariş';
    case DocKind.saleWaybill:
      return 'Çıkış irsaliyesi';
    case DocKind.purchaseWaybill:
      return 'Giriş irsaliyesi';
    case DocKind.saleQuote:
      return 'Teklif';
  }
}

String docStatusText(DocStatus status, DocKind kind) {
  if (kind == DocKind.saleQuote && status == DocStatus.invoiced) return 'Dönüştü';
  return docStatusLabel(status);
}

String docStatusLabel(DocStatus status) {
  switch (status) {
    case DocStatus.draft:
      return 'Taslak';
    case DocStatus.approved:
      return 'Onaylı';
    case DocStatus.cancelled:
      return 'İptal';
    case DocStatus.invoiced:
      return 'Faturalandı';
  }
}

String eDocLabel(EDocStatus status) {
  switch (status) {
    case EDocStatus.none:
      return 'E-belge yok';
    case EDocStatus.queued:
      return 'E-belge kuyrukta';
    case EDocStatus.issued:
      return 'E-belge kesildi';
    case EDocStatus.cancelled:
      return 'E-belge iptal';
  }
}

String deliveryLabel(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.none:
      return 'Belirsiz';
    case DeliveryStatus.preparing:
      return 'Hazırlanıyor';
    case DeliveryStatus.onTheWay:
      return 'Yolda';
    case DeliveryStatus.delivered:
      return 'Teslim edildi';
  }
}

String payMethodLabel(PayMethod method) {
  switch (method) {
    case PayMethod.cash:
      return 'Nakit';
    case PayMethod.transfer:
      return 'Havale / EFT';
    case PayMethod.card:
      return 'Kredi kartı';
    case PayMethod.check:
      return 'Çek';
    case PayMethod.note:
      return 'Senet';
  }
}

String accountRoleLabel(AccountRole role) {
  switch (role) {
    case AccountRole.cash:
      return 'Kasa';
    case AccountRole.bank:
      return 'Banka';
    case AccountRole.checkPortfolio:
      return 'Çek portföyü';
    case AccountRole.issuedChecks:
      return 'Verilen çekler';
  }
}

String serialStatusLabel(SerialStatus status) {
  switch (status) {
    case SerialStatus.inStock:
      return 'Depoda';
    case SerialStatus.sold:
      return 'Satıldı';
    case SerialStatus.service:
      return 'Serviste';
    case SerialStatus.returned:
      return 'İade';
  }
}

String ticketStatusLabel(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return 'Açık';
    case TicketStatus.inProgress:
      return 'İşlemde';
    case TicketStatus.waitingPart:
      return 'Parça bekliyor';
    case TicketStatus.done:
      return 'Kapandı';
    case TicketStatus.cancelled:
      return 'İptal';
  }
}

String instrumentStatusLabel(Instrument item) {
  switch (item.status) {
    case InstrumentStatus.portfolio:
      return item.direction == InstrumentDirection.received ? 'Portföyde' : 'Keşide';
    case InstrumentStatus.deposited:
      return 'Tahsile verildi';
    case InstrumentStatus.collected:
      return 'Tahsil edildi';
    case InstrumentStatus.paid:
      return 'Ödendi';
    case InstrumentStatus.bounced:
      return 'Karşılıksız';
    case InstrumentStatus.endorsed:
      return 'Ciro edildi';
    case InstrumentStatus.returned:
      return 'İade edildi';
  }
}

String balancePhrase(double balance) {
  if (balance > 0.009) return 'Borçlu ${money(balance)}';
  if (balance < -0.009) return 'Alacaklı ${money(-balance)}';
  return 'Kapalı';
}

String docPrefix(DocKind kind) {
  switch (kind) {
    case DocKind.sale:
      return 'SF';
    case DocKind.purchase:
      return 'AF';
    case DocKind.saleReturn:
      return 'SI';
    case DocKind.purchaseReturn:
      return 'AI';
    case DocKind.saleOrder:
      return 'SS';
    case DocKind.purchaseOrder:
      return 'AS';
    case DocKind.saleWaybill:
      return 'IRS';
    case DocKind.purchaseWaybill:
      return 'IRG';
    case DocKind.saleQuote:
      return 'TK';
  }
}
