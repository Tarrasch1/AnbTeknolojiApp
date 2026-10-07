import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import 'cards.dart';
import 'finance_page.dart';
import 'scope.dart';
import 'stock_page.dart';
import 'print_page.dart';
import 'theme.dart';
import 'widgets.dart';

class DocsPage extends StatefulWidget {
  const DocsPage({super.key});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);
  int _tab = 0;
  static const _hints = [
    'Satış faturası müşteriyi borçlandırır ve stoktan düşer.',
    'Alış faturası stoğu artırır ve bizi tedarikçiye borçlandırır.',
    'Teklif stok ve cariyi değiştirmez. Onaydan sonra siparişe veya faturaya döner.',
    'Sipariş stok ve cariyi değiştirmez. Faturalanınca etkisi başlar.',
    'İrsaliye stoğu değiştirir, cariyi değiştirmez. Fatura ayrıca kesilir.',
    'İade, bağlı satış veya alışın tersini yapar.',
  ];

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.index != _tab && mounted) setState(() => _tab = _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageIntro(
          title: 'Belgeler',
          hint: 'Fatura cariyi ve stoğu etkiler. Sipariş ve irsaliye farklı iş yapar; açıklama sekmeyle değişir.',
          icon: Icons.receipt_long_outlined,
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: kNavy,
            tabs: const [
              Tab(text: 'Satış'),
              Tab(text: 'Alış'),
              Tab(text: 'Teklif'),
              Tab(text: 'Sipariş'),
              Tab(text: 'İrsaliye'),
              Tab(text: 'İade'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(alignment: Alignment.centerLeft, child: Text(_hints[_tab], style: const TextStyle(color: kMuted))),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _DocList(kinds: [DocKind.sale], create: DocKind.sale),
              _DocList(kinds: [DocKind.purchase], create: DocKind.purchase),
              _DocList(kinds: [DocKind.saleQuote], create: DocKind.saleQuote),
              _DocList(kinds: [DocKind.saleOrder, DocKind.purchaseOrder], create: DocKind.saleOrder, altCreate: DocKind.purchaseOrder),
              _DocList(kinds: [DocKind.saleWaybill, DocKind.purchaseWaybill], create: DocKind.saleWaybill, altCreate: DocKind.purchaseWaybill),
              _DocList(kinds: [DocKind.saleReturn, DocKind.purchaseReturn], create: DocKind.saleReturn, altCreate: DocKind.purchaseReturn),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocList extends StatefulWidget {
  const _DocList({required this.kinds, required this.create, this.altCreate});

  final List<DocKind> kinds;
  final DocKind create;
  final DocKind? altCreate;

  @override
  State<_DocList> createState() => _DocListState();
}

class _DocListState extends State<_DocList> {
  final _search = TextEditingController();
  DocStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final items = store.docs.where((doc) {
      if (!widget.kinds.contains(doc.kind)) return false;
      if (_status != null && doc.status != _status) return false;
      if (query.isEmpty) return true;
      return store.docMatchesQuery(doc, query);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Belge no, cari, not veya ürün'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.altCreate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: widget.altCreate!))),
                        child: Text(docKindShort(widget.altCreate!)),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: widget.create))),
                    icon: const Icon(Icons.add),
                    label: Text(docKindShort(widget.create)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final item in const [null, DocStatus.draft, DocStatus.approved, DocStatus.invoiced, DocStatus.cancelled])
                      ChoiceChip(
                        label: Text(item == null ? 'Tümü' : docStatusLabel(item)),
                        selected: _status == item,
                        onSelected: (_) => setState(() => _status = item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.kinds.contains(DocKind.saleWaybill))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              store.openWaybills().isEmpty
                  ? 'Faturalanmamış irsaliye yok.'
                  : '${store.openWaybills().length} irsaliyenin faturası henüz kesilmedi. Onaylı olanlar aşağıda “Faturası kesilmedi” diye durur.',
              style: const TextStyle(color: kMuted, height: 1.35),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Belge yok.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final remaining = store.docRemaining(doc);
                    final openWaybill = doc.status == DocStatus.approved &&
                        (doc.kind == DocKind.saleWaybill || doc.kind == DocKind.purchaseWaybill);
                    return DocCard(
                      kind: doc.kind,
                      no: doc.no,
                      party: store.partyName(doc.partyId),
                      meta: '${shortDate(doc.date)} · vade ${shortDate(doc.dueDate)}',
                      amount: money(doc.gross),
                      status: docStatusText(doc.status, doc.kind),
                      statusTone: statusColor(doc.status),
                      extra: openWaybill
                          ? 'Faturası kesilmedi'
                          : doc.promiseDate != null
                              ? 'Söz ${shortDate(doc.promiseDate!)}'
                              : remaining > 0.01
                                  ? 'Kalan ${money(remaining)}'
                                  : null,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

bool _sellsToParty(DocKind kind) {
  return kind == DocKind.sale || kind == DocKind.saleOrder || kind == DocKind.saleWaybill || kind == DocKind.saleQuote;
}

String _approveNote(AppStore store, TradeDoc doc) {
  final notes = [...store.marginWarnings(doc), ...store.limitWarnings(doc)];
  if (notes.isEmpty) return 'Onaylandı';
  return 'Onaylandı. ${notes.join(' | ')}';
}

String _docHint(DocKind kind) {
  switch (kind) {
    case DocKind.sale:
      return 'Onaylanınca stok düşer ve müşteri borçlanır.';
    case DocKind.purchase:
      return 'Onaylanınca stok artar ve tedarikçi alacaklanır.';
    case DocKind.saleReturn:
      return 'Satılan mal geri gelir, müşteri borcu azalır.';
    case DocKind.purchaseReturn:
      return 'Mal tedarikçiye döner, bizim borcumuz azalır.';
    case DocKind.saleOrder:
    case DocKind.purchaseOrder:
      return 'Sipariş henüz stok ve cariyi etkilemez.';
    case DocKind.saleWaybill:
    case DocKind.purchaseWaybill:
      return 'İrsaliye stoğu değiştirir. Cari, fatura kesilince işler.';
    case DocKind.saleQuote:
      return 'Teklif stok ve cariyi değiştirmez. Onaydan sonra siparişe veya faturaya döner.';
  }
}

class DocDetailPage extends StatelessWidget {
  const DocDetailPage({required this.docId, super.key});

  final String docId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final doc = store.docById(docId);
    if (doc == null) return const Scaffold(body: EmptyHint('Belge bulunamadı'));
    final remaining = store.docRemaining(doc);
    final canInvoice = doc.status == DocStatus.approved &&
        (doc.kind == DocKind.saleOrder ||
            doc.kind == DocKind.purchaseOrder ||
            doc.kind == DocKind.saleWaybill ||
            doc.kind == DocKind.purchaseWaybill ||
            doc.kind == DocKind.saleQuote);
    final canOrderFromQuote = doc.kind == DocKind.saleQuote && doc.status == DocStatus.approved;
    final party = store.partyById(doc.partyId);
    final tone = docKindTone(doc.kind);
    final paid = store.docPaid(doc);
    final collects = store.closingDirection(doc.kind) == PayDirection.inbound;
    return Scaffold(
      appBar: AppBar(title: Text('${doc.no} · ${docKindShort(doc.kind)}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HoverCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MarkBadge(label: '', color: tone, icon: docKindIcon(doc.kind), size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.no, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy)),
                          Text(docKindLabel(doc.kind), style: const TextStyle(color: kMuted)),
                          const SizedBox(height: 4),
                          Text(party?.name ?? 'Cari yok', style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                          if (party != null && party.city.isNotEmpty)
                            Text(party.city, style: const TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(docStatusText(doc.status, doc.kind), color: statusColor(doc.status)),
                    StatusChip(eDocLabel(doc.eDoc), color: doc.eDoc == EDocStatus.issued ? kGood : kNavy),
                    if (remaining > 0.01) StatusChip('Kalan ${money(remaining)}', color: kWarn),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_docHint(doc.kind), style: const TextStyle(color: kMuted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FactTile(icon: Icons.event_outlined, label: 'Tarih', value: shortDate(doc.date)),
              _FactTile(icon: Icons.flag_outlined, label: 'Vade', value: shortDate(doc.dueDate), tone: remaining > 0.01 ? kWarn : kNavy),
              _FactTile(icon: Icons.warehouse_outlined, label: 'Depo', value: store.warehouseName(doc.warehouseId), tone: kTeal),
              if (kindAffectsCari(doc.kind) && doc.status == DocStatus.approved)
                _FactTile(
                  icon: collects ? Icons.south_west : Icons.north_east,
                  label: collects ? 'Tahsil edilen' : 'Ödenen',
                  value: money(paid),
                  tone: remaining <= 0.01 ? kGood : kWarn,
                ),
            ],
          ),
          if (doc.shipAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            HoverCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_shipping_outlined, color: kInfo, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Sevkiyat: ${doc.shipAddress}', style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
          ],
          if (doc.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            HoverCard(
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, color: kNavy, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(doc.note, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
          ],
          const SectionTitle('Kalemler'),
          const Text('Satırın üzerine gelince kart öne çıkar. Ürüne tıklayınca kartı açılır.', style: TextStyle(color: kMuted, height: 1.35)),
          const SizedBox(height: 8),
          for (final line in doc.lines) _LineCard(line: line, product: store.productById(line.productId)),
          const SectionTitle('Toplam'),
          HoverCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InfoLine('Ara toplam', money(doc.net)),
                InfoLine('KDV', money(doc.vatTotal)),
                InfoLine('Nakliye', money(doc.shipping)),
                if (kindAffectsCari(doc.kind) && doc.status == DocStatus.approved) ...[
                  InfoLine(collects ? 'Tahsil edilen' : 'Ödenen', money(paid)),
                  InfoLine('Kalan', money(remaining)),
                ],
                const Divider(height: 22),
                Row(
                  children: [
                    const Expanded(child: Text('Genel toplam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kInk))),
                    Text(money(doc.gross), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: tone)),
                  ],
                ),
                if (kindAffectsCari(doc.kind) && doc.status == DocStatus.approved && doc.gross > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (paid / doc.gross).clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: kSoft,
                      color: remaining <= 0.01 ? kGood : kWarn,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      remaining <= 0.01
                          ? (collects ? 'Tahsilat kapandı.' : 'Ödeme kapandı.')
                          : 'Kalan ${money(remaining)}, genel toplamın içinde duruyor.',
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (doc.returnReason.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            HoverCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_return_outlined, color: kWarn, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('İade nedeni: ${doc.returnReason.trim()}', style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
          ],
          if (doc.kind == DocKind.sale || doc.kind == DocKind.saleWaybill || doc.kind == DocKind.purchaseWaybill) ...[
            const SectionTitle('Teslim'),
            const Text('Teslim edildi işaretlenince sevkiyat listesinden düşer.', style: TextStyle(color: kMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in DeliveryStatus.values)
                  ChoiceChip(
                    label: Text(deliveryLabel(status)),
                    selected: doc.deliveryStatus == status,
                    onSelected: (_) => store.setDelivery(doc.id, status),
                  ),
              ],
            ),
          ],
          const SectionTitle('İşlemler'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrintPage(docId: doc.id))),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Yazdır'),
              ),
              if (doc.status != DocStatus.cancelled)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DocEditor(kind: doc.kind, prefill: doc, asCopy: true)),
                  ),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Kopyala'),
                ),
              if (doc.status == DocStatus.approved)
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: doc.kind, draft: doc, revising: true))),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzelt'),
                ),
              if (doc.status == DocStatus.draft) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: doc.kind, draft: doc))),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final message = store.approveDoc(doc.id);
                    showMessage(context, message ?? _approveNote(store, doc));
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Onayla'),
                ),
              ],
              if (canOrderFromQuote)
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DocEditor(kind: DocKind.saleOrder, prefill: doc)),
                  ),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Siparişe çevir'),
                ),
              if (canInvoice)
                FilledButton.icon(
                  onPressed: () {
                    final target = doc.kind == DocKind.purchaseOrder || doc.kind == DocKind.purchaseWaybill
                        ? DocKind.purchase
                        : DocKind.sale;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DocEditor(kind: target, prefill: doc)),
                    );
                  },
                  icon: const Icon(Icons.request_quote_outlined),
                  label: Text(doc.kind == DocKind.saleQuote ? 'Faturaya çevir' : 'Faturalandır'),
                ),
              if (doc.status == DocStatus.approved && kindAffectsCari(doc.kind))
                OutlinedButton.icon(
                  onPressed: () => openPaymentDialog(
                    context,
                    partyId: doc.partyId,
                    docId: doc.id,
                    direction: store.closingDirection(doc.kind),
                  ),
                  icon: Icon(collects ? Icons.south_west : Icons.north_east),
                  label: Text(collects ? 'Tahsilat' : 'Ödeme'),
                ),
              if (doc.status == DocStatus.approved && (doc.kind == DocKind.sale || doc.kind == DocKind.purchase))
                OutlinedButton.icon(
                  onPressed: () {
                    final kind = doc.kind == DocKind.sale ? DocKind.saleReturn : DocKind.purchaseReturn;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: kind, prefill: doc)));
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('İade oluştur'),
                ),
              if (doc.kind == DocKind.sale && (remaining > 0.01 || doc.promiseDate != null))
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await pickDate(context, doc.promiseDate ?? DateTime.now());
                    if (picked == null || !context.mounted) return;
                    showMessage(context, store.setPromise(doc.id, picked) ?? 'Ödeme sözü ${shortDate(picked)}');
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(doc.promiseDate == null ? 'Ödeme sözü' : 'Söz ${shortDate(doc.promiseDate!)}'),
                ),
              if (doc.status != DocStatus.cancelled && doc.status != DocStatus.invoiced)
                TextButton.icon(
                  onPressed: () async {
                    final ok = await confirm(context, 'Belgeyi iptal et', '${doc.no} iptal edilsin mi? Onaylı belgenin stok ve cari etkisi geri alınır.');
                    if (!ok || !context.mounted) return;
                    showMessage(context, store.cancelDoc(doc.id) ?? 'İptal edildi');
                  },
                  icon: const Icon(Icons.block, color: kBad),
                  label: const Text('İptal', style: TextStyle(color: kBad)),
                ),
              PopupMenuButton<EDocStatus>(
                onSelected: (status) => store.setEDoc(doc.id, status),
                itemBuilder: (context) => EDocStatus.values
                    .map((status) => PopupMenuItem(value: status, child: Text(eDocLabel(status))))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.article_outlined, size: 18, color: kNavy),
                      const SizedBox(width: 8),
                      Text(eDocLabel(doc.eDoc), style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'E-belge alanı elle takip içindir; GİB entegrasyonu yoktur. İrsaliyeden kesilen fatura stoğu ikinci kez düşmez.',
            style: TextStyle(color: kMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.icon, required this.label, required this.value, this.tone = kNavy});

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: HoverCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: tone, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: tone)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, required this.product});

  final DocLine line;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final detail = StringBuffer('${qtyText(line.qty)} adet × ${money(line.unitPrice)}');
    if (line.discountRate != 0) detail.write(' · iskonto %${qtyText(line.discountRate)}');
    detail.write(' · KDV %${qtyText(line.vatRate)}');
    if (line.serials.isNotEmpty) detail.write('\nSeri: ${line.serials.join(', ')}');
    if (line.note.isNotEmpty) detail.write('\n${line.note}');
    final item = product;
    return HoverCard(
      onTap: item == null
          ? null
          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: item.id))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(categoryIcon(product?.category ?? ''), color: kNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product?.name ?? 'Ürün', style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                if (product != null) Text('${product!.brand} · ${product!.sku}', style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(detail.toString(), style: const TextStyle(color: kMuted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(money(line.gross), style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
        ],
      ),
    );
  }
}

