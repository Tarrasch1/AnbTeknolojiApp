import 'cities.dart';

class SheetTable {
  const SheetTable(this.headers, this.rows);

  final List<String> headers;
  final List<List<String>> rows;

  factory SheetTable.parse(String csv) {
    final parsed = parseCsv(csv);
    if (parsed.isEmpty) return const SheetTable([], []);
    return SheetTable(parsed.first, parsed.skip(1).toList());
  }
}

String sheetNum(num value) {
  if ((value - value.round()).abs() < 0.0001) return value.round().toString();
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String encodeCsv(SheetTable table) {
  final buffer = StringBuffer('\uFEFF');
  buffer.writeln(table.headers.map(_escape).join(';'));
  for (final row in table.rows) {
    buffer.writeln(row.map(_escape).join(';'));
  }
  return buffer.toString();
}

String _escape(String value) {
  if (value.contains(';') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

List<List<String>> parseCsv(String input) {
  var text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  if (text.trim().isEmpty) return [];
  final delimiter = _delimiter(text.split('\n').first);
  final rows = <List<String>>[];
  final row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
      continue;
    }
    if (char == '"') {
      quoted = true;
    } else if (char == delimiter) {
      row.add(cell.toString());
      cell.clear();
    } else if (char == '\n') {
      row.add(cell.toString());
      cell.clear();
      if (row.any((item) => item.trim().isNotEmpty)) rows.add(List<String>.from(row));
      row.clear();
    } else {
      cell.write(char);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    if (row.any((item) => item.trim().isNotEmpty)) rows.add(List<String>.from(row));
  }
  return rows;
}

String _delimiter(String header) {
  final semi = ';'.allMatches(header).length;
  final comma = ','.allMatches(header).length;
  return semi >= comma ? ';' : ',';
}

String headerKey(String header) => foldCity(header);
