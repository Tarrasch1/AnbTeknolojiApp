import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import 'cards.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  int _tab = 0;
  static const _hints = [
    'Tahsilat müşteri borcunu azaltır. Ödeme tedarikçi borcunu azaltır. Cari boşsa masraftır.',
    'Kasa ve banka nakittir. Çek portföyü henüz nakde dönmemiş evraktır.',
    'Alınan çek cariyi hemen kapatır. Tahsil edilince bankaya geçer. Karşılıksız çek borcu geri açar.',
    'Fiyat listesi, yeni satışta liste fiyatından düşülen iskontodur.',
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
    final store = StoreScope.of(context);
    return Column(
      children: [
        const PageIntro(
          title: 'Finans',
          hint: 'Para nerede, kimden alındı, kime ödendi.',
          icon: Icons.account_balance_wallet_outlined,
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: kNavy,
            tabs: const [
              Tab(text: 'Tahsilat / ödeme'),
              Tab(text: 'Kasa ve banka'),
              Tab(text: 'Çek / senet'),
              Tab(text: 'Fiyat listeleri'),
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
            children: [
              _payments(store),
              _accounts(store),
              _instruments(store),
              _prices(store),
            ],
          ),
        ),
      ],
    );
  }

  Widget _payments(AppStore store) {
    final items = store.payments.where((item) => item.partyId.isNotEmpty).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.icon(
              onPressed: () => openPaymentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Hareket'),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Tahsilat veya ödeme yok.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final inbound = item.direction == PayDirection.inbound;
                    return RecordRow(
                      icon: inbound ? Icons.south_west : Icons.north_east,
                      tone: inbound ? kGood : kBad,
                      title: '${item.no} · ${store.partyName(item.partyId)}',
                      subtitle: '${shortDate(item.date)} · ${payMethodLabel(item.method)} · ${store.accountById(item.accountId)?.name ?? ''} · ${item.note}',
                      trailing: '${inbound ? '+' : '-'}${money(item.amount)}',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _accounts(AppStore store) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Alınan çek portföye girer ve cariyi kapatır. Tahsil edilince bankaya virman olur. Karşılıksız çek cariyi yeniden açar.',
          style: TextStyle(color: Color(0xFF667085)),
        ),
        const SizedBox(height: 8),
        ...store.accounts.map((account) {
          final balance = store.accountBalance(account.id);
          final tone = accountTone(account.role);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HoverCard(
              child: Row(
                children: [
                  MarkBadge(label: '', color: tone, icon: accountIcon(account.role), size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                        Text(accountRoleLabel(account.role), style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                        if (account.iban.isNotEmpty) Text(account.iban, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(money(balance), style: TextStyle(fontWeight: FontWeight.w800, color: balance < 0 ? kBad : kNavy)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(onPressed: () => _editAccount(context), icon: const Icon(Icons.add), label: const Text('Hesap ekle')),
            FilledButton.tonalIcon(onPressed: () => _countCash(context, store), icon: const Icon(Icons.point_of_sale_outlined), label: const Text('Kasa sayımı')),
          ],
        ),
      ],
    );
  }

  Widget _instruments(AppStore store) {
    final items = [...store.instruments]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.icon(onPressed: () => _editInstrument(context), icon: const Icon(Icons.add), label: const Text('Çek / senet')),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyHint('Çek veya senet yok.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('${item.kind == InstrumentKind.check ? 'Çek' : 'Senet'} ${item.no}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                StatusChip(instrumentStatusLabel(item), color: item.status == InstrumentStatus.bounced ? kBad : kNavy),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${store.partyName(item.partyId)} · ${money(item.amount)}'),
                            Text('${item.bank} ${item.branch} · keşideci ${item.issuer.isEmpty ? '—' : item.issuer}'),
                            Text('Vade ${shortDate(item.dueDate)} · düzenleme ${shortDate(item.issueDate)}'),
                            if (item.endorsedToPartyId.isNotEmpty) Text('Ciro: ${store.partyName(item.endorsedToPartyId)}'),
                            if (item.note.isNotEmpty) Text(item.note),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (item.direction == InstrumentDirection.received && item.status == InstrumentStatus.portfolio)
                                  OutlinedButton(onPressed: () => _run(context, store.markDeposited(item.id)), child: const Text('Tahsile ver')),
                                if (item.direction == InstrumentDirection.received &&
                                    (item.status == InstrumentStatus.portfolio || item.status == InstrumentStatus.deposited))
                                  FilledButton(onPressed: () => _collect(context, item), child: const Text('Tahsil et')),
                                if (item.direction == InstrumentDirection.issued && item.status == InstrumentStatus.portfolio)
                                  FilledButton(onPressed: () => _pay(context, item), child: const Text('Ödendi')),
                                if (item.status == InstrumentStatus.portfolio || item.status == InstrumentStatus.deposited)
                                  OutlinedButton(onPressed: () => _run(context, store.bounceInstrument(item.id)), child: const Text('Karşılıksız')),
                                if (item.direction == InstrumentDirection.received && item.status == InstrumentStatus.portfolio)
                                  OutlinedButton(onPressed: () => _endorse(context, item), child: const Text('Ciro')),
                                if (item.direction == InstrumentDirection.received && item.status == InstrumentStatus.portfolio)
                                  TextButton(onPressed: () => _run(context, store.returnInstrument(item.id)), child: const Text('İade')),
                              ],
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

  Widget _prices(AppStore store) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Bayi ve proje iskontoları yeni satış belgelerinde satış fiyatından düşülür.', style: TextStyle(color: Color(0xFF667085))),
        const SizedBox(height: 8),
        ...store.priceLists.map((list) {
          return Card(
            child: ListTile(
              title: Text(list.name),
              subtitle: Text(list.note),
              trailing: Text('%${qtyText(list.discountPercent)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              onTap: () => _editPrice(context, list),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => _editPrice(context, null), icon: const Icon(Icons.add), label: const Text('Liste')),
      ],
    );
  }
}

Future<void> openPaymentDialog(
  BuildContext context, {
  String partyId = '',
  String docId = '',
  PayDirection direction = PayDirection.inbound,
  Payment? existing,
}) async {
  final store = StoreScope.of(context);
  if (existing != null && existing.instrumentId.isNotEmpty) {
    showMessage(context, 'Çek ve senet finans ekranından düzeltilir');
    return;
  }
  if (existing != null && existing.groupId.isNotEmpty) {
    showMessage(context, 'Virman iki cariyi birlikte etkiler. Yeni virman girin.');
    return;
  }
  final usable = store.accounts.where((item) => item.role == AccountRole.cash || item.role == AccountRole.bank).toList();
  if (usable.isEmpty) {
    showMessage(context, 'Kasa veya banka hesabı yok');
    return;
  }
  var dir = existing?.direction ?? direction;
  var method = existing == null || existing.method == PayMethod.check || existing.method == PayMethod.note ? PayMethod.transfer : existing.method;
  var accountId = existing != null && usable.any((item) => item.id == existing.accountId) ? existing.accountId : usable.first.id;
  var selectedParty = existing?.partyId ?? partyId;
  var selectedDoc = existing?.docId ?? docId;
  var date = existing?.date ?? DateTime.now();
  final doc = store.docById(selectedDoc);
  final amount = TextEditingController(text: existing != null ? numField(existing.amount) : (doc == null ? '' : numField(store.docRemaining(doc).abs())));
  final note = TextEditingController(text: existing?.note ?? '');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        final parties = store.parties.where((item) => item.active).toList();
        final docs = store.docs.where((item) => item.partyId == selectedParty && item.status == DocStatus.approved && kindAffectsCari(item.kind)).toList();
        return AlertDialog(
          title: Text(existing == null ? 'Tahsilat / ödeme' : 'Kaydı düzelt'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PayDirection>(
                    value: dir,
                    decoration: const InputDecoration(labelText: 'Yön'),
                    items: const [
                      DropdownMenuItem(value: PayDirection.inbound, child: Text('Tahsilat')),
                      DropdownMenuItem(value: PayDirection.outbound, child: Text('Ödeme / masraf')),
                    ],
                    onChanged: (value) => setLocal(() => dir = value ?? dir),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedParty,
                    decoration: const InputDecoration(labelText: 'Cari (masrafta boş)'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Cari yok')),
                      ...parties.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))),
                    ],
                    onChanged: (value) => setLocal(() {
                      selectedParty = value ?? '';
                      selectedDoc = '';
                    }),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: docs.any((item) => item.id == selectedDoc) ? selectedDoc : '',
                    decoration: const InputDecoration(labelText: 'Belge'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Belgeye bağlama')),
                      ...docs.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.no} · kalan ${money(store.docRemaining(item))}'))),
                    ],
                    onChanged: (value) => setLocal(() => selectedDoc = value ?? ''),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: accountId,
                    decoration: const InputDecoration(labelText: 'Hesap'),
                    items: usable.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                    onChanged: (value) => setLocal(() => accountId = value ?? accountId),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PayMethod>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Yöntem'),
                    items: PayMethod.values
                        .where((item) => item != PayMethod.check && item != PayMethod.note)
                        .map((item) => DropdownMenuItem(value: item, child: Text(payMethodLabel(item))))
                        .toList(),
                    onChanged: (value) => setLocal(() => method = value ?? method),
                  ),
                  const SizedBox(height: 8),
                  DateField(label: 'Tarih', value: date, onChanged: (value) => setLocal(() => date = value)),
                  const SizedBox(height: 8),
                  TextField(controller: amount, decoration: const InputDecoration(labelText: 'Tutar'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(labelText: 'Açıklama', hintText: 'Ekstre satırında ve Excel çıktısında görünür'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
          ],
        );
      },
    ),
  );
  if (saved == true && context.mounted) {
    final payment = Payment(
      id: existing?.id ?? '',
      no: existing?.no ?? '',
      date: date,
      partyId: selectedParty,
      docId: selectedDoc,
      accountId: accountId,
      direction: dir,
      method: method,
      amount: parseNum(amount.text) ?? 0,
      note: note.text.trim(),
    );
    final message = existing == null ? store.addPayment(payment) : store.updatePayment(payment);
    showMessage(context, message ?? (existing == null ? 'Kaydedildi' : 'Kayıt düzeltildi'));
  }
  amount.dispose();
  note.dispose();
}

Future<String?> pickMoneyAccount(BuildContext context) async {
  final store = StoreScope.of(context);
  final usable = store.accounts.where((item) => item.role == AccountRole.cash || item.role == AccountRole.bank).toList();
  if (usable.isEmpty) return null;
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Hesap'),
      children: usable
          .map((item) => SimpleDialogOption(onPressed: () => Navigator.pop(context, item.id), child: Text(item.name)))
          .toList(),
    ),
  );
}

void _run(BuildContext context, String? message) => showMessage(context, message ?? 'Güncellendi');

Future<void> _collect(BuildContext context, Instrument item) async {
  final accountId = await pickMoneyAccount(context);
  if (accountId == null || !context.mounted) return;
  _run(context, StoreScope.of(context).collectInstrument(item.id, accountId));
}

Future<void> _pay(BuildContext context, Instrument item) async {
  final accountId = await pickMoneyAccount(context);
  if (accountId == null || !context.mounted) return;
  _run(context, StoreScope.of(context).payInstrument(item.id, accountId));
}

Future<void> _endorse(BuildContext context, Instrument item) async {
  final store = StoreScope.of(context);
  final suppliers = store.parties.where((party) => party.type != PartyType.customer && party.active).toList();
  if (suppliers.isEmpty) return;
  var supplierId = suppliers.first.id;
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Ciro'),
        content: DropdownButtonFormField<String>(
          value: supplierId,
          items: suppliers.map((party) => DropdownMenuItem(value: party.id, child: Text(party.name))).toList(),
          onChanged: (value) => setLocal(() => supplierId = value ?? supplierId),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ciro et')),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) _run(context, store.endorseInstrument(item.id, supplierId));
}

Future<void> _countCash(BuildContext context, AppStore store) async {
  final account = store.accountByRole(AccountRole.cash);
  if (account == null) {
    showMessage(context, 'Kasa tanımlı değil');
    return;
  }
  final system = store.accountBalance(account.id);
  final counted = TextEditingController(text: numField(system));
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        final diff = (parseNum(counted.text) ?? 0) - system;
        return AlertDialog(
          title: const Text('Kasa sayımı'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sistem bakiyesi ${money(system)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: counted,
                  decoration: const InputDecoration(labelText: 'Sayılan tutar'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  diff.abs() < 0.009 ? 'Fark yok' : 'Fark ${money(diff)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: diff < -0.009 ? kBad : kNavy),
                ),
                const SizedBox(height: 6),
                const Text('Fazlaysa kasa artar, eksikse azalır. Cari bakiyesi değişmez.', style: TextStyle(color: kMuted, height: 1.35)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Farkı işle')),
          ],
        );
      },
    ),
  );
  if (saved == true && context.mounted) {
    showMessage(context, store.countCash(parseNum(counted.text) ?? system) ?? 'Sayım işlendi');
  }
  counted.dispose();
}

Future<void> _editAccount(BuildContext context) async {
  final store = StoreScope.of(context);
  final name = TextEditingController();
  final iban = TextEditingController();
  var role = AccountRole.bank;
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Hesap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(controller: iban, decoration: const InputDecoration(labelText: 'IBAN')),
            DropdownButtonFormField<AccountRole>(
              value: role,
              items: AccountRole.values.map((item) => DropdownMenuItem(value: item, child: Text(accountRoleLabel(item)))).toList(),
              onChanged: (value) => setLocal(() => role = value ?? role),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    ),
  );
  if (saved == true && name.text.trim().isNotEmpty) {
    store.upsertAccount(CashAccount(id: '', name: name.text.trim(), role: role, iban: iban.text.trim()));
  }
  name.dispose();
  iban.dispose();
}

Future<void> _editPrice(BuildContext context, PriceList? existing) async {
  final store = StoreScope.of(context);
  final name = TextEditingController(text: existing?.name ?? '');
  final discount = TextEditingController(text: numField(existing?.discountPercent ?? 0));
  final note = TextEditingController(text: existing?.note ?? '');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fiyat listesi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad')),
          TextField(controller: discount, decoration: const InputDecoration(labelText: 'İskonto %'), keyboardType: TextInputType.number),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Not')),
        ],
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () {
              store.removePriceList(existing.id);
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
    store.upsertPriceList(PriceList(id: existing?.id ?? '', name: name.text.trim(), discountPercent: parseNum(discount.text) ?? 0, note: note.text.trim()));
  }
  name.dispose();
  discount.dispose();
  note.dispose();
}

