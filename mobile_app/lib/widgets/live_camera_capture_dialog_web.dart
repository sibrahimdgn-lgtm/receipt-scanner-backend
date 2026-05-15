import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/receipt_selection.dart';

Future<ReceiptSelection?> showLiveCameraCaptureDialog(
  BuildContext context,
) {
  return showModalBottomSheet<ReceiptSelection?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LiveCameraCaptureSheet(),
  );
}

enum _CameraSheetState {
  idle,
  requesting,
  ready,
  error,
}

enum _CameraFailure {
  denied,
  unavailable,
  unsupported,
}

class _LiveCameraCaptureSheet extends StatefulWidget {
  const _LiveCameraCaptureSheet();

  @override
  State<_LiveCameraCaptureSheet> createState() =>
      _LiveCameraCaptureSheetState();
}

class _LiveCameraCaptureSheetState extends State<_LiveCameraCaptureSheet> {
  late final String _viewType;
  late final html.VideoElement _videoElement;

  html.MediaStream? _stream;
  _CameraSheetState _state = _CameraSheetState.idle;
  _CameraFailure? _failure;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'receipt-live-camera-${DateTime.now().microsecondsSinceEpoch}';
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#0f111d'
      ..setAttribute('playsinline', 'true')
      ..setAttribute('aria-label', 'receipt-live-camera');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _videoElement,
    );
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  Future<void> _requestCameraAccess() async {
    if (_state == _CameraSheetState.requesting) {
      return;
    }

    setState(() {
      _state = _CameraSheetState.requesting;
      _failure = null;
    });

    try {
      await _startCamera();
      if (!mounted) {
        return;
      }
      setState(() => _state = _CameraSheetState.ready);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _CameraSheetState.error;
        _failure = _mapFailure(error);
      });
    }
  }

  Future<void> _startCamera() async {
    _stopStream();

    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw _CameraFailure.unsupported;
    }

    html.MediaStream stream;
    try {
      stream = await mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        },
      });
    } catch (_) {
      stream = await mediaDevices.getUserMedia({
        'audio': false,
        'video': true,
      });
    }

    _stream = stream;
    _videoElement.srcObject = stream;

    if (_videoElement.readyState < 2) {
      await _videoElement.onLoadedMetadata.first.timeout(
        const Duration(seconds: 8),
      );
    }

    await _videoElement.play();
  }

  Future<void> _captureReceipt() async {
    if (_capturing || _stream == null) {
      return;
    }

    setState(() => _capturing = true);

    try {
      final width =
          _videoElement.videoWidth > 0 ? _videoElement.videoWidth : 1280;
      final height =
          _videoElement.videoHeight > 0 ? _videoElement.videoHeight : 720;

      final canvas = html.CanvasElement(width: width, height: height);
      canvas.context2D.drawImageScaled(
        _videoElement,
        0,
        0,
        width.toDouble(),
        height.toDouble(),
      );

      final blob = await _canvasToBlob(canvas);
      if (blob == null) {
        throw _CameraFailure.unavailable;
      }

      final bytes = await _blobToBytes(blob);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        ReceiptSelection(
          bytes: bytes,
          filename:
              'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _CameraSheetState.error;
        _failure = _mapFailure(error);
        _capturing = false;
      });
    }
  }

  Future<html.Blob?> _canvasToBlob(html.CanvasElement canvas) {
    return canvas.toBlob('image/jpeg', 0.92);
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();

    reader.onError.listen((_) {
      completer.completeError(
        StateError('Could not read captured camera frame.'),
      );
    });

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
      } else if (result is Uint8List) {
        completer.complete(result);
      } else if (result is List<int>) {
        completer.complete(Uint8List.fromList(result));
      } else {
        completer.completeError(
          StateError('Unexpected camera frame payload.'),
        );
      }
    });

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  void _stopStream() {
    final stream = _stream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    _stream = null;
    _videoElement.srcObject = null;
  }

  _CameraFailure _mapFailure(Object error) {
    if (error is _CameraFailure) {
      return error;
    }

    final raw = error.toString();
    if (raw.contains('NotAllowedError') ||
        raw.contains('PermissionDeniedError') ||
        raw.contains('permission denied')) {
      return _CameraFailure.denied;
    }
    if (raw.contains('NotFoundError') ||
        raw.contains('NotReadableError') ||
        raw.contains('OverconstrainedError') ||
        raw.contains('AbortError')) {
      return _CameraFailure.unavailable;
    }
    if (raw.contains('TypeError') || raw.contains('unsupported')) {
      return _CameraFailure.unsupported;
    }
    return _CameraFailure.unavailable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: _buildBody(context, theme, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, dynamic l10n) {
    switch (_state) {
      case _CameraSheetState.ready:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cameraPreviewTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cameraPreviewBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HtmlElementView(viewType: _viewType),
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.8,
                            ),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _capturing ? null : _captureReceipt,
                    icon: _capturing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_rounded),
                    label: Text(l10n.captureReceiptPhoto),
                  ),
                ),
              ],
            ),
          ],
        );
      case _CameraSheetState.requesting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              l10n.cameraStarting,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case _CameraSheetState.error:
      case _CameraSheetState.idle:
        final isError = _state == _CameraSheetState.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
              ),
              child: Icon(
                isError ? Icons.camera_alt_outlined : Icons.videocam_rounded,
                color: theme.colorScheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.cameraAccessTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isError ? _failureMessage(l10n) : l10n.cameraAccessBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _requestCameraAccess,
                icon: Icon(
                  isError ? Icons.refresh_rounded : Icons.videocam_rounded,
                ),
                label: Text(
                  isError ? l10n.retry : l10n.allowCameraAccess,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
    }
  }

  String _failureMessage(dynamic l10n) {
    switch (_failure) {
      case _CameraFailure.denied:
        return l10n.cameraPermissionDenied;
      case _CameraFailure.unsupported:
        return l10n.cameraUnsupported;
      case _CameraFailure.unavailable:
      case null:
        return l10n.cameraUnavailable;
    }
  }
}
