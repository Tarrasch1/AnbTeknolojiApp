import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../xlsx_sheet.dart';
import 'cards.dart';
import 'docs_page.dart';
import 'finance_page.dart';
import 'save_file_stub.dart' if (dart.library.html) 'save_file_web.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({required this.partyId, super.key});

  final String partyId;

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  String _period = 'Tümü';

  (DateTime?, DateTime?) _range() {
    final now = DateTime.now();
    switch (_period) {
      case 'Bu ay':
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
      case 'Bu yıl':
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
      default:
        return (null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final party = store.partyById(widget.partyId);
    if (party == null) return const Scaffold(body: EmptyHint('Cari bulunamadı'));
    final balance = store.partyBalance(party.id);
    final range = _range();
    final slice = store.statementBetween(party.id, range.$1, range.$2);
    var running = slice.opening;
    final lines = <({LedgerRow? row, double balance, String title, DateTime? date, double debit, double credit})>[];
    if (range.$1 != null) {
      lines.add((row: null, balance: slice.opening, title: 'Önceki dönem devri', date: null, debit: 0, credit: 0));
    }
    for (final row in slice.rows) {
      running = round2(running + row.debit - row.credit);
      lines.add((row: row, balance: running, title: row.title, date: row.date, debit: row.debit, credit: row.credit));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap ekstresi'),
        actions: [
          IconButton(
            tooltip: 'Excel',
            onPressed: () => _export(party.name, lines),
            icon: const Icon(Icons.grid_on_outlined),
          ),
        ],
      ),
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
                    MarkBadge(label: initialsOf(party.name), color: partyTone(party.type), size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(party.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kNavy)),
                          Text(party.city.isEmpty ? partyTypeLabel(party.type) : '${partyTypeLabel(party.type)} · ${party.city}', style: const TextStyle(color: kMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(balanceText(balance), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: balanceColor(balance))),
                const SizedBox(height: 4),
                Text(
                  balance > 0.009
                      ? 'Borç sütunu bu carinin bize borcunu artırır. Tahsilat alacak sütununa yazılır.'
                      : balance < -0.009
                          ? 'Alacak sütunu bizim bu cariye borcumuzu artırır. Ödeme borç sütununa yazılır.'
                          : 'Hesap kapalı. Yeni fatura bakiyeyi yeniden açar.',
                  style: const TextStyle(color: kMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['Bu ay', 'Bu yıl', 'Tümü'])
                ChoiceChip(
                  label: Text(item),
                  selected: _period == item,
                  onSelected: (_) => setState(() => _period = item),
                ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: party.type == PartyType.supplier ? DocKind.purchase : DocKind.sale, partyId: party.id))),
                icon: const Icon(Icons.add),
                label: Text(party.type == PartyType.supplier ? 'Alış' : 'Satış'),
              ),
              OutlinedButton.icon(
                onPressed: () => openPaymentDialog(
                  context,
                  partyId: party.id,
                  direction: balance >= 0 ? PayDirection.inbound : PayDirection.outbound,
                ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Tahsilat / ödeme'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Her satırın sonunda bakiye yeniden hesaplanır. Excel düğmesi bu dönemi indirir.', style: TextStyle(color: kMuted, height: 1.35)),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            const EmptyHint('Bu dönemde hareket yok.')
          else
            for (final line in lines)
              HoverCard(
                onTap: line.row == null
                    ? null
                    : () {
                        final doc = _docFor(store, line.title);
                        if (doc == null) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DocDetailPage(docId: doc.id)));
                      },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(line.title, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                        ),
                        if (line.date != null) Text(shortDate(line.date!), style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Amount(label: 'Borç', value: line.debit, tone: kBad),
                        _Amount(label: 'Alacak', value: line.credit, tone: kGood),
                        _Amount(label: 'Bakiye', value: line.balance, tone: balanceColor(line.balance), emphasize: true),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  TradeDoc? _docFor(AppStore store, String title) {
    for (final doc in store.docs) {
      if (doc.partyId == widget.partyId && title.contains(doc.no)) return doc;
    }
    return null;
  }

  Future<void> _export(String partyName, List<({LedgerRow? row, double balance, String title, DateTime? date, double debit, double credit})> lines) async {
    final table = SheetTable(
      const ['Tarih', 'Açıklama', 'Borç', 'Alacak', 'Bakiye'],
      [
        for (final line in lines)
          [
            line.date == null ? '' : shortDate(line.date!),
            line.title,
            line.debit == 0 ? '' : sheetNum(line.debit),
            line.credit == 0 ? '' : sheetNum(line.credit),
            sheetNum(line.balance),
          ],
      ],
    );
    final safe = partyName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    await saveBytes(encodeXlsx(table), 'ekstre-$safe.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    if (!mounted) return;
    showMessage(context, 'Ekstre Excel olarak indirildi');
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, required this.tone, this.emphasize = false});

  final String label;
  final double value;
  final Color tone;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final text = value == 0 && !emphasize ? '—' : money(value);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: tone, fontSize: emphasize ? 14 : 13)),
        ],
      ),
    );
  }
}
