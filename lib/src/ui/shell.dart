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
  var _extended = true;
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
    final palette = context.palette;
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
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: () => ThemeScope.of(context).toggle(),
            icon: Icon(ThemeScope.of(context).isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Koyu zemin',
          ),
          IconButton(onPressed: () => _openSearch(context), icon: const Icon(Icons.search), tooltip: 'Ara'),
          const SizedBox(width: 4),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: palette.sidebar,
              child: _sidebar(store.profile.shortName, palette, extended: true, showCollapse: false, closeDrawer: true),
            ),
      body: Row(
        children: [
          if (wide) _sidebar(store.profile.shortName, palette, extended: _extended, showCollapse: true, closeDrawer: false),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
    );
  }

  Widget _sidebar(
    String shortName,
    AppPalette palette, {
    required bool extended,
    required bool showCollapse,
    required bool closeDrawer,
  }) {
    return ColoredBox(
      color: palette.sidebar,
      child: SafeArea(
        child: SizedBox(
          width: extended ? 248 : 76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(extended ? 16 : 12, 16, 12, 12),
                child: Row(
                  children: [
                    const MarkBadge(label: 'AK', color: kAccent, icon: Icons.bolt, size: 40),
                    if (extended) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shortName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            const Text('Toptan panel', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    for (var i = 0; i < _titles.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _NavButton(
                          icon: _icons[i],
                          label: _titles[i],
                          selected: _index == i,
                          extended: extended,
                          palette: palette,
                          onTap: () {
                            setState(() => _index = i);
                            if (closeDrawer) Navigator.pop(context);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (showCollapse)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                  child: _NavButton(
                    icon: extended ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right,
                    label: extended ? 'Daralt' : '',
                    selected: false,
                    extended: extended,
                    palette: palette,
                    onTap: () => setState(() => _extended = !_extended),
                  ),
                ),
            ],
          ),
        ),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool extended;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : palette.sidebarMuted;
    final button = Material(
      color: selected ? palette.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0, vertical: 10),
          child: Row(
            mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : color, size: 20),
              if (extended && label.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: selected ? Colors.white : palette.onSidebar, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (extended || label.isEmpty) return button;
    return Tooltip(message: label, child: button);
  }
}
