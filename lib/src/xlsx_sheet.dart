import 'package:excel/excel.dart';

import 'format.dart';
import 'sheets.dart';

const _numericHeaders = {
  'miktar',
  'birimfiyat',
  'iskonto',
  'kdv',
  'alisfiyati',
  'satisfiyati',
  'minstok',
  'garantiay',
  'tutar',
  'risklimiti',
  'vadegun',
  'watt',
  'desi',
};

List<int> encodeXlsx(SheetTable table) {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  sheet.appendRow([for (final header in table.headers) TextCellValue(header)]);
  for (final row in table.rows) {
    sheet.appendRow([
      for (var i = 0; i < table.headers.length; i++)
        _cell(table.headers[i], i < row.length ? row[i] : ''),
    ]);
  }
  final bytes = excel.encode();
  if (bytes == null) throw StateError('Excel dosyası yazılamadı');
  return bytes;
}

CellValue _cell(String header, String raw) {
  if (_numericHeaders.contains(headerKey(header))) {
    final number = _looseNum(raw);
    if (number != null) {
      if ((number - number.round()).abs() < 0.0001) return IntCellValue(number.round());
      return DoubleCellValue(number);
    }
  }
  return TextCellValue(raw);
}

double? _looseNum(String raw) {
  final text = raw.trim().replaceAll(' ', '').replaceAll('₺', '');
  if (text.isEmpty) return null;
  var normalized = text;
  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '.');
  }
  return double.tryParse(normalized);
}

SheetTable decodeXlsx(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  for (final sheet in excel.tables.values) {
    if (sheet.rows.isEmpty) continue;
    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      final values = [for (final cell in row) _text(cell?.value)];
      if (values.any((item) => item.trim().isNotEmpty)) rows.add(values);
    }
    if (rows.isEmpty) continue;
    final width = rows.first.length;
    return SheetTable(
      rows.first,
      [
        for (final row in rows.skip(1))
          [
            for (var i = 0; i < width; i++) i < row.length ? row[i] : '',
          ],
      ],
    );
  }
  return const SheetTable([], []);
}

String _text(CellValue? value) {
  if (value == null) return '';
  return switch (value) {
    TextCellValue cell => cell.value.toString(),
    IntCellValue(:final value) => '$value',
    DoubleCellValue(:final value) => value.toString(),
    BoolCellValue(:final value) => value ? 'Evet' : 'Hayır',
    DateCellValue cell => shortDate(cell.asDateTimeLocal()),
    DateTimeCellValue cell => shortDate(cell.asDateTimeLocal()),
    FormulaCellValue(:final formula) => formula,
    TimeCellValue cell => cell.toString(),
  };
}
