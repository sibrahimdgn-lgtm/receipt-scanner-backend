import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/receipt_selection.dart';
import '../models/scan_result.dart';
import 'receipt_file_picker_stub.dart'
    if (dart.library.html) 'receipt_file_picker_web.dart' as browser_picker;
import 'auth_service.dart';

class PreparedReceiptUpload {
  const PreparedReceiptUpload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

class ReceiptApiService {
  ReceiptApiService._();
  static final ReceiptApiService instance = ReceiptApiService._();

  static const List<String> _allowedUploadExtensions = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
  ];

  final ImagePicker _picker = ImagePicker();

  Future<ReceiptSelection?> capturePhoto({
    bool? isWebOverride,
    Future<ReceiptSelection?> Function(List<String> allowedExtensions)?
        webPickerOverride,
    Future<XFile?> Function()? cameraPickerOverride,
  }) async {
    final runningOnWeb = isWebOverride ?? kIsWeb;
    if (runningOnWeb) {
      return pickReceiptFile(
        isWebOverride: true,
        webPickerOverride: webPickerOverride,
      );
    }

    final photo = cameraPickerOverride != null
        ? await cameraPickerOverride()
        : await _picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear,
          );

    return _selectionFromXFile(photo);
  }

  Future<ReceiptSelection?> pickReceiptFile({
    bool? isWebOverride,
    Future<ReceiptSelection?> Function(List<String> allowedExtensions)?
        webPickerOverride,
    Future<FilePickerResult?> Function(List<String> allowedExtensions)?
        nativePickerOverride,
  }) async {
    final runningOnWeb = isWebOverride ?? kIsWeb;
    if (runningOnWeb) {
      if (webPickerOverride != null) {
        return webPickerOverride(_allowedUploadExtensions);
      }
      return browser_picker.pickReceiptFileFromBrowser(
        _allowedUploadExtensions,
      );
    }

    final result = nativePickerOverride != null
        ? await nativePickerOverride(_allowedUploadExtensions)
        : await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: _allowedUploadExtensions,
            withData: true,
          );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;
    final filename = _normalizeFilename(
      picked.name.isNotEmpty ? picked.name : 'receipt.jpg',
    );
    final mimeType = _normalizeMimeType(null, filename);

    if (picked.bytes != null) {
      return ReceiptSelection(
        bytes: Uint8List.fromList(picked.bytes!),
        filename: filename,
        mimeType: mimeType,
      );
    }

    if (picked.path != null && picked.path!.isNotEmpty) {
      return _selectionFromXFile(
        XFile(picked.path!),
        fallbackFilename: filename,
        fallbackMimeType: mimeType,
      );
    }

    return null;
  }

  Future<ScanResult> scanReceipt(ReceiptSelection file) async {
    final prepared = await prepareUploadPayload(file);
    final uri = Uri.parse(AppConfig.scanEndpoint);

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(
        await AuthService.instance.requestHeadersAsync(includeAuth: true),
      )
      ..files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          prepared.bytes,
          filename: prepared.filename,
          contentType: MediaType.parse(prepared.mimeType),
        ),
      );

    dev.log('[Upload] Sending to ${AppConfig.scanEndpoint}...');

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
        );

    final response = await http.Response.fromStream(streamedResponse);

    dev.log('[Upload] Status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ScanResult.fromJson(body);
    }

    String errorMessage = 'Server returned status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = body['error']?.toString() ?? errorMessage;
    } catch (_) {}

    throw Exception(errorMessage);
  }

  @visibleForTesting
  Future<PreparedReceiptUpload> prepareUploadPayload(
    ReceiptSelection file, {
    bool? isWebOverride,
    Future<List<int>> Function(Uint8List originalBytes)? webCompressor,
  }) async {
    final originalBytes = file.bytes;
    final originalSize = originalBytes.length;
    final runningOnWeb = isWebOverride ?? kIsWeb;

    dev.log(
      '[Compress] Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB',
    );

    if (file.isPdf) {
      return PreparedReceiptUpload(
        bytes: Uint8List.fromList(originalBytes),
        filename: _normalizedUploadFilename(file.filename, file.mimeType),
        mimeType: 'application/pdf',
      );
    }

    Uint8List uploadBytes;
    String uploadFilename = 'receipt.jpg';
    var uploadMimeType = 'image/jpeg';

    if (runningOnWeb) {
      try {
        final compressor = webCompressor ??
            (Uint8List bytes) => FlutterImageCompress.compressWithList(
                  bytes,
                  quality: AppConfig.compressQuality,
                  minWidth: AppConfig.compressMinWidth,
                  minHeight: AppConfig.compressMinHeight,
                );
        final result = await compressor(originalBytes);

        if (result.isEmpty) {
          throw const FormatException('Compression returned empty bytes.');
        }

        uploadBytes = Uint8List.fromList(result);
      } catch (e, st) {
        dev.log(
          '[Compress] Web compression failed, uploading original file instead: $e',
          stackTrace: st,
        );
        uploadBytes = Uint8List.fromList(originalBytes);
        uploadFilename =
            _normalizedUploadFilename(file.filename, file.mimeType);
        uploadMimeType = _normalizeMimeType(file.mimeType, file.filename);
      }
    } else {
      final result = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: AppConfig.compressQuality,
        minWidth: AppConfig.compressMinWidth,
        minHeight: AppConfig.compressMinHeight,
      );
      uploadBytes = Uint8List.fromList(result);
    }

    final ratio = originalSize == 0
        ? '0.0'
        : ((1 - uploadBytes.length / originalSize) * 100).toStringAsFixed(1);
    dev.log(
      '[Compress] Upload size: ${(uploadBytes.length / 1024).toStringAsFixed(1)} KB '
      '(reduced by $ratio%)',
    );

    return PreparedReceiptUpload(
      bytes: uploadBytes,
      filename: uploadFilename,
      mimeType: uploadMimeType,
    );
  }

  Future<ReceiptSelection?> _selectionFromXFile(
    XFile? file, {
    String? fallbackFilename,
    String? fallbackMimeType,
  }) async {
    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final filename = _normalizeFilename(
      file.name.isNotEmpty ? file.name : (fallbackFilename ?? 'receipt.jpg'),
    );
    final mimeType = _normalizeMimeType(
      file.mimeType ?? fallbackMimeType,
      filename,
    );

    return ReceiptSelection(
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      mimeType: mimeType,
    );
  }

  String _normalizeFilename(String rawName) {
    final trimmed = rawName.trim();
    return trimmed.isEmpty ? 'receipt.jpg' : trimmed;
  }

  String _normalizeMimeType(String? rawMimeType, String filename) {
    final mimeType = rawMimeType?.trim().toLowerCase();
    if (mimeType == 'application/pdf') {
      return 'application/pdf';
    }
    if (mimeType == 'image/jpeg') {
      return 'image/jpeg';
    }
    if (mimeType == 'image/png') {
      return 'image/png';
    }
    if (mimeType == 'image/webp') {
      return 'image/webp';
    }

    final ext = _fileExtension(filename);
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _normalizedUploadFilename(String rawName, String mimeType) {
    final ext = _fileExtension(rawName);
    if (ext == 'pdf') {
      return 'receipt.pdf';
    }
    if (ext == 'png') {
      return 'receipt.png';
    }
    if (ext == 'jpg' || ext == 'jpeg') {
      return 'receipt.$ext';
    }
    if (mimeType == 'application/pdf') {
      return 'receipt.pdf';
    }
    if (mimeType == 'image/png') {
      return 'receipt.png';
    }
    return 'receipt.jpg';
  }

  String _fileExtension(String filename) {
    final match = RegExp(r'\.([A-Za-z0-9]+)$').firstMatch(filename.trim());
    return match?.group(1)?.toLowerCase() ?? '';
  }
}
