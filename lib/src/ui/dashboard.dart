import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import 'cards.dart';
import 'docs_page.dart';
import 'finance_page.dart';
import 'party_page.dart';
import 'scope.dart';
import 'stock_page.dart';
import 'theme.dart';
import 'widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);
    final critical = store.criticalProducts();
    final agenda = store.agenda();
    final recent = [...store.docs]..sort((a, b) => b.date.compareTo(a.date));
    final cashAccounts = store.accounts.where((item) => item.role == AccountRole.cash || item.role == AccountRole.bank).toList();

    final firms = [...store.parties]..sort((a, b) => store.partyBalance(b.id).abs().compareTo(store.partyBalance(a.id).abs()));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HoverCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const MarkBadge(label: 'AK', color: kNavy, icon: Icons.bolt, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.profile.shortName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy)),
                    Text(store.profile.name, style: const TextStyle(color: Color(0xFF667085))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusChip(store.profile.city.isEmpty ? 'İstanbul' : store.profile.city),
                        StatusChip('VKN ${store.profile.taxNo}', color: kCopper),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip('Kırmızı: bize borç veya kritik stok', color: kBad),
            StatusChip('Mavi: bizim borcumuz', color: kInfo),
            StatusChip('Yeşil: kapalı hesap veya yeterli stok', color: kGood),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            KpiCard(label: 'Stok değeri', value: money(store.stockValue()), icon: Icons.inventory_2_outlined),
            KpiCard(label: 'Müşteri alacağı', value: money(store.totalReceivable()), icon: Icons.south_west, tone: kBad),
            KpiCard(label: 'Tedarikçi borcu', value: money(store.totalPayable()), icon: Icons.north_east, tone: kInfo),
            KpiCard(
              label: 'Bu ay satış',
              value: money(store.salesTotal(from: from, to: to)),
              icon: Icons.point_of_sale_outlined,
              tone: kGood,
            ),
            KpiCard(
              label: 'Bu ay brüt kâr',
              value: money(store.grossProfit(from: from, to: to)),
              icon: Icons.trending_up,
              tone: kGood,
            ),
            KpiCard(label: 'Vade ajandası', value: '${agenda.length} kayıt', icon: Icons.calendar_month_outlined, tone: kWarn),
            KpiCard(label: 'Kritik stok', value: '${critical.length} ürün', icon: Icons.warning_amber_rounded, tone: kWarn),
            KpiCard(label: 'Açık irsaliye', value: '${store.openWaybills().length}', icon: Icons.local_shipping_outlined, tone: kInfo),
            KpiCard(label: 'Açık servis', value: '${store.tickets.where((t) => t.status != TicketStatus.done && t.status != TicketStatus.cancelled).length}', icon: Icons.build_outlined),
          ],
        ),
        const SectionTitle('Firma kartları'),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: firms.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final party = firms[index];
              final balance = store.partyBalance(party.id);
              final overLimit = party.creditLimit > 0 && balance > party.creditLimit;
              final ratio = party.creditLimit <= 0 ? 0.0 : balance / party.creditLimit;
              return SizedBox(
                width: 300,
                child: FirmCard(
                  name: party.name,
                  city: party.city,
                  phone: party.phone,
                  typeLabel: partyTypeLabel(party.type),
                  balanceLabel: balanceText(balance),
                  balanceTone: balanceColor(balance),
                  tone: partyTone(party.type),
                  limitRatio: ratio < 0 ? 0 : ratio,
                  overLimit: overLimit,
                  onTap: () => showFirmPanel(context, party.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Kasa ve banka'),
        const Text('Nakit burada. Çek portföyü henüz nakit değildir.', style: TextStyle(color: kMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final account in cashAccounts)
              KpiCard(
                label: account.name,
                value: money(store.accountBalance(account.id)),
                icon: accountIcon(account.role),
                tone: accountTone(account.role),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocEditor(kind: DocKind.sale))),
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Satış'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocEditor(kind: DocKind.purchase))),
              icon: const Icon(Icons.inventory_outlined),
              label: const Text('Alış'),
            ),
            OutlinedButton.icon(
              onPressed: () => openPaymentDialog(context),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Tahsilat'),
            ),
          ],
        ),
        const SectionTitle('Vade ajandası'),
        const Text('Gecikmişler ve önümüzdeki 21 gün. Fatura kalan tutarı, çek ise evrak tutarıdır.', style: TextStyle(color: kMuted)),
        const SizedBox(height: 8),
        if (agenda.isEmpty)
          const EmptyHint('Bu aralıkta vadesi gelen fatura veya çek yok.')
        else
          for (var i = 0; i < agenda.length; i++) ...[
            if (i == 0 || _agendaLabel(agenda[i]) != _agendaLabel(agenda[i - 1]))
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Text(_agendaLabel(agenda[i]), style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
              ),
            _AgendaRow(entry: agenda[i]),
          ],
        const SectionTitle('Kritik stok'),
        if (critical.isEmpty)
          const EmptyHint('Minimumun altında ürün yok.')
        else
          ...critical.map((product) {
            final qty = store.stockOf(product.id);
            return GoodsCard(
              name: product.name,
              brand: product.brand,
              category: product.category,
              sku: product.sku,
              price: money(product.salePrice),
              stock: qty,
              minStock: product.minStock,
              onTap: () => showGoodsPanel(context, product.id),
            );
          }),
        const SectionTitle('Son belgeler'),
        ...recent.take(6).map((doc) => _DocTile(doc: doc)),
      ],
    );
  }
}

String _agendaLabel(AgendaEntry entry) {
  if (entry.late) return 'Gecikmiş';
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  final due = DateTime(entry.day.year, entry.day.month, entry.day.day);
  if (due == day) return 'Bugün';
  if (due == day.add(const Duration(days: 1))) return 'Yarın';
  return shortDate(due);
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.entry});

  final AgendaEntry entry;

  @override
  Widget build(BuildContext context) {
    return RecordRow(
      icon: entry.check ? Icons.sticky_note_2_outlined : Icons.receipt_long,
      tone: entry.late ? kBad : (entry.check ? kWarn : kInfo),
      title: entry.title,
      subtitle: entry.subtitle,
      trailing: money(entry.amount),
      trailingColor: entry.late ? kBad : kInk,
      onTap: entry.docId.isEmpty
          ? () => showFirmPanel(context, entry.partyId)
          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: entry.docId))),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc});

  final TradeDoc doc;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return DocCard(
      kind: doc.kind,
      no: doc.no,
      party: store.partyName(doc.partyId),
      meta: '${docKindShort(doc.kind)} · ${shortDate(doc.date)}',
      amount: money(doc.gross),
      status: docStatusText(doc.status, doc.kind),
      statusTone: statusColor(doc.status),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id))),
    );
  }
}
