import 'package:flutter/material.dart';

import '../cities.dart';
import '../format.dart';
import 'cards.dart';
import 'docs_page.dart';
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
    final brands = store.salesByBrand(from: range.$1, to: range.$2);
    final aging = store.receivableAging();
    final brandRows = brands.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxBrand = brandRows.fold<double>(0, (max, entry) => entry.value > max ? entry.value : max);
    final brandTotal = brandRows.fold<double>(0, (sum, entry) => sum + entry.value);
    final overdue = store.overdueSales();
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
        const _Caption('Düşük kâr üstte. Tutar, satışın netinden alış fiyatı kadarı düşünülerek hesaplanır.'),
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
        const _Caption('Tutar, faturanın henüz kapanmamış kalanıdır.'),
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
      return kWarn;
    case '31-60 gün':
    case '61-90 gün':
    case '90+ gün':
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
    case '31-60 gün':
      return 'Vadesi 31 ile 60 gün arasında geçmiş.';
    case '61-90 gün':
      return 'Vadesi 61 ile 90 gün arasında geçmiş.';
    case '90+ gün':
      return 'Vadesi 90 günden fazla geçmiş.';
    default:
      return '';
  }
}
