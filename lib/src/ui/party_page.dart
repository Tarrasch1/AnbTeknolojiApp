import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import 'cards.dart';
import 'docs_page.dart';
import 'finance_page.dart';
import 'scope.dart';
import 'statement_page.dart';
import 'theme.dart';
import 'widgets.dart';

class PartyPage extends StatefulWidget {
  const PartyPage({super.key});

  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage> with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final TabController _kinds = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _kinds.addListener(() {
      if (!_kinds.indexIsChanging && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _kinds.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final customers = _kinds.index == 0;
    final items = store.parties.where((party) {
      if (customers && party.type == PartyType.supplier) return false;
      if (!customers && party.type == PartyType.customer) return false;
      if (query.isEmpty) return true;
      return '${party.name} ${party.city} ${party.taxNo} ${party.phone}'.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        const PageIntro(
          title: 'Cariler',
          hint: 'Müşteri bize borçluysa kırmızı, biz tedarikçiye borçluysak mavi yazar.',
          icon: Icons.groups_outlined,
        ),
        const MeaningBar(
          items: [
            (kBad, 'Borçlu: bize borcu var'),
            (kInfo, 'Alacaklı: bizim borcumuz'),
            (kGood, 'Kapalı hesap'),
            (kInfo, 'Mavi kart: müşteri'),
            (kTeal, 'Yeşil kart: tedarikçi'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Ünvan, VKN, il, telefon'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _editParty(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Cari'),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _kinds,
            labelColor: kNavy,
            tabs: const [
              Tab(text: 'Müşteri'),
              Tab(text: 'Tedarikçi'),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Cari yok.')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1100 ? 3 : constraints.maxWidth >= 720 ? 2 : 1;
                    final tileWidth = (constraints.maxWidth - 12 * (cols - 1)) / cols;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: items.map((party) {
                          final balance = store.partyBalance(party.id);
                          final overLimit = party.creditLimit > 0 && balance > party.creditLimit;
                          final ratio = party.creditLimit <= 0 ? 0.0 : (balance / party.creditLimit);
                          return SizedBox(
                            width: tileWidth,
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
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PartyDetailPage extends StatelessWidget {
  const PartyDetailPage({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final party = store.partyById(partyId);
    if (party == null) return const Scaffold(body: EmptyHint('Cari bulunamadı'));
    final balance = store.partyBalance(party.id);
    final rows = store.statement(party.id);
    final list = store.priceListById(party.priceListId);
    final tone = partyTone(party.type);
    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [IconButton(onPressed: () => _editParty(context, party), icon: const Icon(Icons.edit_outlined))],
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
                    MarkBadge(label: initialsOf(party.name), color: tone, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(party.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kNavy)),
                          Text('${partyTypeLabel(party.type)} · ${party.city.isEmpty ? 'İl yok' : party.city}', style: const TextStyle(color: kMuted)),
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
                      ? 'Bu cari bize borçlu. Tahsilat bakiyeyi düşürür.'
                      : balance < -0.009
                          ? 'Bu cariye biz borçluyuz. Ödeme bakiyeyi kapatır.'
                          : 'Hesap kapalı. Yeni fatura bakiyeyi yeniden açar.',
                  style: const TextStyle(color: kMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          HoverCard(
            child: Column(
              children: [
                InfoLine('VKN / TCKN', party.taxNo.isEmpty ? '—' : party.taxNo),
                InfoLine('Vergi dairesi', party.taxOffice.isEmpty ? '—' : party.taxOffice),
                InfoLine('Yetkili', party.contact.isEmpty ? '—' : party.contact),
                InfoLine('Telefon', party.phone.isEmpty ? '—' : party.phone),
                InfoLine('E-posta', party.email.isEmpty ? '—' : party.email),
                InfoLine('Adres', '${party.address} ${party.city}'.trim().isEmpty ? '—' : '${party.address}, ${party.city}'),
                InfoLine('Fiyat listesi', list?.name ?? 'Liste fiyatı'),
                InfoLine('Vade', '${party.termDays} gün'),
                InfoLine('Risk limiti', party.creditLimit <= 0 ? 'Yok' : money(party.creditLimit)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PartyNote(note: party.note),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatementPage(partyId: party.id))),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ekstre'),
              ),
              if (party.type != PartyType.supplier)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: DocKind.sale, partyId: party.id))),
                  icon: const Icon(Icons.point_of_sale_outlined),
                  label: const Text('Satış'),
                ),
              if (party.type != PartyType.customer)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocEditor(kind: DocKind.purchase, partyId: party.id))),
                  icon: const Icon(Icons.inventory_outlined),
                  label: const Text('Alış'),
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
              OutlinedButton.icon(
                onPressed: () => _virman(context, party.id),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Virman'),
              ),
              if (party.type != PartyType.supplier)
                OutlinedButton.icon(
                  onPressed: () => _specialPrice(context, party.id),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Özel fiyat'),
                ),
            ],
          ),
          const SectionTitle('Son hareketler'),
          const Text('Tam borç, alacak ve bakiye dökümü ekstrede.', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const EmptyHint('Hareket yok.')
          else
            for (final row in rows.reversed.take(5))
              RecordRow(
                icon: row.debit > 0 ? Icons.south_west : Icons.north_east,
                tone: row.debit > 0 ? kBad : kGood,
                title: row.title,
                subtitle: row.detail.isEmpty ? shortDate(row.date) : '${shortDate(row.date)}\n${row.detail}',
                trailing: money(row.debit > 0 ? row.debit : row.credit),
                trailingColor: row.debit > 0 ? kBad : kGood,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatementPage(partyId: party.id))),
              ),
        ],
      ),
    );
  }
}

class _PartyNote extends StatelessWidget {
  const _PartyNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final text = note.trim().isEmpty ? 'Not yok' : note.trim();
    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Not', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

Future<void> _specialPrice(BuildContext context, String partyId) async {
  final store = StoreScope.of(context);
  final active = store.products.where((item) => item.active).toList();
  if (active.isEmpty) {
    showMessage(context, 'Ürün yok');
    return;
  }
  var productId = active.first.id;
  final price = TextEditingController(text: numField(store.specialPrice(partyId, productId)?.price ?? active.first.salePrice));
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        final rows = store.specialPrices.where((item) => item.partyId == partyId).toList();
        return AlertDialog(
          title: const Text('Özel fiyat'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Bu tutar, fiyat listesindeki iskontodan önce kullanılır. Yalnız satış belgelerinde.', style: TextStyle(color: kMuted, height: 1.35)),
                  const SizedBox(height: 8),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(store.productName(row.productId), overflow: TextOverflow.ellipsis)),
                          Text(money(row.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                          IconButton(
                            tooltip: 'Sil',
                            onPressed: () {
                              store.removeSpecialPrice(partyId, row.productId);
                              setLocal(() {});
                            },
                            icon: const Icon(Icons.delete_outline, color: kBad),
                          ),
                        ],
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value: productId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ürün'),
                    items: active.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (value) {
                      productId = value ?? productId;
                      final current = store.specialPrice(partyId, productId);
                      final product = store.productById(productId);
                      price.text = numField(current?.price ?? product?.salePrice ?? 0);
                      setLocal(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: price, decoration: const InputDecoration(labelText: 'Satış fiyatı (KDV hariç)'), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
            FilledButton(
              onPressed: () {
                final amount = parseNum(price.text);
                if (amount == null) {
                  showMessage(context, 'Fiyat girin');
                  return;
                }
                store.setSpecialPrice(partyId: partyId, productId: productId, price: amount);
                setLocal(() {});
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    ),
  );
  price.dispose();
}

Future<void> _virman(BuildContext context, String fromId) async {
  final store = StoreScope.of(context);
  final others = store.parties.where((item) => item.id != fromId && item.active).toList();
  if (others.isEmpty) {
    showMessage(context, 'Virman için ikinci cari yok');
    return;
  }
  var target = others.first.id;
  final amount = TextEditingController();
  final note = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Cari virman'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kaynak bakiyesi düşer, hedef bakiyesi aynı tutarda artar. Kasa toplamı değişmez.', style: TextStyle(color: kMuted, height: 1.35)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: target,
                decoration: const InputDecoration(labelText: 'Hedef cari'),
                items: others.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: (value) => setLocal(() => target = value ?? target),
              ),
              TextField(controller: amount, decoration: const InputDecoration(labelText: 'Tutar'), keyboardType: TextInputType.number),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Not')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aktar')),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) {
    showMessage(context, store.transferParties(fromId, target, parseNum(amount.text) ?? 0, note: note.text) ?? 'Virman işlendi');
  }
  amount.dispose();
  note.dispose();
}

Future<void> showFirmPanel(BuildContext context, String partyId) {
  final host = context;
  return showPanel(
    context: context,
    builder: (context) {
      final store = StoreScope.of(context);
      final party = store.partyById(partyId);
      if (party == null) return const SizedBox.shrink();
      final balance = store.partyBalance(party.id);
      final list = store.priceListById(party.priceListId);
      final tone = partyTone(party.type);
      return PanelFrame(
        title: party.name,
        subtitle: '${partyTypeLabel(party.type)} · ${party.city.isEmpty ? 'İl yok' : party.city}',
        headerColor: tone,
        mark: MarkBadge(label: initialsOf(party.name), color: const Color(0xFF0B1C33), size: 54),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MiniStat(icon: Icons.account_balance_wallet_outlined, label: 'Bakiye', value: balanceText(balance), tone: balanceColor(balance)),
                const SizedBox(width: 8),
                MiniStat(icon: Icons.speed, label: 'Limit', value: party.creditLimit <= 0 ? 'Yok' : money(party.creditLimit), tone: kCopper),
                const SizedBox(width: 8),
                MiniStat(icon: Icons.event, label: 'Vade', value: '${party.termDays} gün'),
              ],
            ),
            const SizedBox(height: 14),
            _contactTile(Icons.badge_outlined, 'VKN', party.taxNo.isEmpty ? '—' : '${party.taxNo} · ${party.taxOffice}'),
            _contactTile(Icons.person_outline, 'Yetkili', party.contact.isEmpty ? '—' : party.contact),
            _contactTile(Icons.call_outlined, 'Telefon', party.phone.isEmpty ? '—' : party.phone),
            _contactTile(Icons.mail_outline, 'E-posta', party.email.isEmpty ? '—' : party.email),
            _contactTile(Icons.location_on_outlined, 'Adres', '${party.address} ${party.city}'.trim().isEmpty ? '—' : '${party.address}, ${party.city}'),
            _contactTile(Icons.sell_outlined, 'Fiyat listesi', list?.name ?? 'Liste fiyatı'),
            _contactTile(Icons.sticky_note_2_outlined, 'Not', party.note.trim().isEmpty ? 'Not yok' : party.note),
          ],
        ),
        footer: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(host, MaterialPageRoute(builder: (_) => StatementPage(partyId: party.id)));
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Ekstre'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(host, MaterialPageRoute(builder: (_) => PartyDetailPage(partyId: party.id)));
              },
              child: const Text('Cari kart'),
            ),
            if (party.type != PartyType.supplier)
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(host, MaterialPageRoute(builder: (_) => DocEditor(kind: DocKind.sale, partyId: party.id)));
                },
                child: const Text('Satış'),
              ),
            if (party.type != PartyType.customer)
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(host, MaterialPageRoute(builder: (_) => DocEditor(kind: DocKind.purchase, partyId: party.id)));
                },
                child: const Text('Alış'),
              ),
            IconButton(
              tooltip: 'Düzenle',
              onPressed: () {
                Navigator.pop(context);
                _editParty(host, party);
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      );
    },
  );
}

