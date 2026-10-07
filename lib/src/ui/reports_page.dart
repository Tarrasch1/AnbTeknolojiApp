import 'package:flutter/material.dart';

import '../cities.dart';
import '../format.dart';
import 'cards.dart';
import 'docs_page.dart';
import 'party_page.dart';
import 'print_html.dart';
import 'print_launch_stub.dart' if (dart.library.html) 'print_launch_web.dart';
import 'scope.dart';
import 'stock_page.dart';
import 'theme.dart';
import 'widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = 'Bu ay';

  (DateTime?, DateTime?) _range() {
    final now = DateTime.now();
    if (_period == 'Bu ay') return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
    if (_period == 'Bu yıl') return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final range = _range();
    final sellers = store.topSellers(from: range.$1, to: range.$2);
    final customers = store.topParties(suppliers: false, from: range.$1, to: range.$2);
    final suppliers = store.topParties(suppliers: true, from: range.$1, to: range.$2);
    final brands = store.salesByBrand(from: range.$1, to: range.$2);
    final aging = store.receivableAging();
    final payables = store.payableAging();
    final brandRows = brands.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxBrand = brandRows.fold<double>(0, (max, entry) => entry.value > max ? entry.value : max);
    final brandTotal = brandRows.fold<double>(0, (sum, entry) => sum + entry.value);
    final categories = store.salesByCategory(from: range.$1, to: range.$2);
    final categoryRows = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCategory = categoryRows.fold<double>(0, (max, entry) => entry.value > max ? entry.value : max);
    final categoryTotal = categoryRows.fold<double>(0, (sum, entry) => sum + entry.value);
    final dormant = store.dormantCustomers();
    final returned = store.topReturns(from: range.$1, to: range.$2);
    final edocs = store.pendingEDocs();
    final overdue = store.overdueSales();
    final reps = store.salesByRep(from: range.$1, to: range.$2);
    final paces = store.collectionDays();
    final dueToday = store.dueTodaySheet();
    final saleOrders = store.openSaleOrders();
    final purchaseOrders = store.openPurchaseOrders();
    final quotes = store.staleQuotes();
    final ages = store.stockAges();
    final rates = store.returnRates(from: range.$1, to: range.$2);
    final cash = store.cashClose();
    final promises = store.duePromises();
    final breaches = store.overLimitParties();
    final reconcileWait = store.reconcileQueue();
    final repDays = store.repCollectionDays();
    final jumps = store.costJumps();
    final lateBuys = store.latePurchaseOrders();
    final losses = store.belowCostSales(from: range.$1, to: range.$2);
    final payWeek = store.duePurchaseWeek();
    final taxDupes = store.duplicateTaxNos();
    final deadDocs = store.inactiveOpenDocs();
    final discounts = store.discountByParty(from: range.$1, to: range.$2);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageIntro(
          inset: false,
          title: 'Raporlar',
          hint: 'Dönemi seçin. Kartın üzerine gelince öne çıkar, ürüne veya faturaya tıklayınca detay açılır.',
          icon: Icons.insights_outlined,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in const ['Bu ay', 'Bu yıl', 'Tümü'])
              _PeriodPick(
                label: item,
                selected: _period == item,
                onTap: () => setState(() => _period = item),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_periodHint, style: const TextStyle(color: kMuted, height: 1.35)),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip('Yeşil: ciro ve kâr', color: kGood),
            StatusChip('Kırmızı: gecikmiş alacak', color: kBad),
            StatusChip('Mavi: vadesi gelmemiş', color: kInfo),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            KpiCard(label: 'Satış cirosu', value: money(store.salesTotal(from: range.$1, to: range.$2)), icon: Icons.payments_outlined, tone: kGood),
            KpiCard(label: 'Brüt kâr', value: money(store.grossProfit(from: range.$1, to: range.$2)), icon: Icons.trending_up, tone: kGood),
            KpiCard(label: 'Stok değeri', value: money(store.stockValue()), icon: Icons.inventory_2_outlined),
            KpiCard(label: 'Açık alacak', value: money(store.totalReceivable()), icon: Icons.account_balance_wallet_outlined, tone: kBad),
          ],
        ),
        const SectionTitle('Geçen aya göre'),
        const _Caption('Bu takvim ayı, bir önceki ayla kıyaslanır. Dönem seçimi bu kutuyu değiştirmez.'),
        Builder(builder: (context) {
          final compare = store.monthCompare();
          final salesDelta = compare.sales - compare.prevSales;
          final profitDelta = compare.profit - compare.prevProfit;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KpiCard(label: 'Bu ay ciro', value: money(compare.sales), icon: Icons.payments_outlined, tone: kGood),
              KpiCard(label: 'Geçen ay ciro', value: money(compare.prevSales), icon: Icons.history, tone: kNavy),
              KpiCard(
                label: salesDelta >= 0 ? 'Ciro farkı' : 'Ciro düşüşü',
                value: money(salesDelta.abs()),
                icon: salesDelta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                tone: salesDelta >= 0 ? kGood : kBad,
              ),
              KpiCard(label: 'Bu ay kâr', value: money(compare.profit), icon: Icons.trending_up, tone: kGood),
              KpiCard(label: 'Geçen ay kâr', value: money(compare.prevProfit), icon: Icons.trending_flat, tone: kNavy),
              KpiCard(
                label: profitDelta >= 0 ? 'Kâr farkı' : 'Kâr düşüşü',
                value: money(profitDelta.abs()),
                icon: profitDelta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                tone: profitDelta >= 0 ? kGood : kBad,
              ),
            ],
          );
        }),
        const SectionTitle('KDV özeti'),
        const _Caption('Onaylı faturaların KDV toplamı. Vergi dairesine verilen beyanname değildir.'),
        Builder(builder: (context) {
          final vat = store.vatSummary(from: range.$1, to: range.$2);
          final net = vat.salesVat - vat.purchaseVat;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KpiCard(label: 'Satış KDV', value: money(vat.salesVat), icon: Icons.receipt_long, tone: kGood),
              KpiCard(label: 'Alış KDV', value: money(vat.purchaseVat), icon: Icons.inventory_outlined, tone: kTeal),
              KpiCard(
                label: net >= 0 ? 'Ödenecek KDV' : 'Devreden KDV',
                value: money(net.abs()),
                icon: Icons.account_balance_outlined,
                tone: net >= 0 ? kWarn : kInfo,
              ),
            ],
          );
        }),
        const SectionTitle('Ürün kârı'),
        const _Caption('Düşük kâr üstte. Maliyet, satış onayındaki alış fiyatıdır. Sonradan değişen alış fiyatı eski kârı yeniden yazmaz. Eski faturalarda alış fiyatı kayıtlı değilse, yedek açıldığında o günkü alış fiyatı kilitlenir.'),
        Builder(builder: (context) {
          final rows = store.productProfits(from: range.$1, to: range.$2);
          if (rows.isEmpty) return const EmptyHint('Bu aralıkta kâr hesabı yok.');
          return Column(
            children: [
              for (final row in rows)
                RecordRow(
                  icon: categoryIcon(row.product.category),
                  tone: row.profit < 0 ? kBad : kGood,
                  title: row.product.name,
                  subtitle: '${row.product.brand} · ${qtyText(row.qty)} adet',
                  trailing: money(row.profit),
                  trailingColor: row.profit < 0 ? kBad : kGood,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailPage(productId: row.product.id)),
                  ),
                ),
            ],
          );
        }),
        const SectionTitle('En çok satanlar'),
        const _Caption('Sıra, bu dönemdeki net satışa göredir. İadeler tutardan düşer.'),
        if (sellers.isEmpty)
          const EmptyHint('Bu aralıkta satış yok.')
        else
          for (var i = 0; i < sellers.length; i++)
            RecordRow(
              icon: _rankIcon(i),
              tone: i == 0 ? kNavy : kInfo,
              title: sellers[i].product.name,
              subtitle: '${sellers[i].product.brand} · ${qtyText(sellers[i].qty)} adet · ${sellers[i].product.category}',
              trailing: money(sellers[i].revenue),
              trailingColor: sellers[i].revenue < 0 ? kBad : kGood,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailPage(productId: sellers[i].product.id)),
              ),
            ),
        const SectionTitle('En çok ciro yapan müşteriler'),
        const _Caption('KDV dahil satış cirosu. İadeler düşer. Seçili döneme bağlıdır.'),
        if (customers.isEmpty)
          const EmptyHint('Bu aralıkta müşteri cirosu yok.')
        else
          for (var i = 0; i < customers.length; i++)
            RecordRow(
              icon: _rankIcon(i),
              tone: i == 0 ? kNavy : kInfo,
              title: customers[i].party.name,
              subtitle: customers[i].party.city.isEmpty ? 'İl yok' : customers[i].party.city,
              trailing: money(customers[i].amount),
              trailingColor: customers[i].amount < 0 ? kBad : kGood,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: customers[i].party.id)),
              ),
            ),
        const SectionTitle('En çok ciro yapan tedarikçiler'),
        const _Caption('KDV dahil alış cirosu. İadeler düşer. Seçili döneme bağlıdır.'),
        if (suppliers.isEmpty)
          const EmptyHint('Bu aralıkta tedarikçi cirosu yok.')
        else
          for (var i = 0; i < suppliers.length; i++)
            RecordRow(
              icon: _rankIcon(i),
              tone: i == 0 ? kTeal : kInfo,
              title: suppliers[i].party.name,
              subtitle: suppliers[i].party.city.isEmpty ? 'İl yok' : suppliers[i].party.city,
              trailing: money(suppliers[i].amount),
              trailingColor: kTeal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: suppliers[i].party.id)),
              ),
            ),
        const SectionTitle('Plasiyer cirosu'),
        const _Caption('KDV dahil satış cirosu. İadeler düşer. Cari kartındaki bugünkü plasiyer adına göredir. Seçili döneme bağlıdır.'),
        if (reps.isEmpty)
          const EmptyHint('Bu aralıkta plasiyer cirosu yok.')
        else
          for (final row in reps)
            RecordRow(
              icon: Icons.badge_outlined,
              tone: row.name == 'Plasiyersiz' ? kMuted : kNavy,
              title: row.name,
              subtitle: row.name == 'Plasiyersiz' ? 'Kartta plasiyer adı yok' : 'Müşteri kartındaki ad',
              trailing: money(row.amount),
              trailingColor: row.amount < 0 ? kBad : kGood,
            ),
        const SectionTitle('Ortalama tahsilat süresi'),
        const _Caption('Kapanmış satışta, fatura tarihinden belgeye bağlı son tahsilata kadar geçen gün. Belgesiz tahsilat süreye girmez. Dönem çipleri bu kutuyu değiştirmez.'),
        if (paces.isEmpty)
          const EmptyHint('Belgeye bağlı kapanmış tahsilat yok.')
        else
          for (final row in paces)
            RecordRow(
              icon: Icons.timer_outlined,
              tone: row.days > 30 ? kWarn : kGood,
              title: row.party.name,
              subtitle: '${row.invoices} fatura',
              trailing: '${qtyText(row.days)} gün',
              trailingColor: row.days > 30 ? kWarn : kGood,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: row.party.id))),
            ),
        const SectionTitle('Plasiyer tahsilat süresi'),
        const _Caption('Plasiyerin müşterilerinde kapanmış, belgeye bağlı tahsilatların fatura adedine göre ortalaması. Dönem çipleri bu kutuyu değiştirmez.'),
        if (repDays.isEmpty)
          const EmptyHint('Plasiyere bağlanacak kapanmış tahsilat yok.')
        else
          for (final row in repDays)
            RecordRow(
              icon: Icons.badge_outlined,
              tone: row.days > 30 ? kWarn : kGood,
              title: row.name,
              subtitle: '${row.customers} müşteri · ${row.invoices} fatura',
              trailing: '${qtyText(row.days)} gün',
              trailingColor: row.days > 30 ? kWarn : kGood,
            ),
        const SectionTitle('Marka dağılımı'),
        const _Caption('Çubuk en yüksek markaya göre dolar. Yüzde, bu dönemdeki marka cirosunun payıdır. KDV hariç.'),
        if (brandRows.isEmpty)
          const EmptyHint('Marka satışı yok.')
        else
          for (var i = 0; i < brandRows.length; i++)
            _BrandBar(
              name: brandRows[i].key,
              amount: brandRows[i].value,
              ratio: maxBrand <= 0 ? 0 : (brandRows[i].value / maxBrand).clamp(0, 1).toDouble(),
              share: brandTotal.abs() < 0.009 ? 0 : brandRows[i].value / brandTotal * 100,
              tone: _brandTone(i),
            ),
        const SectionTitle('Kategori cirosu'),
        const _Caption('KDV hariç net satış. İadeler düşer. Seçili döneme bağlıdır.'),
        if (categoryRows.isEmpty)
          const EmptyHint('Kategori satışı yok.')
        else
          for (var i = 0; i < categoryRows.length; i++)
            _BrandBar(
              name: categoryRows[i].key,
              amount: categoryRows[i].value,
              ratio: maxCategory <= 0 ? 0 : (categoryRows[i].value / maxCategory).clamp(0, 1).toDouble(),
              share: categoryTotal.abs() < 0.009 ? 0 : categoryRows[i].value / categoryTotal * 100,
              tone: _brandTone(i),
            ),
        const SectionTitle('Alacak yaşlandırma'),
        const _Caption('Açık satış faturalarının vadesine göre kalan tutarı.'),
        for (final entry in aging.entries)
          RecordRow(
            icon: entry.key == 'Vadesi gelmemiş' ? Icons.event_available_outlined : Icons.schedule,
            tone: _agingTone(entry.key),
            title: entry.key,
            subtitle: _agingHint(entry.key),
            trailing: money(entry.value),
            trailingColor: _agingTone(entry.key),
          ),
        const SectionTitle('Tedarikçi borç yaşlandırma'),
        const _Caption('Açık alış faturalarında bizim borcumuz. Vadesi gelen gün bugünü de kapsar.'),
        for (final entry in payables.entries)
          RecordRow(
            icon: entry.key == 'Vadesi gelmemiş' ? Icons.event_available_outlined : Icons.schedule,
            tone: _agingTone(entry.key),
            title: entry.key,
            subtitle: _agingHint(entry.key),
            trailing: money(entry.value),
            trailingColor: _agingTone(entry.key),
          ),
        const SectionTitle('Depo stok değeri'),
        const _Caption('Depodaki malların alış fiyatından değeri.'),
        for (final warehouse in store.warehouses)
          RecordRow(
            icon: Icons.warehouse_outlined,
            tone: kTeal,
            title: warehouse.name,
            subtitle: warehouse.city.isEmpty ? 'İl yok' : warehouse.city,
            trailing: money(store.stockValue(warehouseId: warehouse.id)),
          ),
        const SectionTitle('Vadesi geçen faturalar'),
        const _Caption('Tutar, faturanın henüz kapanmamış kalanıdır. Tahsilat listesi aynı carileri telefonuyla gruplar.'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: overdue.isEmpty ? null : () => launchPrint(collectionHtml(store)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Tahsilat listesi'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: dueToday.isEmpty ? null : () => launchPrint(dueTodayHtml(store)),
            icon: const Icon(Icons.today_outlined),
            label: const Text('Bugün vadesi gelenler'),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: promises.isEmpty ? null : () => launchPrint(promiseHtml(store)),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Ödeme sözü'),
            ),
            FilledButton.tonalIcon(
              onPressed: cash.isEmpty ? null : () => launchPrint(cashCloseHtml(store)),
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Kasa gün sonu'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (overdue.isEmpty)
          const EmptyHint('Vadesi geçen fatura yok.')
        else
          for (final doc in overdue)
            RecordRow(
              icon: Icons.receipt_long,
              tone: kBad,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · vade ${shortDate(doc.dueDate)}',
              trailing: money(store.docRemaining(doc)),
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
        const SectionTitle('Uyuyan müşteriler'),
        const _Caption('90 gündür onaylı satışı veya çıkış irsaliyesi olmayan müşteriler. Tedarikçiler bu listede yoktur.'),
        if (dormant.isEmpty)
          const EmptyHint('Son 90 günde her müşteriye satış var.')
        else
          for (final row in dormant)
            RecordRow(
              icon: Icons.phone_outlined,
              tone: kWarn,
              title: row.party.name,
              subtitle: '${row.party.phone.trim().isEmpty ? 'Telefon yok' : row.party.phone.trim()} · ${row.party.city.isEmpty ? 'İl yok' : row.party.city}',
              trailing: row.lastSale == null ? 'Hiç yok' : shortDate(row.lastSale!),
              trailingColor: kWarn,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: row.party.id))),
            ),
        const SectionTitle('En çok iade edilen ürünler'),
        const _Caption('Onaylı satış iadelerindeki adet. İade nedeni belgenin üzerinde durur. Seçili döneme bağlıdır.'),
        if (returned.isEmpty)
          const EmptyHint('Bu aralıkta satış iadesi yok.')
        else
          for (final row in returned)
            RecordRow(
              icon: Icons.assignment_return_outlined,
              tone: kBad,
              title: row.product.name,
              subtitle: '${row.product.brand} · ${row.docs} belge',
              trailing: '${qtyText(row.qty)} adet',
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: row.product.id))),
            ),
        const SectionTitle('İade oranı'),
        const _Caption('Dönemdeki iade adedi, dönemdeki satış adedine bölünür. İadesi olmayan ürün yazılmaz. Eski satışın iadesi oranı yüzde 100’ün üstüne çıkabilir.'),
        if (rates.isEmpty)
          const EmptyHint('Bu aralıkta iadesi olan satış yok.')
        else
          for (final row in rates)
            RecordRow(
              icon: Icons.percent,
              tone: row.rate >= 20 ? kBad : kWarn,
              title: row.product.name,
              subtitle: 'Satış ${qtyText(row.sold)} · iade ${qtyText(row.returned)}',
              trailing: '%${qtyText(row.rate)}',
              trailingColor: row.rate >= 20 ? kBad : kWarn,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: row.product.id))),
            ),
        const SectionTitle('Stok yaşı'),
        const _Caption('Elde duran ürünün son onaylı alış veya alış irsaliyesinden bugüne kaç gün geçtiği. Elle stok girişi yaşı değiştirmez. Dönem çipleri bu kutuyu değiştirmez.'),
        if (ages.isEmpty)
          const EmptyHint('Elde stok yok.')
        else
          for (final row in ages.take(12))
            RecordRow(
              icon: Icons.hourglass_bottom,
              tone: (row.days ?? 0) >= 90 ? kWarn : kNavy,
              title: row.product.name,
              subtitle: '${row.product.brand} · elde ${qtyText(row.onHand)}',
              trailing: row.days == null ? 'Alış yok' : '${row.days} gün',
              trailingColor: (row.days ?? 0) >= 90 ? kWarn : kNavy,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: row.product.id))),
            ),
        const SectionTitle('Dönmeyen teklifler'),
        const _Caption('15 gün ve daha eski onaylı teklifler. Faturaya veya siparişe dönünce listeden düşer.'),
        if (quotes.isEmpty)
          const EmptyHint('15 gündür bekleyen teklif yok.')
        else
          for (final doc in quotes)
            RecordRow(
              icon: Icons.request_quote_outlined,
              tone: kWarn,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · ${shortDate(doc.date)} · ${store.orderBrief(doc)}',
              trailing: money(doc.gross),
              trailingColor: kWarn,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
        const SectionTitle('Açık satış siparişleri'),
        const _Caption('Onaylı ve faturası kesilmemiş siparişler.'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: saleOrders.isEmpty ? null : () => launchPrint(orderListHtml(store)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Satış siparişlerini yazdır'),
          ),
        ),
        const SizedBox(height: 8),
        if (saleOrders.isEmpty)
          const EmptyHint('Açık satış siparişi yok.')
        else
          for (final doc in saleOrders)
            RecordRow(
              icon: Icons.shopping_bag_outlined,
              tone: kInfo,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · ${store.orderBrief(doc)}',
              trailing: shortDate(doc.date),
              trailingColor: kInfo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
        const SectionTitle('Açık alış siparişleri'),
        const _Caption('Onaylı ve faturası kesilmemiş alış siparişleri.'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: purchaseOrders.isEmpty ? null : () => launchPrint(orderListHtml(store, purchases: true)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Alış siparişlerini yazdır'),
          ),
        ),
        const SizedBox(height: 8),
        if (purchaseOrders.isEmpty)
          const EmptyHint('Açık alış siparişi yok.')
        else
          for (final doc in purchaseOrders)
            RecordRow(
              icon: Icons.local_shipping_outlined,
              tone: kTeal,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · ${store.orderBrief(doc)}',
              trailing: shortDate(doc.date),
              trailingColor: kTeal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
        const SectionTitle('Geciken alış siparişleri'),
        const _Caption('7 gün ve daha eski, faturası hâlâ kesilmemiş alış siparişleri.'),
        if (lateBuys.isEmpty)
          const EmptyHint('7 gündür bekleyen alış siparişi yok.')
        else
          for (final doc in lateBuys)
            RecordRow(
              icon: Icons.schedule,
              tone: kBad,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · ${store.orderBrief(doc)}',
              trailing: shortDate(doc.date),
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
        const SectionTitle('Limit aşan cariler'),
        const _Caption('Bakiyesi kredi limitini geçen müşteriler. Açık sipariş bu listeye girmez; satış onayındaki uyarıya girer.'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: breaches.isEmpty ? null : () => launchPrint(limitHtml(store)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Limit listesini yazdır'),
          ),
        ),
        const SizedBox(height: 8),
        if (breaches.isEmpty)
          const EmptyHint('Limiti aşan müşteri yok.')
        else
          for (final row in breaches)
            RecordRow(
              icon: Icons.speed,
              tone: kBad,
              title: row.party.name,
              subtitle: '${row.party.phone.trim().isEmpty ? 'Telefon yok' : row.party.phone.trim()} · bakiye ${money(row.balance)} · limit ${money(row.party.creditLimit)}',
              trailing: money(row.over),
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: row.party.id))),
            ),
        const SectionTitle('Mutabakat bekleyenler'),
        const _Caption('Bakiyesi açık cariler. Mutabakat tarihi hiç yok ya da 30 günden eski.'),
        if (reconcileWait.isEmpty)
          const EmptyHint('Mutabakatı bekleyen cari yok.')
        else
          for (final party in reconcileWait)
            RecordRow(
              icon: Icons.fact_check_outlined,
              tone: kWarn,
              title: party.name,
              subtitle: party.reconciledOn == null ? 'Mutabakat yok' : 'Son mutabakat ${shortDate(party.reconciledOn!)}',
              trailing: money(store.partyBalance(party.id)),
              trailingColor: store.partyBalance(party.id) < 0 ? kInfo : kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: party.id))),
            ),
        const SectionTitle('Alış sıçraması'),
        const _Caption('Son alış fiyatı, bir önceki alış fiyatına göre yüzde 10 veya daha fazla artan ürünler.'),
        if (jumps.isEmpty)
          const EmptyHint('Yüzde 10’u aşan alış artışı yok.')
        else
          for (final row in jumps)
            RecordRow(
              icon: Icons.trending_up,
              tone: kWarn,
              title: row.product.name,
              subtitle: '${shortDate(row.change.date)} · ${money(row.change.oldPurchase)} → ${money(row.change.newPurchase)}',
              trailing: money(row.change.newPurchase),
              trailingColor: kWarn,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: row.product.id))),
            ),
        const SectionTitle('Zararına kapanmış satışlar'),
        const _Caption('Onaylı satışta satırın net birim fiyatı, belgede kilitlenen alış maliyetinin altında. Güncel alış fiyatı kullanılmaz. Satış iadesi girmez.'),
        if (losses.isEmpty)
          const EmptyHint('Maliyeti kilitli zarar satırı yok.')
        else
          for (final row in losses)
            RecordRow(
              icon: Icons.money_off,
              tone: kBad,
              title: row.product.name,
              subtitle: '${row.doc.no} · ${store.partyName(row.doc.partyId)} · satış ${money(row.netUnit)} · maliyet ${money(row.cost)}',
              trailing: shortDate(row.doc.date),
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: row.doc.id))),
            ),
        const SectionTitle('Bu hafta ödenecek alışlar'),
        const _Caption('Kalanı olan onaylı alış faturaları. Vadesi bugün veya 7 gün içinde. Geçmiş vadeler bu listede yoktur.'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: payWeek.isEmpty ? null : () => launchPrint(payableWeekHtml(store)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Ödeme listesini yazdır'),
          ),
        ),
        const SizedBox(height: 8),
        if (payWeek.isEmpty)
          const EmptyHint('Bu hafta vadesi gelen açık alış yok.')
        else
          for (final doc in payWeek)
            RecordRow(
              icon: Icons.event,
              tone: kWarn,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · vade ${shortDate(doc.dueDate)}',
              trailing: money(store.docRemaining(doc)),
              trailingColor: kWarn,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
        const SectionTitle('Aynı vergi numarası'),
        const _Caption('Boş olmayan vergi numarası birden fazla caride yazılı. Kartlar birleştirilmez.'),
        if (taxDupes.isEmpty)
          const EmptyHint('Paylaşılan vergi numarası yok.')
        else
          for (final row in taxDupes)
            RecordRow(
              icon: Icons.badge_outlined,
              tone: kWarn,
              title: row.taxNo,
              subtitle: row.parties.map((party) => party.name).join(' · '),
              trailing: '${row.parties.length} cari',
              trailingColor: kWarn,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: row.parties.first.id))),
            ),
        const SectionTitle('Pasif ürünlü açık belgeler'),
        const _Caption('Ürün kartı kapalı. Satış siparişi, alış siparişi veya teklif hâlâ onaylı ve faturası kesilmemiş.'),
        if (deadDocs.isEmpty)
          const EmptyHint('Pasif ürünlü açık sipariş veya teklif yok.')
        else
          for (final row in deadDocs)
            RecordRow(
              icon: Icons.visibility_off_outlined,
              tone: kBad,
              title: row.doc.no,
              subtitle: '${store.partyName(row.doc.partyId)} · ${row.products.map((product) => product.name).join(', ')}',
              trailing: docKindLabel(row.doc.kind),
              trailingColor: kBad,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: row.doc.id))),
            ),
        const SectionTitle('Verilen iskonto'),
        const _Caption('Dönemdeki onaylı satışlarda satır iskontosunun tutarı. KDV hariçtir. Satış iadesi düşülmez.'),
        if (discounts.isEmpty)
          const EmptyHint('Bu dönemde iskonto yazılmış satış yok.')
        else
          for (final row in discounts)
            RecordRow(
              icon: Icons.percent,
              tone: kInfo,
              title: row.party.name,
              subtitle: '${row.invoices} fatura',
              trailing: money(row.discount),
              trailingColor: kInfo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: row.party.id))),
            ),
        const SectionTitle('E-belge iş listesi'),
        const _Caption('Onaylı satışta e-belge işareti boş olanlar. Bu liste manueldir. GİB bağlantısı değildir.'),
        if (edocs.isEmpty)
          const EmptyHint('İşareti boş onaylı satış yok.')
        else
          for (final doc in edocs)
            RecordRow(
              icon: Icons.receipt_outlined,
              tone: kInfo,
              title: doc.no,
              subtitle: '${store.partyName(doc.partyId)} · ${shortDate(doc.date)}',
              trailing: eDocLabel(doc.eDoc),
              trailingColor: kInfo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
            ),
      ],
    );
  }

  String get _periodHint {
    switch (_period) {
      case 'Bu ay':
        return 'Ciro ve kâr bu ayın onaylı satışlarından. Stok ve alacak bugünkü bakiyedir.';
      case 'Bu yıl':
        return 'Ciro ve kâr bu yılın onaylı satışlarından. Stok ve alacak bugünkü bakiyedir.';
      default:
        return 'Ciro ve kâr bütün onaylı satışlardan. Stok ve alacak bugünkü bakiyedir.';
    }
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: kMuted, height: 1.35)),
    );
  }
}

