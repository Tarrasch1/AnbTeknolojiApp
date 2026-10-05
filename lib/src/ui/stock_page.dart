import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import 'cards.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 7, vsync: this);
  int _tab = 0;
  final _search = TextEditingController();
  String _category = 'Tümü';
  String? _countWarehouse;
  final _countFields = <String, TextEditingController>{};

  static const _hints = [
    'Çubuk eldeki stoğu gösterir. Kırmızı, minimumun altıdır.',
    'Yeşil giriş, kırmızı çıkış. Fatura, sayım ve transfer burada toplanır.',
    'Her deponun stoğu ayrıdır. Transfer malı bir depodan diğerine taşır.',
    'Sayılan adedi yazın. Sistemle fark kadar düzeltme fişi oluşur.',
    'Seri no satışta garantiye başlar. Servis ekranından da sorgulanır.',
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
    for (final controller in _countFields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Column(
      children: [
        const PageIntro(
          title: 'Ürün ve stok',
          hint: 'Ne kadar mal var, nerede duruyor, hangisi azalıyor.',
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
              Tab(text: 'Depolar'),
              Tab(text: 'Sayım'),
              Tab(text: 'Seri no'),
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
              _warehouses(store),
              _count(store),
              _serials(store),
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
    final items = store.products.where((product) {
      if (_category != 'Tümü' && product.category != _category) return false;
      if (query.isEmpty) return true;
      final blob = '${product.name} ${product.sku} ${product.barcode} ${product.brand}'.toLowerCase();
      return blob.contains(query);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Bu filtrede ürün yok.')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1100 ? 3 : constraints.maxWidth >= 720 ? 2 : 1;
                    final tileWidth = (constraints.maxWidth - 12 * (cols - 1)) / cols;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: items.map((product) {
                          final qty = store.stockOf(product.id);
                          return SizedBox(
                            width: tileWidth,
                            child: GoodsCard(
                              name: product.name,
                              brand: product.brand,
                              category: product.category,
                              sku: product.sku,
                              price: money(product.salePrice),
                              stock: qty,
                              minStock: product.minStock,
                              reserved: store.reservedOf(product.id),
                              onTap: () => showGoodsPanel(context, product.id),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _moves(AppStore store) {
    final items = [...store.moves]..sort((a, b) => b.date.compareTo(a.date));
    if (items.isEmpty) return const EmptyHint('Stok hareketi yok.');
    return ListView.separated(
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
          subtitle: '${store.warehouseName(move.warehouseId)} · ${shortDate(move.date)} · ${move.note}',
          trailing: '${inbound ? '+' : ''}${qtyText(move.qty)}',
        );
      },
    );
  }

  Widget _warehouses(AppStore store) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _editWarehouse(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Depo'),
          ),
        ),
        const SizedBox(height: 8),
        ...store.warehouses.map((warehouse) {
          return Card(
            child: ListTile(
              title: Text(warehouse.name),
              subtitle: Text('${warehouse.city} · ${warehouse.address}\nStok değeri ${money(store.stockValue(warehouseId: warehouse.id))}'),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Düzenle',
                onPressed: () => _editWarehouse(context, warehouse),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        const Text('Transfer, çıkış deposundaki stoğu diğer depoya taşır.', style: TextStyle(color: Color(0xFF667085))),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _transfer(context),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Depolar arası transfer'),
        ),
      ],
    );
  }

  Widget _count(AppStore store) {
    if (store.warehouses.isEmpty) return const EmptyHint('Önce depo ekleyin.');
    _countWarehouse ??= store.warehouses.first.id;
    for (final product in store.products) {
      _countFields.putIfAbsent(product.id, () {
        return TextEditingController(text: qtyText(store.stockOf(product.id, warehouseId: _countWarehouse)));
      });
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _countWarehouse,
                  decoration: const InputDecoration(labelText: 'Sayılan depo'),
                  items: store.warehouses
                      .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _countWarehouse = value;
                      for (final product in store.products) {
                        _countFields[product.id]?.text = qtyText(store.stockOf(product.id, warehouseId: value));
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final counted = <String, double>{};
                  for (final product in store.products) {
                    final parsed = parseNum(_countFields[product.id]?.text ?? '');
                    if (parsed == null) continue;
                    counted[product.id] = parsed;
                  }
                  final changes = store.applyCount(_countWarehouse!, counted);
                  showMessage(context, changes == 0 ? 'Fark yok, kayıt açılmadı' : '$changes üründe sayım farkı işlendi');
                },
                child: const Text('Sayımı işle'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: store.products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = store.products[index];
              final system = store.stockOf(product.id, warehouseId: _countWarehouse);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(product.name)),
                      Text('Sistem ${qtyText(system)}', style: const TextStyle(color: Color(0xFF667085))),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _countFields[product.id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sayılan'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _serials(AppStore store) {
    final query = _search.text.trim().toLowerCase();
    final items = store.serials.where((item) => query.isEmpty || item.serial.toLowerCase().contains(query)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.qr_code_scanner), hintText: 'Seri no ara'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Seri no yok. Alış veya stok girişinde yazabilirsiniz.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return RecordRow(
                      icon: Icons.qr_code_2,
                      tone: item.status == SerialStatus.inStock ? kGood : item.status == SerialStatus.sold ? kInfo : kWarn,
                      title: item.serial,
                      subtitle: '${store.productName(item.productId)} · ${serialStatusLabel(item.status)}'
                          '${item.warrantyUntil == null ? '' : ' · garanti ${shortDate(item.warrantyUntil!)}'}',
                      trailing: item.partyId.isEmpty ? store.warehouseName(item.warehouseId) : store.partyName(item.partyId),
                      trailingColor: kInk,
                    );
                  },
                ),
        ),
      ],
    );
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

Future<void> _editWarehouse(BuildContext context, Warehouse? existing) async {
  final store = StoreScope.of(context);
  final name = TextEditingController(text: existing?.name ?? '');
  final city = TextEditingController(text: existing?.city ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Yeni depo' : 'Depo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad')),
          TextField(controller: city, decoration: const InputDecoration(labelText: 'İl')),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Adres')),
        ],
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () {
              final message = store.removeWarehouse(existing.id);
              showMessage(context, message ?? 'Depo silindi');
              Navigator.pop(context, false);
            },
            child: const Text('Sil'),
          ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
      ],
    ),
  );
  if (saved == true && name.text.trim().isNotEmpty) {
    store.upsertWarehouse(Warehouse(id: existing?.id ?? '', name: name.text.trim(), city: city.text.trim(), address: address.text.trim()));
  }
  name.dispose();
  city.dispose();
  address.dispose();
}

Future<void> _transfer(BuildContext context) async {
  final store = StoreScope.of(context);
  if (store.products.isEmpty || store.warehouses.length < 2) {
    showMessage(context, 'Transfer için en az iki depo ve bir ürün gerekli');
    return;
  }
  var productId = store.products.first.id;
  var fromId = store.warehouses.first.id;
  var toId = store.warehouses[1].id;
  final qty = TextEditingController(text: '1');
  final note = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Transfer'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: productId,
                decoration: const InputDecoration(labelText: 'Ürün'),
                items: store.products.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (value) => setLocal(() => productId = value ?? productId),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: fromId,
                decoration: const InputDecoration(labelText: 'Çıkış'),
                items: store.warehouses.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: (value) => setLocal(() => fromId = value ?? fromId),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: toId,
                decoration: const InputDecoration(labelText: 'Giriş'),
                items: store.warehouses.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: (value) => setLocal(() => toId = value ?? toId),
              ),
              const SizedBox(height: 8),
              TextField(controller: qty, decoration: const InputDecoration(labelText: 'Miktar'), keyboardType: TextInputType.number),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Not')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Transfer')),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) {
    final message = store.transfer(productId: productId, fromId: fromId, toId: toId, qty: parseNum(qty.text) ?? 0, note: note.text.trim());
    showMessage(context, message ?? 'Transfer kaydedildi');
  }
  qty.dispose();
  note.dispose();
}
