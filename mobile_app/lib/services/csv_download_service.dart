import 'csv_download_service_stub.dart'
    if (dart.library.html) 'csv_download_service_web.dart' as impl;

Future<void> downloadCsvFile({
  required String filename,
  required String csvContent,
}) {
  return impl.downloadCsvFile(
    filename: filename,
    csvContent: csvContent,
  );
}
