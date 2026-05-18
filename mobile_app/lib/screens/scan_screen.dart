import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/receipt_selection.dart';
import '../services/auth_service.dart';
import '../services/receipt_api_service.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/hover_lift_card.dart';
import '../widgets/language_switcher_button.dart';
import '../widgets/live_camera_capture_dialog_stub.dart'
    if (dart.library.html) '../widgets/live_camera_capture_dialog_web.dart';
import '../widgets/motion_reveal.dart';
import '../widgets/result_dialog.dart';
import '../widgets/scan_feedback_widgets.dart';
import 'login_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  bool _isProcessing = false;
  ReceiptSelection? _selectedFile;

  late final AnimationController _pulseController;
  late final AnimationController _fabController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fabScaleAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _pickCameraReceipt() async {
    final selection = kIsWeb
        ? await showLiveCameraCaptureDialog(context)
        : await ReceiptApiService.instance.capturePhoto();
    if (!mounted || selection == null) {
      return;
    }

    await _setSelectedFileAndSubmit(selection);
  }

  Future<void> _pickUploadReceipt() async {
    final selection = await ReceiptApiService.instance.pickReceiptFile();
    if (!mounted || selection == null) {
      return;
    }

    await _setSelectedFileAndSubmit(selection);
  }

  Future<void> _setSelectedFileAndSubmit(ReceiptSelection selection) async {
    if (!mounted) {
      return;
    }

    setState(() => _selectedFile = selection);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    await _submitSelectedFile();
  }

  Future<void> _submitSelectedFile() async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selectedFile = _selectedFile;
    if (selectedFile == null) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await ReceiptApiService.instance.scanReceipt(selectedFile);

      if (mounted) {
        final wasLoggedIn = AuthService.instance.isLoggedIn;
        await ResultDialog.show(context, result);
        if (mounted) {
          setState(() => _selectedFile = null);
        }
        if (mounted && wasLoggedIn) {
          _showStatusSnackBar(
            message: l10n.receiptScannedAndSaved,
            icon: Icons.check_circle_rounded,
            accentColor: theme.colorScheme.primary,
          );
        }
        if (mounted && !AuthService.instance.isLoggedIn) {
          AuthService.instance.pendingGuestReceipt = result.toJson();
          _showGuestNudge();
        }
      }
    } catch (e) {
      if (mounted) {
        _showStatusSnackBar(
          message: l10n.scanFailedTryAgain,
          icon: Icons.error_outline_rounded,
          accentColor: theme.colorScheme.error,
          actionLabel: l10n.retry,
          onAction: _submitSelectedFile,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showStatusSnackBar({
    required String message,
    required IconData icon,
    required Color accentColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 4),
          content: ScanStatusBanner(
            message: message,
            icon: icon,
            accentColor: accentColor,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      );
  }

  void _showGuestNudge() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.savings_rounded,
              color: theme.colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.saveAndTrackSpending,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.saveAndTrackSpendingBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.signUpFree),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.notNow,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reveal(
    int order,
    Widget child, {
    Offset beginOffset = const Offset(0, 0.08),
  }) {
    return MotionReveal(
      delay: Duration(milliseconds: 80 * order),
      beginOffset: beginOffset,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: theme.colorScheme.primary,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            l10n.poweredByGemini,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.end,
                      children: [
                        const LanguageSwitcherButton(compact: true),
                        AnimatedBuilder(
                          animation: AuthService.instance,
                          builder: (_, __) {
                            final isLoggedIn = AuthService.instance.isLoggedIn;
                            final overlayColor =
                                WidgetStateProperty.resolveWith<Color?>(
                              (states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return (isLoggedIn
                                          ? Colors.white
                                          : theme.colorScheme.primary)
                                      .withValues(alpha: 0.16);
                                }
                                if (states.contains(WidgetState.hovered)) {
                                  return (isLoggedIn
                                          ? Colors.white
                                          : theme.colorScheme.primary)
                                      .withValues(alpha: 0.1);
                                }
                                if (states.contains(WidgetState.focused)) {
                                  return (isLoggedIn
                                          ? Colors.white
                                          : theme.colorScheme.primary)
                                      .withValues(alpha: 0.08);
                                }
                                return Colors.transparent;
                              },
                            );

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                overlayColor: overlayColor,
                                onTap: () {
                                  if (!isLoggedIn) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  } else {
                                    AuthService.instance.logout();
                                  }
                                },
                                child: isLoggedIn
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: theme.colorScheme.surface,
                                          border: Border.all(
                                            color: theme
                                                .colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.logout_rounded,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.signOut,
                                              style: TextStyle(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.15),
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              color: theme.colorScheme.primary,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.signIn,
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _isProcessing
                      ? _buildLoadingState(theme, l10n)
                      : _buildIdleState(theme, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState(ThemeData theme, dynamic l10n) {
    final selectedFile = _selectedFile;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _reveal(
              0,
              Text(
                l10n.scanReceiptTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _reveal(
              1,
              Text(
                l10n.scanReceiptSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _reveal(
              2,
              HoverLiftCard(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                glowColor: theme.colorScheme.secondary,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.scanUploadOptions,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.supportedScanFormats,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _reveal(
              3,
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickCameraReceipt,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      kIsWeb
                          ? Icons.videocam_rounded
                          : Icons.camera_alt_rounded,
                    ),
                    label: Text(kIsWeb ? l10n.openCamera : l10n.takePhoto),
                  ),
                  FilledButton.icon(
                    onPressed: _pickUploadReceipt,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(l10n.uploadReceiptFile),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (selectedFile == null)
              _reveal(
                4,
                ScaleTransition(
                  scale: _fabScaleAnimation,
                  child: Text(
                    l10n.tapToScan,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else ...[
              _reveal(4, _buildSelectedFileCard(theme, l10n, selectedFile)),
              const SizedBox(height: 18),
              _reveal(
                5,
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickCameraReceipt,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        kIsWeb
                            ? Icons.videocam_rounded
                            : Icons.camera_alt_rounded,
                      ),
                      label: Text(kIsWeb ? l10n.openCamera : l10n.takePhoto),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickUploadReceipt,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.changeFile),
                    ),
                    FilledButton.icon(
                      onPressed: _submitSelectedFile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(l10n.analyzeSelectedFile),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard(
    ThemeData theme,
    dynamic l10n,
    ReceiptSelection file,
  ) {
    if (file.isPdf) {
      return HoverLiftCard(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        glowColor: theme.colorScheme.secondary,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primary,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pdfDocument,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      file.filename,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pdfReadyForAnalysis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HoverLiftCard(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      glowColor: theme.colorScheme.primary,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.selectedReceiptFile,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF38D39F),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Image.memory(
                  file.bytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              file.filename,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, dynamic l10n) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final normalizedPulse =
            ((_pulseAnimation.value - 0.85) / 0.15).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReceiptAnalysisLoadingCard(
              title: l10n.analyzingReceipt,
              subtitle: l10n.analyzingReceiptBody,
              pulseValue: normalizedPulse,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.outlineVariant,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
