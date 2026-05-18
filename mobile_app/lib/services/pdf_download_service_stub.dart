import 'dart:typed_data';

Future<void> downloadPdfFile({
  required String filename,
  required Uint8List pdfBytes,
}) async {
  throw UnsupportedError('PDF download is only supported on Flutter Web.');
}
