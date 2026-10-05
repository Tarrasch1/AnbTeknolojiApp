import 'package:flutter/material.dart';

import '../store.dart';

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({
    required AppStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope bulunamadı');
    return scope!.notifier!;
  }
}
