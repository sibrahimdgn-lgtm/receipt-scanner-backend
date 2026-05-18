import 'package:flutter/material.dart';

class ReceiptAnalysisLoadingCard extends StatelessWidget {
  const ReceiptAnalysisLoadingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pulseValue,
  });

  final String title;
  final String subtitle;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = Color.lerp(
      theme.colorScheme.outlineVariant,
      theme.colorScheme.primary.withValues(alpha: 0.18),
      pulseValue.clamp(0, 1),
    )!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonPill(
                            key: const ValueKey('scan-loading-header'),
                            width: 160,
                            height: 14,
                            color: highlight,
                          ),
                          const SizedBox(height: 10),
                          _SkeletonPill(
                            width: double.infinity,
                            height: 12,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SkeletonPill(
                              width: double.infinity,
                              height: 12,
                              color: highlight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _SkeletonPill(
                            width: 72,
                            height: 12,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _SkeletonPill(
                              width: double.infinity,
                              height: 12,
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _SkeletonPill(
                            width: 88,
                            height: 12,
                            color: highlight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _SkeletonPill(
                              width: double.infinity,
                              height: 12,
                              color: highlight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _SkeletonPill(
                            width: 56,
                            height: 12,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanStatusBanner extends StatelessWidget {
  const ScanStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onAction,
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPill extends StatelessWidget {
  const _SkeletonPill({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: ColoredBox(
          color: color,
          child: SizedBox(height: height),
        ),
      ),
    );
  }
}
