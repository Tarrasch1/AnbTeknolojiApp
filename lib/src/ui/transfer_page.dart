import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../sheets.dart';
import '../transfer.dart';
import '../xlsx_sheet.dart';
import 'save_file_stub.dart' if (dart.library.html) 'save_file_web.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const PageIntro(
          inset: false,
          title: 'Excel aktarımı',
          hint: 'Her belge türünün kendi dosyası vardır. Excel .xlsx açar. LibreOffice ve benzeri programlar CSV dosyasını da açar.',
          icon: Icons.table_chart_outlined,
        ),
        for (final kind in TransferKind.values) ...[
          HoverCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.title, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 16)),
                const SizedBox(height: 4),
                Text(kind.hint, style: const TextStyle(color: kMuted, height: 1.35)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _export(context, kind, excel: true),
                      icon: const Icon(Icons.grid_on_outlined),
                      label: const Text('Excel indir'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _export(context, kind, excel: false),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('CSV indir'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _import(context, kind),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('İçe aktar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _export(BuildContext context, TransferKind kind, {required bool excel}) async {
    final table = buildTable(StoreScope.of(context), kind);
    final filename = '${kind.fileName}.${excel ? 'xlsx' : 'csv'}';
    if (excel) {
      await saveBytes(
        encodeXlsx(table),
        filename,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } else {
      await saveBytes(utf8.encode(encodeCsv(table)), filename, 'text/csv');
    }
    if (!context.mounted) return;
    showMessage(context, table.rows.isEmpty ? '$filename indirildi. İçinde başlık var, satır yok.' : '$filename indirildi.');
  }

  Future<void> _import(BuildContext context, TransferKind kind) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'txt'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || !context.mounted) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      showMessage(context, 'Dosya okunamadı');
      return;
    }
    final report = importBytes(StoreScope.of(context), kind, bytes, file.name);
    if (!context.mounted) return;
    showMessage(context, report.summary());
  }
}