class _PeriodPick extends StatefulWidget {
  const _PeriodPick({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PeriodPick> createState() => _PeriodPickState();
}

class _PeriodPickState extends State<_PeriodPick> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: _hover ? 0 : 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected ? kNavy : (_hover ? const Color(0xFFF8FBFF) : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? kNavy : kLine, width: active ? 1.4 : 1),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(_hover ? 0.16 : 0.04),
                blurRadius: _hover ? 14 : 6,
                offset: Offset(0, _hover ? 6 : 2),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontWeight: FontWeight.w700, color: widget.selected ? Colors.white : kNavy),
          ),
        ),
      ),
    );
  }
}

class _BrandBar extends StatefulWidget {
  const _BrandBar({
    required this.name,
    required this.amount,
    required this.ratio,
    required this.share,
    required this.tone,
  });

  final String name;
  final double amount;
  final double ratio;
  final double share;
  final Color tone;

  @override
  State<_BrandBar> createState() => _BrandBarState();
}

class _BrandBarState extends State<_BrandBar> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: _hover ? 0 : 2, bottom: _hover ? 12 : 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFFF8FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hover ? kNavy : kLine, width: _hover ? 1.4 : 1),
          boxShadow: [
            BoxShadow(
              color: kNavy.withOpacity(_hover ? 0.14 : 0.05),
              blurRadius: _hover ? 18 : 8,
              offset: Offset(0, _hover ? 8 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: widget.tone.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.sell_outlined, color: widget.tone, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                      Text(percentLabel(widget.share), style: TextStyle(color: widget.tone, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(money(widget.amount), style: TextStyle(fontWeight: FontWeight.w800, color: widget.amount < 0 ? kBad : widget.tone)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.ratio),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: _hover ? 12 : 8,
                    backgroundColor: kSoft,
                    color: widget.tone,
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

IconData _rankIcon(int index) {
  switch (index) {
    case 0:
      return Icons.looks_one_outlined;
    case 1:
      return Icons.looks_two_outlined;
    case 2:
      return Icons.looks_3_outlined;
    case 3:
      return Icons.looks_4_outlined;
    default:
      return Icons.looks_5_outlined;
  }
}

Color _brandTone(int index) {
  const tones = [kNavy, kInfo, kTeal, kGood, kWarn];
  return tones[index % tones.length];
}

Color _agingTone(String key) {
  switch (key) {
    case 'Vadesi gelmemiş':
      return kInfo;
    case '1-30 gün':
    case '0-30 gün':
      return kWarn;
    case '31-60 gün':
    case '61-90 gün':
    case '90+ gün':
    case '60+ gün':
      return kBad;
    default:
      return kNavy;
  }
}

String _agingHint(String key) {
  switch (key) {
    case 'Vadesi gelmemiş':
      return 'Vadesi henüz gelmemiş açık faturalar.';
    case '1-30 gün':
      return 'Vadesi 1 ile 30 gün arasında geçmiş.';
    case '0-30 gün':
      return 'Vadesi bugün veya son 30 gün içinde gelmiş.';
    case '31-60 gün':
      return 'Vadesi 31 ile 60 gün arasında geçmiş.';
    case '60+ gün':
      return 'Vadesi 60 günden fazla geçmiş.';
    case '61-90 gün':
      return 'Vadesi 61 ile 90 gün arasında geçmiş.';
    case '90+ gün':
      return 'Vadesi 90 günden fazla geçmiş.';
    default:
      return '';
  }
}
