import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadPdfFile({
  required String filename,
  required Uint8List pdfBytes,
}) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
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