class _EditorLine extends StatefulWidget {
  const _EditorLine({required this.line, required this.product, required this.onDelete});

  final DocLine line;
  final Product? product;
  final VoidCallback onDelete;

  @override
  State<_EditorLine> createState() => _EditorLineState();
}

class _EditorLineState extends State<_EditorLine> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final product = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hover ? kSoft : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hover ? kNavy : kLine),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(categoryIcon(product?.category ?? ''), color: kNavy, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product?.name ?? 'Ürün', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                  Text(
                    '${qtyText(line.qty)} adet × ${money(line.unitPrice)} · KDV %${qtyText(line.vatRate)}'
                    '${line.discountRate == 0 ? '' : ' · isk %${qtyText(line.discountRate)}'}',
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(money(line.gross), style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
            IconButton(tooltip: 'Satırı sil', onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: kBad)),
          ],
        ),
      ),
    );
  }
}

class DocEditor extends StatefulWidget {
  const DocEditor({required this.kind, this.draft, this.prefill, this.partyId = '', this.asCopy = false, this.revising = false, super.key});

  final DocKind kind;
  final TradeDoc? draft;
  final TradeDoc? prefill;
  final String partyId;
  final bool asCopy;
  final bool revising;

  @override
  State<DocEditor> createState() => _DocEditorState();
}