Future<void> _editInstrument(BuildContext context) async {
  final store = StoreScope.of(context);
  final parties = store.parties.where((item) => item.active).toList();
  if (parties.isEmpty) return;
  var partyId = parties.first.id;
  var kind = InstrumentKind.check;
  var direction = InstrumentDirection.received;
  final no = TextEditingController();
  final bank = TextEditingController();
  final branch = TextEditingController();
  final issuer = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  var issue = DateTime.now();
  var due = DateTime.now().add(const Duration(days: 30));
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Çek / senet'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<InstrumentKind>(
                  value: kind,
                  items: const [
                    DropdownMenuItem(value: InstrumentKind.check, child: Text('Çek')),
                    DropdownMenuItem(value: InstrumentKind.promissory, child: Text('Senet')),
                  ],
                  onChanged: (value) => setLocal(() => kind = value ?? kind),
                ),
                DropdownButtonFormField<InstrumentDirection>(
                  value: direction,
                  items: const [
                    DropdownMenuItem(value: InstrumentDirection.received, child: Text('Alınan')),
                    DropdownMenuItem(value: InstrumentDirection.issued, child: Text('Verilen')),
                  ],
                  onChanged: (value) => setLocal(() => direction = value ?? direction),
                ),
                DropdownButtonFormField<String>(
                  value: partyId,
                  decoration: const InputDecoration(labelText: 'Cari'),
                  items: parties.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                  onChanged: (value) => setLocal(() => partyId = value ?? partyId),
                ),
                TextField(controller: no, decoration: const InputDecoration(labelText: 'Evrak no')),
                TextField(controller: amount, decoration: const InputDecoration(labelText: 'Tutar'), keyboardType: TextInputType.number),
                TextField(controller: bank, decoration: const InputDecoration(labelText: 'Banka')),
                TextField(controller: branch, decoration: const InputDecoration(labelText: 'Şube')),
                TextField(controller: issuer, decoration: const InputDecoration(labelText: 'Keşideci')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Vade ${shortDate(due)}'),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final picked = await pickDate(context, due);
                    if (picked != null) setLocal(() => due = picked);
                  },
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
  if (saved == true && context.mounted) {
    final message = store.addInstrument(
      Instrument(
        id: '',
        kind: kind,
        direction: direction,
        no: no.text.trim(),
        amount: parseNum(amount.text) ?? 0,
        issueDate: issue,
        dueDate: due,
        partyId: partyId,
        bank: bank.text.trim(),
        branch: branch.text.trim(),
        issuer: issuer.text.trim(),
        note: note.text.trim(),
      ),
    );
    showMessage(context, message ?? 'Evrak portföye alındı, cari güncellendi');
  }
  no.dispose();
  bank.dispose();
  branch.dispose();
  issuer.dispose();
  amount.dispose();
  note.dispose();
}
