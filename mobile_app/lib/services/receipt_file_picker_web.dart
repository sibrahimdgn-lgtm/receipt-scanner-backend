import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../models/receipt_selection.dart';

Future<ReceiptSelection?> pickReceiptFileFromBrowser(
  List<String> allowedExtensions,
) {
  final completer = Completer<ReceiptSelection?>();
  final input = html.FileUploadInputElement()
    ..accept = allowedExtensions.map((ext) => '.${ext.toLowerCase()}').join(',')
    ..multiple = false
    ..style.display = 'none';

  bool completed = false;
  StreamSubscription<html.Event>? changeSub;
  StreamSubscription<html.Event>? focusSub;

  void finish(ReceiptSelection? selection) {
    if (completed) {
      return;
    }
    completed = true;
    changeSub?.cancel();
    focusSub?.cancel();
    input.remove();
    completer.complete(selection);
  }

  changeSub = input.onChange.listen((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      finish(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.listen((_) => finish(null));
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      Uint8List? bytes;

      if (result is ByteBuffer) {
        bytes = Uint8List.view(result);
      } else if (result is Uint8List) {
        bytes = result;
      } else if (result is List<int>) {
        bytes = Uint8List.fromList(result);
      }

      if (bytes == null || bytes.isEmpty) {
        finish(null);
        return;
      }

      finish(
        ReceiptSelection(
          bytes: bytes,
          filename: file.name,
          mimeType: _normalizeMimeType(file.type, file.name),
        ),
      );
    });
    reader.readAsArrayBuffer(file);
  });

  focusSub = html.window.onFocus.listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!completed && (input.files == null || input.files!.isEmpty)) {
        finish(null);
      }
    });
  });

  html.document.body?.append(input);
  input.click();

  return completer.future;
}

String _normalizeMimeType(String rawMimeType, String filename) {
  final mimeType = rawMimeType.trim().toLowerCase();
  if (mimeType == 'application/pdf') {
    return 'application/pdf';
  }
  if (mimeType == 'image/png') {
    return 'image/png';
  }
  if (mimeType == 'image/webp') {
    return 'image/webp';
  }
  if (mimeType == 'image/heic') {
    return 'image/heic';
  }
  if (mimeType == 'image/heif') {
    return 'image/heif';
  }
  if (mimeType == 'image/jpeg') {
    return 'image/jpeg';
  }

  final match = RegExp(r'\.([A-Za-z0-9]+)$').firstMatch(filename.trim());
  final ext = match?.group(1)?.toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}
