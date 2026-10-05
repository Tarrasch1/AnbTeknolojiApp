// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<void> launchPrint(String htmlText) async {
  final blob = html.Blob([htmlText], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
