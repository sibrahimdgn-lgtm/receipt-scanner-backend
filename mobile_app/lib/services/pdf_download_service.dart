import 'dart:typed_data';

import 'pdf_download_service_stub.dart'
    if (dart.library.html) 'pdf_download_service_web.dart' as impl;

Future<void> downloadPdfFile({
  required String filename,
  required Uint8List pdfBytes,
}) {
  return impl.downloadPdfFile(
    filename: filename,
    pdfBytes: pdfBytes,
  );
}
