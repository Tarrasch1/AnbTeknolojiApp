import 'models.dart';

class CityFirmSale {
  const CityFirmSale(this.party, this.sales);

  final Party party;
  final double sales;
}

class CitySales {
  const CitySales({required this.key, required this.sales, required this.firms});

  final String key;
  final double sales;
  final List<CityFirmSale> firms;

  double percentOf(double total) {
    if (total.abs() < 0.009) return 0;
    return sales / total * 100;
  }
}

String foldCity(String raw) {
  final folded = raw
      .trim()
      .toLowerCase()
      .replaceAll('\u0307', '')
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  const aliases = {
    'afyon': 'afyonkarahisar',
    'kmaras': 'kahramanmaras',
    'maras': 'kahramanmaras',
    'urfa': 'sanliurfa',
    'icel': 'mersin',
    'kinkkale': 'kirikkale',
    'zinguldak': 'zonguldak',
  };
  return aliases[folded] ?? folded;
}

String percentLabel(double value) {
  final negative = value < 0;
  final figure = value.abs().toStringAsFixed(1).replaceAll('.', ',');
  return '${negative ? '-' : ''}%$figure';
}

String cityShareSentence(String city, String amount, double share) {
  final figure = share.abs().toStringAsFixed(1).replaceAll('.', ',');
  final sign = share < 0 ? 'eksi ' : '';
  return '$city satışı $amount. Bu tutar, firmanın toplam satışının $sign yüzde $figure kadarını oluşturuyor.';
}
