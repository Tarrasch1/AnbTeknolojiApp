import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../xlsx_sheet.dart';
import 'cards.dart';
import 'save_file_stub.dart' if (dart.library.html) 'save_file_web.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  int _tab = 0;
  final _search = TextEditingController();
  String _category = 'Tümü';
  String _brand = 'Tümü';
  String _moveParty = '';

  static const _hints = [
    'Kategoriye göre süzülür. Satıra tıklayınca ürün kartı açılır.',
    'Satışta müşteri ve adet yazar. Alışta tedarikçi görünür.',
    'Eksik miktar, minimum stok ile eldeki stok farkıdır. Tedarikçi son alış belgesinden gelir.',
    'Elde durup son 90 günde satılmamış ürünler. Hiç satılmayanlar listenin başındadır.',
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
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Column(
      children: [
        const PageIntro(
          title: 'Ürün ve stok',
          hint: 'Stok kodu, adet ve tutarlar satır satır durur.',
          icon: Icons.inventory_2_outlined,
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: kNavy,
            tabs: const [
              Tab(text: 'Ürünler'),
              Tab(text: 'Hareketler'),
              Tab(text: 'Alış önerisi'),
              Tab(text: 'Yavaş stok'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(_hints[_tab], style: const TextStyle(color: kMuted)),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _products(store),
              _moves(store),
              _reorder(store),
              _slow(store),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reorder(AppStore store) {
    final needs = store.reorderNeeds();
    if (needs.isEmpty) return const EmptyHint('Minimumun altında ürün yok.');
    final groups = <String, List<ReorderNeed>>{};
    for (final need in needs) {
      groups.putIfAbsent(need.supplierId, () => []).add(need);
    }
    final keys = groups.keys.toList()..sort((a, b) => store.partyName(a).compareTo(store.partyName(b)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: groups.keys.every((id) => id.isEmpty)
                ? null
                : () {
                    final nos = store.draftReorderOrders();
                    showMessage(context, nos.isEmpty ? 'Taslak açılamadı' : 'Alış siparişi taslağı: ${nos.join(', ')}');
                  },
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Sipariş taslaklarını oluştur'),
          ),
        ),
        const SizedBox(height: 12),
        for (final key in keys) ...[
          Text(
            key.isEmpty ? 'Son alış yok' : store.partyName(key),
            style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy),
          ),
          const SizedBox(height: 6),
          if (key.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Bu ürünler için onaylı alış bulunamadı. Sipariş taslağına yazılmaz.', style: TextStyle(color: kMuted, fontSize: 12)),
            ),
          for (final need in groups[key]!)
            RecordRow(
              icon: categoryIcon(need.product.category),
              tone: kBad,
              title: need.product.name,
              subtitle: 'Stok ${qtyText(need.onHand)} · min ${qtyText(need.product.minStock)} · eksik ${qtyText(need.shortQty)}'
                  '${need.lastCost > 0 ? ' · son alış ${money(need.lastCost)}' : ''}',
              trailing: qtyText(need.shortQty),
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: need.product.id))),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _slow(AppStore store) {
    final items = store.slowProducts();
    if (items.isEmpty) return const EmptyHint('Son 90 günde satılmamış, elde duran ürün yok.');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in items)
          RecordRow(
            icon: categoryIcon(item.product.category),
            tone: kWarn,
            title: item.product.name,
            subtitle: item.lastSale == null
                ? 'Hiç satılmadı · elde ${qtyText(item.onHand)}'
                : 'Son satış ${shortDate(item.lastSale!)} · elde ${qtyText(item.onHand)}',
            trailing: qtyText(item.onHand),
            trailingColor: kWarn,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: item.product.id))),
          ),
      ],
    );
  }

  Widget _products(AppStore store) {
    final query = _search.text.trim().toLowerCase();
    final brands = store.products
        .where((product) => _category == 'Tümü' || product.category == _category)
        .map((product) => product.brand)
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final brand = brands.contains(_brand) ? _brand : 'Tümü';
    final items = store.products.where((product) {
      if (_category != 'Tümü' && product.category != _category) return false;
      if (brand != 'Tümü' && product.brand != brand) return false;
      if (query.isEmpty) return true;
      final blob = '${product.name} ${product.sku} ${product.barcode} ${product.brand}'.toLowerCase();
      return blob.contains(query);
    }).toList()
      ..sort((a, b) => a.sku.compareTo(b.sku));
    var qtySum = 0.0;
    var costSum = 0.0;
    var saleSum = 0.0;
    for (final product in items) {
      final qty = store.stockOf(product.id);
      qtySum += qty;
      costSum += product.purchasePrice * qty;
      saleSum += product.salePrice * qty;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Ad, marka, barkod, stok kodu'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Excel',
                onPressed: items.isEmpty ? null : () => _exportStock(context, store, items),
                icon: const Icon(Icons.grid_on_outlined),
              ),
              OutlinedButton.icon(
                onPressed: () => _bulkPrice(context, store),
                icon: const Icon(Icons.sell_outlined),
                label: const Text('Fiyat'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _editProduct(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Ürün'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: ['Tümü', ...applianceCategories].map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(item),
                  selected: _category == item,
                  onSelected: (_) => setState(() => _category = item),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            children: ['Tümü', ...brands].map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(item == 'Tümü' ? 'Tüm markalar' : item),
                  selected: brand == item,
                  onSelected: (_) => setState(() => _brand = item),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Bu filtrede ürün yok.')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: width,
                          child: Column(
                            children: [
                              const _StockHead(),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: kLine),
                                  itemBuilder: (context, index) {
                                    final product = items[index];
                                    final qty = store.stockOf(product.id);
                                    final low = product.minStock > 0 && qty <= product.minStock;
                                    return InkWell(
                                      onTap: () => showGoodsPanel(context, product.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            _StockCell(product.sku.isEmpty ? '—' : product.sku, 120),
                                            Expanded(
                                              child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                                            ),
                                            _StockCell(qtyText(qty), 80, align: TextAlign.right, color: low ? kBad : kInk),
                                            _StockCell(money(product.purchasePrice), 120, align: TextAlign.right),
                                            _StockCell(money(product.salePrice), 130, align: TextAlign.right),
                                            _StockCell(money(product.purchasePrice * qty), 130, align: TextAlign.right),
                                            _StockCell(money(product.salePrice * qty), 140, align: TextAlign.right),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _StockFoot(qty: qtySum, cost: costSum, sale: saleSum),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _moves(AppStore store) {
    final partyIds = <String>{};
    for (final move in store.moves) {
      final partyId = _partyOf(store, move);
      if (partyId != null) partyIds.add(partyId);
    }
    final parties = partyIds.map(store.partyById).whereType<Party>().toList()..sort((a, b) => a.name.compareTo(b.name));
    final selected = parties.any((party) => party.id == _moveParty) ? _moveParty : '';
    final items = store.moves.where((move) => selected.isEmpty || _partyOf(store, move) == selected).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Müşteri / tedarikçi'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tüm cariler')),
              ...parties.map((party) => DropdownMenuItem(value: party.id, child: Text(party.name, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (value) => setState(() => _moveParty = value ?? ''),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Bu filtrede stok hareketi yok.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final move = items[index];
                    final inbound = move.qty >= 0;
                    return RecordRow(
                      icon: inbound ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      tone: inbound ? kGood : kBad,
                      title: store.productName(move.productId),
                      subtitle: '${_moveStory(store, move)} · ${shortDate(move.date)}',
                      trailing: '${inbound ? '+' : ''}${qtyText(move.qty)}',
                    );
                  },
                ),
        ),
      ],
    );
  }

  String? _partyOf(AppStore store, StockMove move) {
    final doc = move.docId.isEmpty ? null : store.docById(move.docId);
    if (doc == null || doc.partyId.isEmpty) return null;
    return doc.partyId;
  }

  String _moveStory(AppStore store, StockMove move) {
    final doc = move.docId.isEmpty ? null : store.docById(move.docId);
    if (doc != null && doc.partyId.isNotEmpty) {
      final qty = qtyText(move.qty.abs());
      final action = switch (doc.kind) {
        DocKind.sale || DocKind.saleWaybill => 'satıldı',
        DocKind.saleReturn => 'müşteriden iade',
        DocKind.purchase || DocKind.purchaseWaybill => 'alındı',
        DocKind.purchaseReturn => 'tedarikçiye iade',
        _ => 'işlendi',
      };
      return '${store.partyName(doc.partyId)} · $qty adet $action · ${doc.no}';
    }
    return '${store.warehouseName(move.warehouseId)} · ${move.note}';
  }

}

Future<void> showGoodsPanel(BuildContext context, String productId) {
  final host = context;
  return showPanel(
    context: context,
    builder: (context) {
      final store = StoreScope.of(context);
      final product = store.productById(productId);
      if (product == null) return const SizedBox.shrink();
      final qty = store.stockOf(product.id);
      final reserved = store.reservedOf(product.id);
      final low = qty <= product.minStock;
      return PanelFrame(
        title: product.name,
        subtitle: '${product.brand} · ${product.sku}',
        headerColor: low ? kBad : kNavy,
        mark: MarkBadge(label: '', color: const Color(0xFF0B1C33), icon: categoryIcon(product.category), size: 54),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MiniStat(icon: Icons.inventory_2_outlined, label: 'Stok', value: '${qtyText(qty)} adet', tone: low ? kBad : kGood),
                if (reserved > 0.0001) ...[
                  const SizedBox(width: 8),
                  MiniStat(icon: Icons.lock_outline, label: 'Satılabilir', value: qtyText(qty - reserved), tone: kWarn),
                ],
                const SizedBox(width: 8),
                MiniStat(icon: Icons.sell_outlined, label: 'Satış', value: money(product.salePrice), tone: kCopper),
                const SizedBox(width: 8),
                MiniStat(icon: Icons.verified_outlined, label: 'Garanti', value: '${product.warrantyMonths} ay'),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusChip(product.category),
                StatusChip('Enerji ${product.energyClass}'),
                if (product.needsInstall) const StatusChip('Montajlı', color: kWarn),
                if (product.trackSerial) const StatusChip('Seri takipli'),
                if (low) const StatusChip('Kritik stok', color: kBad),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Depolar', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 8),
            ...store.warehouses.map((warehouse) {
              final warehouseQty = store.stockOf(product.id, warehouseId: warehouse.id);
              final cap = product.minStock <= 0 ? 10.0 : product.minStock * 3;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(warehouse.name, overflow: TextOverflow.ellipsis)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (warehouseQty / cap).clamp(0, 1).toDouble(),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF0EBE3),
                          color: warehouseQty <= 0 ? kBad : kNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(qtyText(warehouseQty), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Text('Alış ${money(product.purchasePrice)} · KDV %${qtyText(product.vatRate)} · raf ${product.shelf.isEmpty ? '—' : product.shelf}'),
          ],
        ),
        footer: Row(
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(host, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id)));
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ürün kartı'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _manual(host, product, inbound: true);
              },
              child: const Text('Stok girişi'),
            ),
          ],
        ),
      );
    },
  );
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final product = store.productById(productId);
    if (product == null) {
      return const Scaffold(body: EmptyHint('Ürün bulunamadı'));
    }
    final serials = store.serials.where((item) => item.productId == product.id).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(product.sku),
        actions: [
          IconButton(onPressed: () => _editProduct(context, product), icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageIntro(
            inset: false,
            title: product.name,
            hint: '${product.brand} · ${product.category}. Eldeki ${qtyText(store.stockOf(product.id))} adet, minimum ${qtyText(product.minStock)}.',
            icon: categoryIcon(product.category),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(product.brand),
              StatusChip(product.category),
              StatusChip(product.active ? 'Aktif' : 'Pasif', color: product.active ? kGood : kBad),
              if (product.needsInstall) const StatusChip('Montajlı', color: kWarn),
              if (product.trackSerial) const StatusChip('Seri takipli'),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  InfoLine('Barkod', product.barcode.isEmpty ? '—' : product.barcode),
                  InfoLine('Enerji', product.energyClass),
                  InfoLine('Garanti', '${product.warrantyMonths} ay'),
                  InfoLine('Güç', product.watt == 0 ? '—' : '${product.watt} W'),
                  InfoLine('Renk / menşei', '${product.color} · ${product.origin}'),
                  InfoLine('Desi', qtyText(product.desi)),
                  InfoLine('Raf', product.shelf.isEmpty ? '—' : product.shelf),
                  InfoLine('Alış', money(product.purchasePrice)),
                  InfoLine('Satış', money(product.salePrice)),
                  InfoLine('KDV', '%${qtyText(product.vatRate)}'),
                  InfoLine('Min. stok', qtyText(product.minStock)),
                  if (product.note.isNotEmpty) InfoLine('Not', product.note),
                ],
              ),
            ),
          ),
          const SectionTitle('Fiyat geçmişi'),
          const Text('Alış veya satış fiyatı değişince eski ve yeni tutar burada kalır.', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          if (store.priceHistory(product.id).isEmpty)
            const EmptyHint('Fiyat değişikliği yok.')
          else
            for (final change in store.priceHistory(product.id))
              Card(
                child: ListTile(
                  title: Text(shortDate(change.date), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    'Alış ${money(change.oldPurchase)} → ${money(change.newPurchase)}\nSatış ${money(change.oldSale)} → ${money(change.newSale)}',
                  ),
                ),
              ),
          const SectionTitle('Tedarikçi alış fiyatları'),
          const Text('Onaylı alış faturası ve alış irsaliyesindeki son birim fiyat. Aynı tedarikçinin eski fiyatı yerini sonuncuya bırakır.', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          if (store.supplierPrices(product.id).isEmpty)
            const EmptyHint('Bu ürünün onaylı alışı yok.')
          else
            for (final row in store.supplierPrices(product.id))
              Card(
                child: ListTile(
                  title: Text(row.party.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${row.docNo} · ${shortDate(row.date)}'),
                  trailing: Text(money(row.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          const SectionTitle('Son satış fiyatları'),
          const Text('Onaylı satış faturası ve çıkış irsaliyesindeki son birim fiyat. Aynı müşterinin eski fiyatı yerini sonuncuya bırakır.', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          if (store.customerPrices(product.id).isEmpty)
            const EmptyHint('Bu ürünün onaylı satışı yok.')
          else
            for (final row in store.customerPrices(product.id))
              Card(
                child: ListTile(
                  title: Text(row.party.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${row.docNo} · ${shortDate(row.date)}'),
                  trailing: Text(money(row.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          const SectionTitle('Depo bazında stok'),
          ...store.warehouses.map((warehouse) {
            return Card(
              child: ListTile(
                title: Text(warehouse.name),
                trailing: Text(qtyText(store.stockOf(product.id, warehouseId: warehouse.id)), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            );
          }),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _manual(context, product, inbound: true),
                icon: const Icon(Icons.add),
                label: const Text('Stok girişi'),
              ),
              OutlinedButton.icon(
                onPressed: () => _manual(context, product, inbound: false),
                icon: const Icon(Icons.remove),
                label: const Text('Stok çıkışı'),
              ),
            ],
          ),
          const SectionTitle('Seri numaraları'),
          if (serials.isEmpty) const EmptyHint('Bu ürüne bağlı seri yok.') else ...serials.map((item) => Card(child: ListTile(title: Text(item.serial), subtitle: Text(serialStatusLabel(item.status))))),
        ],
      ),
    );
  }
}

Future<void> _bulkPrice(BuildContext context, AppStore store) async {
  final brands = store.products.map((item) => item.brand).where((item) => item.isNotEmpty).toSet().toList()..sort();
  final percent = TextEditingController(text: '10');
  var brand = '';
  var category = '';
  var up = true;
  var sale = true;
  var purchase = false;
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Toplu fiyat'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Seçilen marka veya kategorideki fiyatlar yüzde kadar değişir.', style: TextStyle(color: kMuted, height: 1.35)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: brand,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Marka'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm markalar')),
                ...brands.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (value) => setLocal(() => brand = value ?? ''),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm kategoriler')),
                ...applianceCategories.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (value) => setLocal(() => category = value ?? ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: percent,
              decoration: const InputDecoration(labelText: 'Yüzde'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Zam'), selected: up, onSelected: (_) => setLocal(() => up = true)),
                ChoiceChip(label: const Text('İndirim'), selected: !up, onSelected: (_) => setLocal(() => up = false)),
              ],
            ),
            CheckboxListTile(value: sale, onChanged: (value) => setLocal(() => sale = value ?? true), title: const Text('Satış fiyatı'), contentPadding: EdgeInsets.zero),
            CheckboxListTile(value: purchase, onChanged: (value) => setLocal(() => purchase = value ?? false), title: const Text('Alış fiyatı'), contentPadding: EdgeInsets.zero),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Uygula')),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) {
    final rate = parseNum(percent.text) ?? 0;
    final result = store.adjustPrices(
      brand: brand,
      category: category,
      percent: up ? rate : -rate,
      sale: sale,
      purchase: purchase,
    );
    showMessage(context, result.error ?? '${result.count} ürünün fiyatı güncellendi');
  }
  percent.dispose();
}

Future<void> _editProduct(BuildContext context, Product? existing) async {
  final store = StoreScope.of(context);
  final sku = TextEditingController(text: existing?.sku ?? '');
  final barcode = TextEditingController(text: existing?.barcode ?? '');
  final name = TextEditingController(text: existing?.name ?? '');
  final brand = TextEditingController(text: existing?.brand ?? applianceBrands.first);
  final energy = TextEditingController(text: existing?.energyClass ?? 'A');
  final warranty = TextEditingController(text: '${existing?.warrantyMonths ?? 24}');
  final watt = TextEditingController(text: '${existing?.watt ?? 0}');
  final color = TextEditingController(text: existing?.color ?? '');
  final origin = TextEditingController(text: existing?.origin ?? 'Türkiye');
  final desi = TextEditingController(text: numField(existing?.desi ?? 0));
  final vat = TextEditingController(text: numField(existing?.vatRate ?? store.profile.defaultVat));
  final buy = TextEditingController(text: numField(existing?.purchasePrice ?? 0));
  final sell = TextEditingController(text: numField(existing?.salePrice ?? 0));
  final minStock = TextEditingController(text: numField(existing?.minStock ?? 0));
  final shelf = TextEditingController(text: existing?.shelf ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  var category = existing?.category ?? applianceCategories.first;
  var warehouseId = existing?.warehouseId ?? (store.warehouses.isEmpty ? '' : store.warehouses.first.id);
  var install = existing?.needsInstall ?? false;
  var track = existing?.trackSerial ?? true;
  var active = existing?.active ?? true;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        return FormDialog(
          title: existing == null ? 'Yeni ürün' : 'Ürünü düzenle',
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  final message = store.removeProduct(existing.id);
                  if (context.mounted) {
                    showMessage(context, message ?? 'Ürün silindi');
                    Navigator.pop(context, false);
                  }
                },
                child: const Text('Sil / pasif'),
              ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
          ],
          child: Column(
            children: [
              FormSection(
                step: '1',
                title: 'Kimlik',
                hint: 'Fatura satırında görünen ad, kod ve kategori.',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Ürün adı')),
                    const SizedBox(height: 10),
                    FieldGrid(
                      children: [
                        TextField(controller: sku, decoration: const InputDecoration(labelText: 'Stok kodu')),
                        TextField(controller: barcode, decoration: const InputDecoration(labelText: 'Barkod')),
                        TextField(controller: brand, decoration: const InputDecoration(labelText: 'Marka')),
                        DropdownButtonFormField<String>(
                          value: category,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Kategori'),
                          items: applianceCategories.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setLocal(() => category = value ?? category),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FormSection(
                step: '2',
                title: 'Fiyat',
                hint: 'Tutarlar KDV hariç. Faturada KDV ayrıca eklenir.',
                icon: Icons.sell_outlined,
                child: FieldGrid(
                  children: [
                    TextField(controller: buy, decoration: const InputDecoration(labelText: 'Alış'), keyboardType: TextInputType.number),
                    TextField(controller: sell, decoration: const InputDecoration(labelText: 'Satış'), keyboardType: TextInputType.number),
                    TextField(controller: vat, decoration: const InputDecoration(labelText: 'KDV %'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              FormSection(
                step: '3',
                title: 'Stok',
                hint: 'Minimumun altına düşünce ürün kritik listesine düşer.',
                icon: Icons.warehouse_outlined,
                child: Column(
                  children: [
                    FieldGrid(
                      children: [
                        TextField(controller: minStock, decoration: const InputDecoration(labelText: 'Min. stok'), keyboardType: TextInputType.number),
                        TextField(controller: shelf, decoration: const InputDecoration(labelText: 'Raf')),
                        DropdownButtonFormField<String>(
                          value: warehouseId.isEmpty ? null : warehouseId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Varsayılan depo'),
                          items: store.warehouses.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setLocal(() => warehouseId = value ?? warehouseId),
                        ),
                      ],
                    ),
                    CheckboxListTile(value: track, onChanged: (value) => setLocal(() => track = value ?? false), title: const Text('Seri no takip edilsin'), contentPadding: EdgeInsets.zero),
                    CheckboxListTile(value: active, onChanged: (value) => setLocal(() => active = value ?? true), title: const Text('Satışa açık'), contentPadding: EdgeInsets.zero),
                  ],
                ),
              ),
              FormSection(
                step: '4',
                title: 'Teknik bilgi',
                hint: 'Garanti süresi satıştan sonra bu aya göre başlar.',
                icon: Icons.tune_outlined,
                child: Column(
                  children: [
                    FieldGrid(
                      children: [
                        DropdownButtonFormField<String>(
                          value: energyClasses.contains(energy.text) ? energy.text : 'A',
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Enerji sınıfı'),
                          items: energyClasses.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                          onChanged: (value) => setLocal(() => energy.text = value ?? 'A'),
                        ),
                        TextField(controller: warranty, decoration: const InputDecoration(labelText: 'Garanti (ay)'), keyboardType: TextInputType.number),
                        TextField(controller: watt, decoration: const InputDecoration(labelText: 'Watt'), keyboardType: TextInputType.number),
                        TextField(controller: color, decoration: const InputDecoration(labelText: 'Renk')),
                        TextField(controller: origin, decoration: const InputDecoration(labelText: 'Menşei')),
                        TextField(controller: desi, decoration: const InputDecoration(labelText: 'Desi'), keyboardType: TextInputType.number),
                      ],
                    ),
                    CheckboxListTile(value: install, onChanged: (value) => setLocal(() => install = value ?? false), title: const Text('Montaj gerektirir'), contentPadding: EdgeInsets.zero),
                    TextField(controller: note, decoration: const InputDecoration(labelText: 'Not'), maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  if (saved == true && context.mounted) {
    if (name.text.trim().isEmpty) {
      showMessage(context, 'Ürün adı gerekli');
    } else {
      store.upsertProduct(
        Product(
          id: existing?.id ?? '',
          sku: sku.text.trim(),
          barcode: barcode.text.trim(),
          name: name.text.trim(),
          brand: brand.text.trim(),
          category: category,
          energyClass: energy.text.trim().isEmpty ? 'A' : energy.text.trim(),
          warrantyMonths: int.tryParse(warranty.text) ?? 24,
          watt: int.tryParse(watt.text) ?? 0,
          color: color.text.trim(),
          origin: origin.text.trim(),
          desi: parseNum(desi.text) ?? 0,
          needsInstall: install,
          trackSerial: track,
          vatRate: parseNum(vat.text) ?? 20,
          purchasePrice: parseNum(buy.text) ?? 0,
          salePrice: parseNum(sell.text) ?? 0,
          minStock: parseNum(minStock.text) ?? 0,
          shelf: shelf.text.trim(),
          warehouseId: warehouseId,
          active: active,
          note: note.text.trim(),
        ),
      );
    }
  }
  sku.dispose();
  barcode.dispose();
  name.dispose();
  brand.dispose();
  energy.dispose();
  warranty.dispose();
  watt.dispose();
  color.dispose();
  origin.dispose();
  desi.dispose();
  vat.dispose();
  buy.dispose();
  sell.dispose();
  minStock.dispose();
  shelf.dispose();
  note.dispose();
}

Future<void> _manual(BuildContext context, Product product, {required bool inbound}) async {
  final store = StoreScope.of(context);
  final qty = TextEditingController(text: '1');
  final cost = TextEditingController(text: numField(inbound ? product.purchasePrice : product.salePrice));
  final note = TextEditingController();
  final serials = TextEditingController();
  var warehouseId = product.warehouseId.isEmpty ? store.warehouses.first.id : product.warehouseId;
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(inbound ? 'Stok girişi' : 'Stok çıkışı'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: warehouseId,
                decoration: const InputDecoration(labelText: 'Depo'),
                items: store.warehouses.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: (value) => setLocal(() => warehouseId = value ?? warehouseId),
              ),
              const SizedBox(height: 8),
              TextField(controller: qty, decoration: const InputDecoration(labelText: 'Miktar'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: cost, decoration: const InputDecoration(labelText: 'Birim maliyet'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: serials, decoration: const InputDecoration(labelText: 'Seri nolar (satır satır)'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Not')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) {
    final amount = parseNum(qty.text) ?? 0;
    final message = store.manualMove(
      productId: product.id,
      warehouseId: warehouseId,
      qty: inbound ? amount : -amount,
      unitCost: parseNum(cost.text) ?? 0,
      note: note.text.trim(),
      serialCodes: serials.text.split('\n'),
    );
    showMessage(context, message ?? 'Stok hareketi kaydedildi');
  }
  qty.dispose();
  cost.dispose();
  note.dispose();
  serials.dispose();
}

Future<void> _exportStock(BuildContext context, AppStore store, List<Product> items) async {
  final table = SheetTable(
    const ['Stok kodu', 'Ürün adı', 'Stok adedi', 'Birim maliyeti', 'Birim satış fiyatı', 'Toplam maliyet', 'Toplam satış bedeli'],
    [
      for (final product in items)
        [
          product.sku,
          product.name,
          sheetNum(store.stockOf(product.id)),
          sheetNum(product.purchasePrice),
          sheetNum(product.salePrice),
          sheetNum(round2(product.purchasePrice * store.stockOf(product.id))),
          sheetNum(round2(product.salePrice * store.stockOf(product.id))),
        ],
    ],
  );
  await saveBytes(encodeXlsx(table), 'stok-listesi.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  if (!context.mounted) return;
  showMessage(context, 'Stok listesi Excel olarak indirildi');
}

class _StockHead extends StatelessWidget {
  const _StockHead();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF8FAFC),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _StockCell('Stok kodu', 120, head: true),
            Expanded(child: Text('Ürün adı', style: TextStyle(fontWeight: FontWeight.w700, color: kMuted, fontSize: 12))),
            _StockCell('Stok adedi', 80, head: true, align: TextAlign.right),
            _StockCell('Birim maliyeti', 120, head: true, align: TextAlign.right),
            _StockCell('Birim satış fiyatı', 130, head: true, align: TextAlign.right),
            _StockCell('Toplam maliyet', 130, head: true, align: TextAlign.right),
            _StockCell('Toplam satış bedeli', 140, head: true, align: TextAlign.right),
          ],
        ),
      ),
    );
  }
}

class _StockFoot extends StatelessWidget {
  const _StockFoot({required this.qty, required this.cost, required this.sale});

  final double qty;
  final double cost;
  final double sale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8F1FB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const _StockCell('Dip toplam', 120, head: true),
            const Expanded(child: SizedBox.shrink()),
            _StockCell(qtyText(qty), 80, align: TextAlign.right, color: kNavy),
            const _StockCell('', 120),
            const _StockCell('', 130),
            _StockCell(money(cost), 130, align: TextAlign.right, color: kNavy),
            _StockCell(money(sale), 140, align: TextAlign.right, color: kNavy),
          ],
        ),
      ),
    );
  }
}

class _StockCell extends StatelessWidget {
  const _StockCell(this.text, this.width, {this.head = false, this.align = TextAlign.left, this.color});

  final String text;
  final double width;
  final bool head;
  final TextAlign align;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: head ? FontWeight.w700 : FontWeight.w600,
          color: color ?? (head ? kMuted : kInk),
          fontSize: head ? 12 : 13,
        ),
      ),
    );
  }
}