Widget _contactTile(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: const Color(0xFFF4F0E8), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: kNavy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF667085))),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _editParty(BuildContext context, Party? existing) async {
  final store = StoreScope.of(context);
  final name = TextEditingController(text: existing?.name ?? '');
  final taxNo = TextEditingController(text: existing?.taxNo ?? '');
  final taxOffice = TextEditingController(text: existing?.taxOffice ?? '');
  final contact = TextEditingController(text: existing?.contact ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final email = TextEditingController(text: existing?.email ?? '');
  final city = TextEditingController(text: existing?.city ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final limit = TextEditingController(text: numField(existing?.creditLimit ?? 0));
  final term = TextEditingController(text: '${existing?.termDays ?? store.profile.defaultTermDays}');
  final note = TextEditingController(text: existing?.note ?? '');
  var type = existing?.type ?? PartyType.customer;
  var priceListId = existing?.priceListId ?? '';
  var active = existing?.active ?? true;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => FormDialog(
        title: existing == null ? 'Yeni cari' : 'Cari kartı',
        maxWidth: 680,
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                final message = store.removeParty(existing.id);
                showMessage(context, message ?? 'Cari silindi');
                Navigator.pop(context, false);
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
              hint: 'Müşteri satışa, tedarikçi alışa yazılır. İkisi de her iki belgede seçilir.',
              icon: Icons.badge_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in PartyType.values)
                        ChoiceChip(
                          label: Text(partyTypeLabel(item)),
                          selected: type == item,
                          onSelected: (_) => setLocal(() => type = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Ünvan')),
                  const SizedBox(height: 10),
                  FieldGrid(
                    children: [
                      TextField(controller: taxNo, decoration: const InputDecoration(labelText: 'VKN / TCKN')),
                      TextField(controller: taxOffice, decoration: const InputDecoration(labelText: 'Vergi dairesi')),
                    ],
                  ),
                ],
              ),
            ),
            FormSection(
              step: '2',
              title: 'İletişim',
              hint: 'İl, haritada bu cariyi hangi şehre koyacağını belirler.',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  FieldGrid(
                    children: [
                      TextField(controller: contact, decoration: const InputDecoration(labelText: 'Yetkili')),
                      TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefon')),
                      TextField(controller: email, decoration: const InputDecoration(labelText: 'E-posta')),
                      TextField(controller: city, decoration: const InputDecoration(labelText: 'İl')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: address, decoration: const InputDecoration(labelText: 'Adres')),
                ],
              ),
            ),
            FormSection(
              step: '3',
              title: 'Ticari koşullar',
              hint: 'Vade günü yeni faturanın vadesini doldurur. Limit aşılırsa kart uyarır.',
              icon: Icons.account_balance_wallet_outlined,
              child: Column(
                children: [
                  FieldGrid(
                    children: [
                      TextField(controller: limit, decoration: const InputDecoration(labelText: 'Kredi limiti'), keyboardType: TextInputType.number),
                      TextField(controller: term, decoration: const InputDecoration(labelText: 'Vade (gün)'), keyboardType: TextInputType.number),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: priceListId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Fiyat listesi'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Liste fiyatı')),
                      ...store.priceLists.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.name} (%${qtyText(item.discountPercent)})', overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (value) => setLocal(() => priceListId = value ?? ''),
                  ),
                  CheckboxListTile(
                    value: active,
                    onChanged: (value) => setLocal(() => active = value ?? true),
                    title: const Text('Aktif'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextField(controller: note, decoration: const InputDecoration(labelText: 'Risk / not'), maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (saved == true && name.text.trim().isNotEmpty) {
    store.upsertParty(
      Party(
        id: existing?.id ?? '',
        type: type,
        name: name.text.trim(),
        taxNo: taxNo.text.trim(),
        taxOffice: taxOffice.text.trim(),
        contact: contact.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),
        city: city.text.trim(),
        address: address.text.trim(),
        creditLimit: parseNum(limit.text) ?? 0,
        termDays: int.tryParse(term.text) ?? 30,
        priceListId: priceListId,
        note: note.text.trim(),
        active: active,
      ),
    );
  } else if (saved == true && context.mounted) {
    showMessage(context, 'Ünvan gerekli');
  }
  name.dispose();
  taxNo.dispose();
  taxOffice.dispose();
  contact.dispose();
  phone.dispose();
  email.dispose();
  city.dispose();
  address.dispose();
  limit.dispose();
  term.dispose();
  note.dispose();
}
