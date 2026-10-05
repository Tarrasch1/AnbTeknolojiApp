import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  int _tab = 0;
  final _serial = TextEditingController();
  static const _hints = [
    'Seri no yazın. Garanti satış tarihinde başlar, süre ürün kartındaki aydır.',
    'Açık fiş bekleyen iştir. Ücret cariye işlenirse müşteri bakiyesine eklenir.',
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
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Column(
      children: [
        const PageIntro(
          title: 'Garanti ve servis',
          hint: 'Hangi cihaz garantide, hangi arıza açık.',
          icon: Icons.build_outlined,
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: kNavy,
            tabs: const [Tab(text: 'Garanti sorgula'), Tab(text: 'Servis fişleri')],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(alignment: Alignment.centerLeft, child: Text(_hints[_tab], style: const TextStyle(color: kMuted))),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _lookup(store),
              _tickets(store),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lookup(AppStore store) {
    final result = _serial.text.trim().isEmpty ? null : store.lookupSerial(_serial.text);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Beyaz eşya, klima ve televizyonda garanti satış tarihinden itibaren işler.', style: TextStyle(color: Color(0xFF667085))),
        const SizedBox(height: 8),
        TextField(
          controller: _serial,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.qr_code_scanner), hintText: 'Seri no'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (_serial.text.trim().isNotEmpty && result == null) const EmptyHint('Bu seri bulunamadı.'),
        if (result != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.product?.name ?? 'Ürün', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  InfoLine('Durum', serialStatusLabel(result.serial.status)),
                  InfoLine('Müşteri', result.party?.name ?? 'Henüz satılmadı'),
                  InfoLine('Satış', result.serial.soldAt == null ? '—' : shortDate(result.serial.soldAt!)),
                  InfoLine('Garanti bitiş', result.serial.warrantyUntil == null ? 'Başlamadı' : shortDate(result.serial.warrantyUntil!)),
                  const SizedBox(height: 8),
                  StatusChip(
                    result.serial.soldAt == null
                        ? 'Garanti satışta başlar'
                        : result.inWarranty
                            ? 'Garanti kapsamında · ${result.daysLeft} gün'
                            : 'Garanti bitmiş',
                    color: result.inWarranty ? kGood : kBad,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _editTicket(context, serial: result.serial.serial, productId: result.serial.productId, partyId: result.serial.partyId, warranty: result.inWarranty),
                    child: const Text('Servis fişi aç'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tickets(AppStore store) {
    final items = [...store.tickets]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.icon(onPressed: () => _editTicket(context), icon: const Icon(Icons.add), label: const Text('Fiş')),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Servis fişi yok.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ticket = items[index];
                    return RecordRow(
                      icon: Icons.build_outlined,
                      tone: ticket.status == TicketStatus.done ? kGood : kWarn,
                      title: '${ticket.no} · ${store.productName(ticket.productId)}',
                      subtitle: '${store.partyName(ticket.partyId)} · ${ticket.fault}',
                      trailing: ticketStatusLabel(ticket.status),
                      onTap: () => _editTicket(context, existing: ticket),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Future<void> _editTicket(
  BuildContext context, {
  ServiceTicket? existing,
  String serial = '',
  String productId = '',
  String partyId = '',
  bool warranty = false,
}) async {
  final store = StoreScope.of(context);
  if (store.parties.isEmpty || store.products.isEmpty) return;
  var selectedParty = existing?.partyId ?? (partyId.isEmpty ? store.parties.first.id : partyId);
  var selectedProduct = existing?.productId ?? (productId.isEmpty ? store.products.first.id : productId);
  var status = existing?.status ?? TicketStatus.open;
  var underWarranty = existing?.underWarranty ?? warranty;
  var feeInvoiced = existing?.feeInvoiced ?? false;
  final serialController = TextEditingController(text: existing?.serial ?? serial);
  final fault = TextEditingController(text: existing?.fault ?? '');
  final resolution = TextEditingController(text: existing?.resolution ?? '');
  final fee = TextEditingController(text: numField(existing?.fee ?? 0));
  final note = TextEditingController(text: existing?.note ?? '');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(existing == null ? 'Servis fişi' : existing.no),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedParty,
                  decoration: const InputDecoration(labelText: 'Cari'),
                  items: store.parties.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                  onChanged: (value) => setLocal(() => selectedParty = value ?? selectedParty),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedProduct,
                  decoration: const InputDecoration(labelText: 'Ürün'),
                  items: store.products.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) => setLocal(() => selectedProduct = value ?? selectedProduct),
                ),
                TextField(controller: serialController, decoration: const InputDecoration(labelText: 'Seri no')),
                TextField(controller: fault, decoration: const InputDecoration(labelText: 'Arıza'), maxLines: 2),
                TextField(controller: resolution, decoration: const InputDecoration(labelText: 'Yapılan işlem'), maxLines: 2),
                DropdownButtonFormField<TicketStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: TicketStatus.values.map((item) => DropdownMenuItem(value: item, child: Text(ticketStatusLabel(item)))).toList(),
                  onChanged: (value) => setLocal(() => status = value ?? status),
                ),
                CheckboxListTile(
                  value: underWarranty,
                  onChanged: (value) => setLocal(() => underWarranty = value ?? false),
                  title: const Text('Garanti kapsamında'),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(controller: fee, decoration: const InputDecoration(labelText: 'Ücret (garanti dışı)'), keyboardType: TextInputType.number),
                CheckboxListTile(
                  value: feeInvoiced,
                  onChanged: (value) => setLocal(() => feeInvoiced = value ?? false),
                  title: const Text('Ücreti cariye işle'),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(controller: note, decoration: const InputDecoration(labelText: 'Not')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    ),
  );
  if (saved == true) {
    store.upsertTicket(
      ServiceTicket(
        id: existing?.id ?? '',
        no: existing?.no ?? '',
        date: existing?.date ?? DateTime.now(),
        partyId: selectedParty,
        productId: selectedProduct,
        serial: serialController.text.trim(),
        fault: fault.text.trim(),
        resolution: resolution.text.trim(),
        status: status,
        underWarranty: underWarranty,
        fee: parseNum(fee.text) ?? 0,
        feeInvoiced: feeInvoiced,
        note: note.text.trim(),
      ),
    );
  }
  serialController.dispose();
  fault.dispose();
  resolution.dispose();
  fee.dispose();
  note.dispose();
}
