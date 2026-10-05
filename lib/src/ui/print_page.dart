import 'package:flutter/material.dart';

import '../format.dart';
import 'print_html.dart';
import 'print_launch_stub.dart' if (dart.library.html) 'print_launch_web.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class PrintPage extends StatelessWidget {
  const PrintPage({required this.docId, super.key});

  final String docId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final doc = store.docById(docId);
    if (doc == null) return const Scaffold(body: EmptyHint('Belge bulunamadı'));
    final party = store.partyById(doc.partyId);
    final profile = store.profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(doc.no),
        actions: [
          FilledButton.icon(
            onPressed: () => launchPrint(documentHtml(store, doc)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Yazdır'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kLine),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
                      Text('${profile.address} ${profile.city}', style: const TextStyle(color: kMuted)),
                      Text('VKN ${profile.taxNo} · ${profile.taxOffice}', style: const TextStyle(color: kMuted)),
                      if (profile.iban.isNotEmpty) Text(profile.iban, style: const TextStyle(color: kMuted)),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final who = _SheetBox(
                            title: docKindLabel(doc.kind),
                            lines: [
                              doc.no,
                              'Tarih ${shortDate(doc.date)} · vade ${shortDate(doc.dueDate)}',
                              'Depo ${store.warehouseName(doc.warehouseId)}',
                            ],
                          );
                          final them = _SheetBox(
                            title: party?.name ?? 'Cari yok',
                            lines: [
                              '${party?.address ?? ''} ${party?.city ?? ''}'.trim(),
                              if (doc.shipAddress.isNotEmpty) 'Sevkiyat: ${doc.shipAddress}',
                              'VKN ${party?.taxNo ?? ''} · ${party?.taxOffice ?? ''}',
                            ],
                          );
                          if (constraints.maxWidth < 560) {
                            return Column(children: [who, const SizedBox(height: 8), them]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: who),
                              const SizedBox(width: 12),
                              Expanded(child: them),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Text('Ürün', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700))),
                          SizedBox(width: 64, child: Text('Miktar', textAlign: TextAlign.right, style: TextStyle(color: kMuted, fontWeight: FontWeight.w700))),
                          SizedBox(width: 120, child: Text('Tutar', textAlign: TextAlign.right, style: TextStyle(color: kMuted, fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const Divider(),
                      for (final line in doc.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(store.productName(line.productId), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      '${qtyText(line.qty)} × ${money(line.unitPrice)} · KDV %${qtyText(line.vatRate)}',
                                      style: const TextStyle(color: kMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 64, child: Text(qtyText(line.qty), textAlign: TextAlign.right)),
                              SizedBox(width: 120, child: Text(money(line.gross), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ),
                      const Divider(),
                      InfoLine('Ara toplam', money(doc.net)),
                      InfoLine('KDV', money(doc.vatTotal)),
                      InfoLine('Nakliye', money(doc.shipping)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Expanded(child: Text('Genel toplam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                          Text(money(doc.gross), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kNavy)),
                        ],
                      ),
                      if (doc.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(doc.note),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Bu çıktı şirket içi belgedir. GİB e-fatura veya e-irsaliye yerine geçmez.',
                        style: TextStyle(color: kMuted, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBox extends StatelessWidget {
  const _SheetBox({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final line in lines)
            if (line.trim().isNotEmpty) Text(line, style: const TextStyle(color: kMuted, height: 1.35)),
        ],
      ),
    );
  }
}
