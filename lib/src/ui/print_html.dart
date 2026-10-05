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

String _esc(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
