import 'dart:convert';
import 'dart:html' as html;

Future<void> downloadCsvFile({
  required String filename,
  required String csvContent,
}) async {
  final bytes = utf8.encode('\uFEFF$csvContent');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
