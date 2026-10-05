import 'package:flutter/material.dart';

import '../models.dart';
import 'dashboard.dart';
import 'docs_page.dart';
import 'finance_page.dart';
import 'map_page.dart';
import 'party_page.dart';
import 'reports_page.dart';
import 'scope.dart';
import 'service_page.dart';
import 'settings_page.dart';
import 'stock_page.dart';
import 'transfer_page.dart';
import 'cards.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _search = TextEditingController();

  static const _titles = [
    'Özet',
    'Stok',
    'Cariler',
    'Belgeler',
    'Finans',
    'Servis',
    'Harita',
    'Aktarım',
    'Raporlar',
    'Ayarlar',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.groups_outlined,
    Icons.receipt_long_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.build_outlined,
    Icons.map_outlined,
    Icons.swap_vert,
    Icons.insights_outlined,
    Icons.settings_outlined,
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1080;
    const pages = [
      DashboardPage(),
      StockPage(),
      PartyPage(),
      DocsPage(),
      FinancePage(),
      ServicePage(),
      MapPage(),
      TransferPage(),
      ReportsPage(),
      SettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const MarkBadge(label: 'AK', color: kNavy, icon: Icons.bolt, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Text('${store.profile.shortName} · ${_titles[_index]}')),
          ],
        ),
        actions: [
          IconButton(onPressed: () => _openSearch(context), icon: const Icon(Icons.search), tooltip: 'Ara'),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(color: kNavy),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text('Akım Elektrik', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    for (var i = 0; i < _titles.length; i++)
                      ListTile(
                        leading: Icon(_icons[i]),
                        title: Text(_titles[i]),
                        selected: _index == i,
                        onTap: () {
                          setState(() => _index = i);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: kLine)),
              ),
              child: SizedBox(
                width: 220,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            extended: true,
                            minExtendedWidth: 220,
                            selectedIndex: _index,
                            onDestinationSelected: (value) => setState(() => _index = value),
                            leading: const Padding(
                              padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                              child: Row(
                                children: [
                                  MarkBadge(label: 'AK', color: kNavy, icon: Icons.bolt, size: 40),
                                  SizedBox(width: 10),
                                  Text('AKIM', style: TextStyle(color: kNavy, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                ],
                              ),
                            ),
                            destinations: [
                              for (var i = 0; i < _titles.length; i++)
                                NavigationRailDestination(icon: Icon(_icons[i]), label: Text(_titles[i])),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    _search.clear();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          final hits = StoreScope.of(context).search(_search.text);
          return AlertDialog(
            title: const Text('Ara'),
            content: SizedBox(
              width: 480,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Ürün, cari, belge no, seri'),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  Expanded(
                    child: ListView(
                      children: hits.map((hit) {
                        return ListTile(
                          title: Text(hit.title),
                          subtitle: Text(hit.subtitle),
                          onTap: () {
                            Navigator.pop(context);
                            _openHit(hit);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openHit(SearchHit hit) {
    final Widget page;
    switch (hit.kind) {
      case 'product':
        page = ProductDetailPage(productId: hit.id);
      case 'party':
        page = PartyDetailPage(partyId: hit.id);
      case 'doc':
        page = DocDetailPage(docId: hit.id);
      case 'serial':
        setState(() => _index = 5);
        return;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
