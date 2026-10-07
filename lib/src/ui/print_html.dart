import '../format.dart';
import '../models.dart';
import '../store.dart';

String documentHtml(AppStore store, TradeDoc doc) {
  final party = store.partyById(doc.partyId);
  final profile = store.profile;
  final rows = doc.lines.map((line) {
    final product = store.productById(line.productId);
    return '''
      <tr>
        <td>${_esc(product?.name ?? 'Ürün')}<div class="muted">${_esc(product?.sku ?? '')}</div></td>
        <td class="num">${_esc(qtyText(line.qty))}</td>
        <td class="num">${_esc(money(line.unitPrice))}</td>
        <td class="num">%${_esc(qtyText(line.discountRate))}</td>
        <td class="num">%${_esc(qtyText(line.vatRate))}</td>
        <td class="num">${_esc(money(line.gross))}</td>
      </tr>''';
  }).join();
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>${_esc(doc.no)} · ${_esc(docKindLabel(doc.kind))}</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  .row { display: flex; justify-content: space-between; gap: 24px; margin-top: 16px; }
  .box { flex: 1; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; }
  .total { margin-top: 12px; margin-left: auto; width: 260px; }
  .total div { display: flex; justify-content: space-between; padding: 3px 0; }
  .grand { font-size: 18px; font-weight: 800; }
  .note { margin-top: 16px; font-size: 12px; color: #64748b; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">${_esc(profile.address)} ${_esc(profile.city)} · VKN ${_esc(profile.taxNo)} · ${_esc(profile.taxOffice)}</div>
  <div class="muted">${_esc(profile.iban)}</div>
  <div class="row">
    <div class="box">
      <strong>${_esc(docKindLabel(doc.kind))}</strong>
      <div>${_esc(doc.no)}</div>
      <div class="muted">Tarih ${_esc(shortDate(doc.date))} · Vade ${_esc(shortDate(doc.dueDate))}</div>
      <div class="muted">Depo ${_esc(store.warehouseName(doc.warehouseId))}</div>
    </div>
    <div class="box">
      <strong>${_esc(party?.name ?? 'Cari yok')}</strong>
      <div class="muted">${_esc(party?.address ?? '')} ${_esc(party?.city ?? '')}</div>
      ${doc.shipAddress.isEmpty ? '' : '<div>Sevkiyat: ${_esc(doc.shipAddress)}</div>'}
      <div class="muted">VKN ${_esc(party?.taxNo ?? '')} · ${_esc(party?.taxOffice ?? '')}</div>
    </div>
  </div>
  <table>
    <thead><tr><th>Ürün</th><th class="num">Miktar</th><th class="num">Birim</th><th class="num">İskonto</th><th class="num">KDV</th><th class="num">Tutar</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
  <div class="total">
    <div><span>Ara toplam</span><span>${_esc(money(doc.net))}</span></div>
    <div><span>KDV</span><span>${_esc(money(doc.vatTotal))}</span></div>
    <div><span>Nakliye</span><span>${_esc(money(doc.shipping))}</span></div>
    <div class="grand"><span>Genel toplam</span><span>${_esc(money(doc.gross))}</span></div>
  </div>
  ${doc.note.isEmpty ? '' : '<p>${_esc(doc.note)}</p>'}
  <p class="note">Bu çıktı şirket içi belgedir. GİB e-fatura veya e-irsaliye yerine geçmez.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String statementHtml(
  AppStore store,
  Party party,
  List<({DateTime? date, String title, String detail, double debit, double credit, double balance})> lines,
) {
  final profile = store.profile;
  final rows = lines.map((line) {
    return '''
      <tr>
        <td>${line.date == null ? '' : _esc(shortDate(line.date!))}</td>
        <td>${_esc(line.title)}${line.detail.isEmpty ? '' : '<div>${_esc(line.detail).replaceAll('\n', '<br>')}</div>'}</td>
        <td class="num">${line.debit == 0 ? '' : _esc(money(line.debit))}</td>
        <td class="num">${line.credit == 0 ? '' : _esc(money(line.credit))}</td>
        <td class="num">${_esc(money(line.balance))}</td>
      </tr>''';
  }).join();
  final note = party.note.trim().isEmpty ? 'Not yok' : party.note.trim();
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Ekstre · ${_esc(party.name)}</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  .note { margin: 12px 0; padding: 10px 12px; border: 1px solid #e2e8f0; border-radius: 8px; }
  table { width: 100%; border-collapse: collapse; margin-top: 12px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Hesap ekstresi · ${_esc(party.name)} · ${_esc(partyTypeLabel(party.type))}</div>
  <div class="note"><strong>Not</strong><div>${_esc(note)}</div></div>
  <table>
    <thead><tr><th>Tarih</th><th>Açıklama</th><th class="num">Borç</th><th class="num">Alacak</th><th class="num">Bakiye</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
  <p class="muted">Bu çıktı şirket içi ekstre belgesidir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String reconcileHtml(AppStore store, Party party) {
  final profile = store.profile;
  final balance = store.partyBalance(party.id);
  final sentence = balance > 0.009
      ? '${_esc(party.name)} firmasının ${_esc(shortDate(DateTime.now()))} tarihi itibarıyla bakiyesi ${_esc(money(balance))} borçtur.'
      : balance < -0.009
          ? '${_esc(profile.shortName.isEmpty ? profile.name : profile.shortName)} firmasının ${_esc(party.name)} firmasına ${_esc(shortDate(DateTime.now()))} tarihi itibarıyla borcu ${_esc(money(balance.abs()))} tutarındadır.'
          : '${_esc(party.name)} hesabı ${_esc(shortDate(DateTime.now()))} tarihi itibarıyla kapalıdır.';
  final note = party.note.trim().isEmpty ? 'Not yok' : party.note.trim();
  final agreed = party.reconciledOn == null ? 'Son mutabakat tarihi yok.' : 'Son mutabakat ${_esc(shortDate(party.reconciledOn!))}.';
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Mutabakat · ${_esc(party.name)}</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 32px; }
  h1 { font-size: 22px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  .sheet { margin-top: 28px; border: 1px solid #e2e8f0; border-radius: 12px; padding: 20px; }
  .balance { font-size: 28px; font-weight: 800; margin: 12px 0; }
  .note { margin-top: 16px; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">${_esc(profile.address)} ${_esc(profile.city)} · VKN ${_esc(profile.taxNo)} · ${_esc(profile.taxOffice)}</div>
  <div class="sheet">
    <strong>Cari mutabakat</strong>
    <div>${_esc(party.name)}</div>
    <div class="muted">${_esc(partyTypeLabel(party.type))} · ${_esc(party.city)} · VKN ${_esc(party.taxNo)}</div>
    <div class="balance">${_esc(balancePhrase(balance))}</div>
    <p>$sentence</p>
    <p>$agreed</p>
    <div class="note"><strong>Not</strong><div>${_esc(note)}</div></div>
  </div>
  <p class="muted">Bu çıktı şirket içi mutabakat mektubudur. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String orderListHtml(AppStore store, {bool purchases = false}) {
  final rows = purchases ? store.openPurchaseOrders() : store.openSaleOrders();
  final title = purchases ? 'Açık alış siparişleri' : 'Açık satış siparişleri';
  final body = rows.map((doc) {
    final party = store.partyById(doc.partyId);
    final lines = doc.lines.map((line) => '${_esc(store.productName(line.productId))} · ${_esc(qtyText(line.qty))} adet').join('<br>');
    return '''
      <tr>
        <td>${_esc(doc.no)}<div class="muted">${_esc(shortDate(doc.date))}</div></td>
        <td>${_esc(party?.name ?? 'Cari yok')}<div class="muted">${_esc(party?.phone.trim().isEmpty ?? true ? 'Telefon yok' : party!.phone.trim())}</div></td>
        <td>$lines</td>
      </tr>''';
  }).join();
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>${_esc(title)}</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">${_esc(title)} · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Onaylı ve henüz faturası kesilmemiş siparişler. Faturaya dönünce listeden düşer.</div>
  <table>
    <thead><tr><th>Belge</th><th>Cari</th><th>Ürünler</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p class="muted">Bu çıktı şirket içi sipariş listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String promiseHtml(AppStore store) {
  final rows = store.duePromises();
  final body = rows.map((doc) {
    final party = store.partyById(doc.partyId);
    final phone = party == null || party.phone.trim().isEmpty ? 'Telefon yok' : party.phone.trim();
    return '''
      <tr>
        <td>${_esc(doc.no)}</td>
        <td>${_esc(party?.name ?? 'Cari yok')}<div class="muted">${_esc(phone)}</div></td>
        <td>${_esc(shortDate(doc.promiseDate!))}</td>
        <td class="num">${_esc(money(store.docRemaining(doc)))}</td>
      </tr>''';
  }).join();
  final total = rows.fold<double>(0, (sum, doc) => sum + store.docRemaining(doc));
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Ödeme sözü</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; font-weight: 700; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Ödeme sözü · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Söz tarihi bugün veya geçmiş, kapanmamış satışlar. İleri tarihli söz bu listede yoktur.</div>
  <table>
    <thead><tr><th>Fatura</th><th>Cari</th><th>Söz</th><th class="num">Kalan</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p><strong>Toplam kalan ${_esc(money(total))}</strong></p>
  <p class="muted">Bu çıktı şirket içi tahsilat listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String cashCloseHtml(AppStore store) {
  final rows = store.cashClose();
  final body = rows.map((row) {
    final lines = row.lines.map((payment) {
      final way = payment.direction == PayDirection.inbound ? 'Giriş' : 'Çıkış';
      final who = payment.partyId.isEmpty ? 'Cari yok' : store.partyName(payment.partyId);
      final note = payment.note.trim().isEmpty ? payMethodLabel(payment.method) : payment.note.trim();
      return '<div>${_esc(way)} · ${_esc(who)} · ${_esc(note)} · ${_esc(money(payment.amount))}</div>';
    }).join();
    return '''
      <tr>
        <td>${_esc(row.account.name)}</td>
        <td>$lines</td>
        <td class="num">${_esc(money(row.inbound))}</td>
        <td class="num">${_esc(money(row.outbound))}</td>
        <td class="num">${_esc(money(row.inbound - row.outbound))}</td>
      </tr>''';
  }).join();
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Kasa gün sonu</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Kasa gün sonu · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Kasa ve banka. Çek portföyü bu listede yoktur. Virman aynı tutarı giriş ve çıkış olarak yazar.</div>
  <table>
    <thead><tr><th>Hesap</th><th>Hareket</th><th class="num">Giriş</th><th class="num">Çıkış</th><th class="num">Net</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p class="muted">Bu çıktı şirket içi kasa dökümüdür. Banka ekstresi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String limitHtml(AppStore store) {
  final rows = store.overLimitParties();
  final body = rows.map((row) {
    final phone = row.party.phone.trim().isEmpty ? 'Telefon yok' : row.party.phone.trim();
    return '''
      <tr>
        <td>${_esc(row.party.name)}<div class="muted">${_esc(row.party.city)} · ${_esc(phone)}</div></td>
        <td class="num">${_esc(money(row.balance))}</td>
        <td class="num">${_esc(money(row.party.creditLimit))}</td>
        <td class="num">${_esc(money(row.over))}</td>
      </tr>''';
  }).join();
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Limit aşan cariler</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; font-weight: 700; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Limit aşan cariler · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Bakiyesi kredi limitini geçen müşteriler. Açık sipariş bu listeye girmez.</div>
  <table>
    <thead><tr><th>Cari</th><th class="num">Bakiye</th><th class="num">Limit</th><th class="num">Aşım</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p class="muted">Bu çıktı şirket içi risk listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String payableWeekHtml(AppStore store) {
  final docs = store.duePurchaseWeek();
  final grouped = <String, List<TradeDoc>>{};
  for (final doc in docs) {
    grouped.putIfAbsent(doc.partyId, () => []).add(doc);
  }
  final body = grouped.entries.map((entry) {
    final party = store.partyById(entry.key);
    final phone = party == null || party.phone.trim().isEmpty ? 'Telefon yok' : party.phone.trim();
    final lines = entry.value
        .map((doc) => '${_esc(doc.no)} · kalan ${_esc(money(store.docRemaining(doc)))} · vade ${_esc(shortDate(doc.dueDate))}')
        .join('<br>');
    final remaining = entry.value.fold<double>(0, (sum, doc) => sum + store.docRemaining(doc));
    return '''
      <tr>
        <td>${_esc(party?.name ?? 'Cari yok')}<div class="muted">${_esc(phone)}</div></td>
        <td>$lines</td>
        <td class="num">${_esc(money(remaining))}</td>
      </tr>''';
  }).join();
  final total = docs.fold<double>(0, (sum, doc) => sum + store.docRemaining(doc));
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Bu hafta ödenecek alışlar</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; font-weight: 700; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Bu hafta ödenecek alışlar · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Kalanı olan onaylı alış faturaları. Vadesi bugün veya 7 gün içinde. Geçmiş vadeler bu listede yoktur.</div>
  <table>
    <thead><tr><th>Tedarikçi</th><th>Faturalar</th><th class="num">Kalan</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p><strong>Toplam kalan ${_esc(money(total))}</strong></p>
  <p class="muted">Bu çıktı şirket içi ödeme listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String collectionHtml(AppStore store) {
  final rows = store.collectionSheet();
  final body = rows.map((row) {
    final phone = row.party.phone.trim().isEmpty ? 'Telefon yok' : row.party.phone.trim();
    final docs = row.docs
        .map((doc) => '${_esc(doc.no)} · kalan ${_esc(money(store.docRemaining(doc)))} · vade ${_esc(shortDate(doc.dueDate))}')
        .join('<br>');
    return '''
      <tr>
        <td>${_esc(row.party.name)}<div class="muted">${_esc(row.party.city)} · ${_esc(phone)}</div></td>
        <td>$docs</td>
        <td class="num">${_esc(money(row.remaining))}</td>
      </tr>''';
  }).join();
  final total = rows.fold<double>(0, (sum, row) => sum + row.remaining);
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Tahsilat listesi</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; font-weight: 700; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Tahsilat listesi · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Vadesi dünden önce dolmuş, kapanmamış satış faturaları. Bugün vadesi gelenler bu listede yoktur.</div>
  <table>
    <thead><tr><th>Cari</th><th>Faturalar</th><th class="num">Kalan</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p><strong>Toplam kalan ${_esc(money(total))}</strong></p>
  <p class="muted">Bu çıktı şirket içi tahsilat listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String dueTodayHtml(AppStore store) {
  final rows = store.dueTodaySheet();
  final body = rows.map((row) {
    final phone = row.party.phone.trim().isEmpty ? 'Telefon yok' : row.party.phone.trim();
    final docs = row.docs.map((doc) => '${_esc(doc.no)} · kalan ${_esc(money(store.docRemaining(doc)))}').join('<br>');
    return '''
      <tr>
        <td>${_esc(row.party.name)}<div class="muted">${_esc(row.party.city)} · ${_esc(phone)}</div></td>
        <td>$docs</td>
        <td class="num">${_esc(money(row.remaining))}</td>
      </tr>''';
  }).join();
  final total = rows.fold<double>(0, (sum, row) => sum + row.remaining);
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Bugün vadesi gelenler</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; font-weight: 700; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Bugün vadesi gelenler · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Yalnız vadesi bugün olan açık satışlar. Dünden önce dolanlar bu listede yoktur.</div>
  <table>
    <thead><tr><th>Cari</th><th>Faturalar</th><th class="num">Kalan</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p><strong>Toplam kalan ${_esc(money(total))}</strong></p>
  <p class="muted">Bu çıktı şirket içi tahsilat listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String shippingHtml(AppStore store) {
  final rows = store.openShipments();
  final body = rows.map((doc) {
    final party = store.partyById(doc.partyId);
    final phone = party == null || party.phone.trim().isEmpty ? 'Telefon yok' : party.phone.trim();
    final lines = doc.lines.map((line) => '${_esc(store.productName(line.productId))} · ${_esc(qtyText(line.qty))} adet').join('<br>');
    final address = store.shipmentAddress(doc);
    return '''
      <tr>
        <td>${_esc(doc.no)}<div class="muted">${_esc(docKindLabel(doc.kind))} · ${_esc(shortDate(doc.date))} · ${_esc(deliveryLabel(doc.deliveryStatus))}</div></td>
        <td>${_esc(party?.name ?? 'Cari yok')}<div class="muted">${_esc(phone)}</div></td>
        <td>${_esc(address.isEmpty ? 'Adres yok' : address)}</td>
        <td>$lines</td>
      </tr>''';
  }).join();
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Sevkiyat listesi</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; vertical-align: top; }
  th { color: #64748b; font-weight: 600; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Sevkiyat listesi · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Teslim edilmemiş satış faturaları ve çıkış irsaliyeleri. İrsaliyeden kesilen fatura ikinci kez yazılmaz.</div>
  <table>
    <thead><tr><th>Belge</th><th>Cari</th><th>Adres</th><th>Ürünler</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p class="muted">Bu çıktı şirket içi sevkiyat listesidir. GİB belgesi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String instrumentHtml(AppStore store) {
  final rows = store.upcomingInstruments();
  final body = rows.map((item) {
    final bank = [item.bank, item.branch].where((part) => part.trim().isNotEmpty).join(' ');
    return '''
      <tr>
        <td>${_esc(instrumentKindLabel(item.kind))}</td>
        <td>${_esc(item.no)}</td>
        <td>${_esc(store.partyName(item.partyId))}</td>
        <td>${_esc(bank.isEmpty ? '—' : bank)}</td>
        <td>${_esc(shortDate(item.dueDate))}</td>
        <td>${_esc(instrumentStatusLabel(item))}</td>
        <td class="num">${_esc(money(item.amount))}</td>
      </tr>''';
  }).join();
  final total = rows.fold<double>(0, (sum, item) => sum + item.amount);
  final profile = store.profile;
  return '''
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Çek ve senet listesi</title>
<style>
  body { font-family: "Segoe UI", sans-serif; color: #0f172a; margin: 24px; }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .muted { color: #64748b; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { border-bottom: 1px solid #e2e8f0; padding: 8px 6px; text-align: left; font-size: 13px; }
  th { color: #64748b; font-weight: 600; }
  .num { text-align: right; white-space: nowrap; font-weight: 700; }
</style>
</head>
<body>
  <h1>${_esc(profile.name)}</h1>
  <div class="muted">Çek ve senet · ${_esc(shortDate(DateTime.now()))}</div>
  <div class="muted">Portföyde veya tahsile verilmiş evrak. Vadesi geçmişler ve önümüzdeki 14 gün.</div>
  <table>
    <thead><tr><th>Tür</th><th>No</th><th>Cari</th><th>Banka</th><th>Vade</th><th>Durum</th><th class="num">Tutar</th></tr></thead>
    <tbody>$body</tbody>
  </table>
  <p><strong>Toplam ${_esc(money(total))}</strong></p>
  <p class="muted">Bu çıktı şirket içi evrak listesidir. Banka ekstresi değildir.</p>
  <script>window.addEventListener('load', () => window.print());</script>
</body>
</html>
''';
}

String _esc(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
