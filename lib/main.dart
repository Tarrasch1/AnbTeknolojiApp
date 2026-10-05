import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/store.dart';
import 'src/ui/scope.dart';
import 'src/ui/shell.dart';
import 'src/ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WholesaleApp());
}

class WholesaleApp extends StatefulWidget {
  const WholesaleApp({super.key, this.store});

  final AppStore? store;

  @override
  State<WholesaleApp> createState() => _WholesaleAppState();
}

class _WholesaleAppState extends State<WholesaleApp> {
  late final AppStore _store = widget.store ?? AppStore();
  late final Future<void> _loading = _store.ensureLoaded();

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: _store,
      child: MaterialApp(
        title: 'Akım Elektrik',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FutureBuilder<void>(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Scaffold(body: Center(child: Text('Veri açılamadı: ${snapshot.error}')));
            }
            return const HomeShell();
          },
        ),
      ),
    );
  }
}