class _DocEditorState extends State<DocEditor> {
  late String _partyId;
  late String _warehouseId;
  late DateTime _date;
  late DateTime _due;
  late List<DocLine> _lines;
  late final TextEditingController _note;
  late final TextEditingController _reason;
  late final TextEditingController _shipping;
  late final TextEditingController _ship;
  String? _id;
  String _sourceId = '';
  var _delivery = DeliveryStatus.none;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final store = StoreScope.of(context);
    final base = widget.draft ?? widget.prefill;
    _partyId = widget.partyId.isNotEmpty ? widget.partyId : (base?.partyId ?? '');
    _warehouseId = base?.warehouseId ?? (store.warehouses.isEmpty ? '' : store.warehouses.first.id);
    _date = widget.draft?.date ?? DateTime.now();
    final party = store.partyById(_partyId);
    _due = widget.draft?.dueDate ?? _date.add(Duration(days: party?.termDays ?? store.profile.defaultTermDays));
    _lines = base?.lines.map((line) => line.copy()).toList() ?? <DocLine>[];
    _note = TextEditingController(text: widget.draft?.note ?? (widget.prefill == null || widget.asCopy ? '' : '${widget.prefill!.no} kaynaklı'));
    _reason = TextEditingController(text: base?.returnReason ?? '');
    _shipping = TextEditingController(text: numField(base?.shipping ?? 0));
    _ship = TextEditingController(text: base?.shipAddress ?? '');
    _id = widget.asCopy ? null : widget.draft?.id;
    _sourceId = widget.asCopy ? '' : (widget.prefill?.id ?? widget.draft?.sourceDocId ?? '');
    _delivery = widget.asCopy ? DeliveryStatus.none : (base?.deliveryStatus ?? DeliveryStatus.none);
    _ready = true;
  }

  @override
  void dispose() {
    if (_ready) {
      _note.dispose();
      _reason.dispose();
      _shipping.dispose();
      _ship.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final store = StoreScope.of(context);
    final parties = store.parties.where((party) => store.partyFits(party, widget.kind) || party.id == _partyId).toList();
    final party = store.partyById(_partyId);
    final net = _lines.fold(0.0, (sum, line) => sum + line.net);
    final vat = _lines.fold(0.0, (sum, line) => sum + line.vatAmount);
    final shipping = parseNum(_shipping.text) ?? 0;
    final gross = net + vat + shipping;
    final info = FormSection(
      step: '1',
      title: 'Belge bilgileri',
      hint: _docHint(widget.kind),
      icon: docKindIcon(widget.kind),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldGrid(
            minItemWidth: 220,
            children: [
              DropdownButtonFormField<String>(
                value: parties.any((item) => item.id == _partyId) ? _partyId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cari'),
                items: parties.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (value) => setState(() {
                  _partyId = value ?? '';
                  final selected = store.partyById(_partyId);
                  _due = _date.add(Duration(days: selected?.termDays ?? store.profile.defaultTermDays));
                }),
              ),
              DropdownButtonFormField<String>(
                value: _warehouseId.isEmpty ? null : _warehouseId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Depo'),
                items: store.warehouses.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (value) => setState(() => _warehouseId = value ?? ''),
              ),
              DateField(label: 'Tarih', value: _date, onChanged: (value) => setState(() => _date = value)),
              DateField(label: 'Vade', value: _due, onChanged: (value) => setState(() => _due = value)),
              TextField(
                controller: _shipping,
                decoration: const InputDecoration(labelText: 'Nakliye'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          if (party != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: balanceColor(store.partyBalance(party.id)).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${party.city.isEmpty ? 'İl yok' : party.city} · ${balanceText(store.partyBalance(party.id))}',
                style: TextStyle(color: balanceColor(store.partyBalance(party.id)), fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _ship,
            decoration: const InputDecoration(labelText: 'Sevkiyat adresi', hintText: 'Boşsa carinin adresi kullanılır'),
          ),
          const SizedBox(height: 10),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Belge notu')),
          if (widget.kind == DocKind.saleReturn || widget.kind == DocKind.purchaseReturn) ...[
            const SizedBox(height: 10),
            TextField(controller: _reason, decoration: const InputDecoration(labelText: 'İade nedeni')),
          ],
        ],
      ),
    );
    final lines = FormSection(
      step: '2',
      title: 'Kalemler',
      hint: widget.revising ? 'Kayıt onaylı. Kaydedince stok ve cari bu kalemlere göre yeniden işlenir.' : 'Fiyat KDV hariçtir. Taslak stok ve cariyi değiştirmez.',
      icon: Icons.list_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_partyId.isNotEmpty && _sellsToParty(widget.kind)) ...[
            Builder(builder: (context) {
              final frequent = store.frequentProducts(_partyId);
              if (frequent.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bu cariye son satılanlar', style: TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final product in frequent)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: ActionChip(
                              label: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onPressed: () => setState(() {
                                _lines.add(DocLine(
                                  productId: product.id,
                                  qty: 1,
                                  unitPrice: store.suggestPrice(product, party, widget.kind),
                                  vatRate: product.vatRate,
                                  note: product.needsInstall ? 'Montaj' : '',
                                ));
                              }),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
          if (_lines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kLine),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined, color: kMuted),
                  SizedBox(height: 6),
                  Text('Henüz ürün yok', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else
            for (final entry in _lines.asMap().entries)
              _EditorLine(
                line: entry.value,
                product: store.productById(entry.value.productId),
                onDelete: () => setState(() => _lines.removeAt(entry.key)),
              ),
          const SizedBox(height: 4),
          FilledButton.tonalIcon(onPressed: () => _addLine(store), icon: const Icon(Icons.add), label: const Text('Ürün ekle')),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          InfoLine('Ara toplam', money(net)),
          InfoLine('KDV', money(vat)),
          InfoLine('Nakliye', money(shipping)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(child: Text('Genel toplam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Text(money(gross), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: docKindTone(widget.kind))),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.revising)
            FilledButton(onPressed: () => _save(approve: true), child: const Text('Düzeltmeyi kaydet'))
          else
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _save(approve: false), child: const Text('Taslak kaydet'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () => _save(approve: true), child: const Text('Onayla'))),
              ],
            ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(docKindLabel(widget.kind))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, lines],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addLine(AppStore store) async {
    final product = await _pickProduct(context, store);
    if (product == null || !mounted) return;
    final party = store.partyById(_partyId);
    final qty = TextEditingController(text: '1');
    final price = TextEditingController(text: numField(store.suggestPrice(product, party, widget.kind)));
    final discount = TextEditingController(text: '0');
    final vat = TextEditingController(text: numField(product.vatRate));
    final serials = TextEditingController();
    final note = TextEditingController(text: product.needsInstall ? 'Montaj' : '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          final qtyN = parseNum(qty.text) ?? 0;
          final priceN = parseNum(price.text) ?? 0;
          final discountN = parseNum(discount.text) ?? 0;
          final vatN = parseNum(vat.text) ?? 0;
          final lineNet = qtyN * priceN * (1 - discountN / 100);
          final lineGross = lineNet * (1 + vatN / 100);
          return AlertDialog(
            title: Text(product.name),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${product.brand} · stok ${qtyText(store.stockOf(product.id))}', style: const TextStyle(color: kMuted)),
                    if (party != null && store.specialPrice(party.id, product.id) != null)
                      const Text('Bu cariye özel fiyat uygulanır', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700))
                    else if (party != null && store.priceListById(party.priceListId) != null)
                      Text('Fiyat listesi: ${store.priceListById(party.priceListId)!.name}', style: const TextStyle(color: kNavy, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    FieldGrid(
                      minItemWidth: 180,
                      children: [
                        TextField(controller: qty, decoration: const InputDecoration(labelText: 'Miktar'), keyboardType: TextInputType.number, onChanged: (_) => setLocal(() {})),
                        TextField(controller: price, decoration: const InputDecoration(labelText: 'Birim fiyat'), keyboardType: TextInputType.number, onChanged: (_) => setLocal(() {})),
                        TextField(controller: discount, decoration: const InputDecoration(labelText: 'İskonto %'), keyboardType: TextInputType.number, onChanged: (_) => setLocal(() {})),
                        TextField(controller: vat, decoration: const InputDecoration(labelText: 'KDV %'), keyboardType: TextInputType.number, onChanged: (_) => setLocal(() {})),
                      ],
                    ),
                    if (product.trackSerial) ...[
                      const SizedBox(height: 10),
                      TextField(controller: serials, decoration: const InputDecoration(labelText: 'Seri nolar, her satıra bir tane'), maxLines: 3),
                    ],
                    const SizedBox(height: 10),
                    TextField(controller: note, decoration: const InputDecoration(labelText: 'Satır notu')),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(10)),
                      child: Text('Satır toplamı ${money(lineGross)}', style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ekle')),
            ],
          );
        },
      ),
    );
    if (saved == true) {
      final codes = serials.text.split(RegExp(r'[\n,]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
      setState(() {
        _lines.add(
          DocLine(
            productId: product.id,
            qty: parseNum(qty.text) ?? 1,
            unitPrice: parseNum(price.text) ?? 0,
            discountRate: parseNum(discount.text) ?? 0,
            vatRate: parseNum(vat.text) ?? product.vatRate,
            serials: codes,
            note: note.text.trim(),
          ),
        );
      });
      if (product.trackSerial && codes.length != (parseNum(qty.text) ?? 1).round() && mounted) {
        showMessage(context, 'Seri adedi miktardan farklı. Yine de eklendi.');
      }
    }
    qty.dispose();
    price.dispose();
    discount.dispose();
    vat.dispose();
    serials.dispose();
    note.dispose();
  }

  TradeDoc _build() {
    return TradeDoc(
      id: _id ?? '',
      kind: widget.kind,
      status: DocStatus.draft,
      no: widget.draft?.no ?? '',
      date: _date,
      dueDate: _due,
      partyId: _partyId,
      warehouseId: _warehouseId,
      lines: _lines.map((line) => line.copy()).toList(),
      note: _note.text.trim(),
      returnReason: _reason.text.trim(),
      shipping: parseNum(_shipping.text) ?? 0,
      sourceDocId: _sourceId,
      shipAddress: _ship.text.trim(),
      deliveryStatus: _delivery,
    );
  }

  void _save({required bool approve}) {
    final store = StoreScope.of(context);
    final doc = _build();
    if (widget.revising) {
      final error = store.reviseDoc(doc);
      showMessage(context, error ?? 'Belge düzeltildi');
      if (error == null) Navigator.pop(context);
      return;
    }
    final draftError = store.addDraft(doc);
    if (draftError != null) {
      showMessage(context, draftError);
      return;
    }
    _id = doc.id;
    if (!approve) {
      showMessage(context, 'Taslak kaydedildi');
      Navigator.pop(context);
      return;
    }
    final approveError = store.approveDoc(doc.id);
    showMessage(context, approveError ?? _approveNote(store, doc));
    if (approveError == null) Navigator.pop(context);
  }
}

Future<Product?> _pickProduct(BuildContext context, AppStore store) {
  return showDialog<Product>(
    context: context,
    builder: (context) => const _ProductSearch(),
  );
}

class _ProductSearch extends StatefulWidget {
  const _ProductSearch();

  @override
  State<_ProductSearch> createState() => _ProductSearchState();
}

class _ProductSearchState extends State<_ProductSearch> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final key = _query.text.trim().toLowerCase();
    final items = store.products.where((product) {
      if (!product.active) return false;
      if (key.isEmpty) return true;
      return '${product.name} ${product.sku} ${product.barcode} ${product.brand}'.toLowerCase().contains(key);
    }).toList();
    return AlertDialog(
      title: const Text('Ürün seç'),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _query,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Ara'),
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  return RecordRow(
                    icon: categoryIcon(product.category),
                    tone: store.stockOf(product.id) <= product.minStock ? kBad : kNavy,
                    title: product.name,
                    subtitle: '${product.brand} · ${product.sku} · stok ${qtyText(store.stockOf(product.id))}',
                    trailing: money(product.salePrice),
                    onTap: () => Navigator.pop(context, product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

