import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/models/receipt_selection.dart';
import 'package:receipt_scanner_app/services/receipt_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptApiService.prepareUploadPayload', () {
    test('web falls back to original PNG bytes when image compression fails',
        () async {
      final originalBytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3, 4]);
      final file = ReceiptSelection(
        bytes: originalBytes,
        filename: 'screenshot.png',
        mimeType: 'image/png',
      );

      final prepared = await ReceiptApiService.instance.prepareUploadPayload(
        file,
        isWebOverride: true,
        webCompressor: (_) async =>
            throw const FormatException('decode failed'),
      );

      expect(prepared.bytes, originalBytes);
      expect(prepared.filename, 'receipt.png');
      expect(prepared.mimeType, 'image/png');
    });

    test('web keeps compressed jpeg filename when image compression succeeds',
        () async {
      final originalBytes = Uint8List.fromList([1, 2, 3, 4]);
      final compressedBytes = Uint8List.fromList([9, 8, 7]);
      final file = ReceiptSelection(
        bytes: originalBytes,
        filename: 'photo.png',
        mimeType: 'image/png',
      );

      final prepared = await ReceiptApiService.instance.prepareUploadPayload(
        file,
        isWebOverride: true,
        webCompressor: (_) async => compressedBytes,
      );

      expect(prepared.bytes, compressedBytes);
      expect(prepared.filename, 'receipt.jpg');
      expect(prepared.mimeType, 'image/jpeg');
    });

    test('pdf uploads bypass image compression and keep pdf filename',
        () async {
      final originalBytes = Uint8List.fromList([37, 80, 68, 70, 45]);
      final file = ReceiptSelection(
        bytes: originalBytes,
        filename: 'invoice.pdf',
        mimeType: 'application/pdf',
      );

      final prepared = await ReceiptApiService.instance.prepareUploadPayload(
        file,
        isWebOverride: true,
      );

      expect(prepared.bytes, originalBytes);
      expect(prepared.filename, 'receipt.pdf');
      expect(prepared.mimeType, 'application/pdf');
    });
  });

  group('ReceiptApiService.pickReceiptFile', () {
    test('web path can use browser picker override without file_picker plugin',
        () async {
      final selection = ReceiptSelection(
        bytes: Uint8List.fromList([37, 80, 68, 70]),
        filename: 'invoice.pdf',
        mimeType: 'application/pdf',
      );

      final picked = await ReceiptApiService.instance.pickReceiptFile(
        isWebOverride: true,
        webPickerOverride: (_) async => selection,
      );

      expect(picked, isNotNull);
      expect(picked!.filename, 'invoice.pdf');
      expect(picked.mimeType, 'application/pdf');
    });
  });
}
