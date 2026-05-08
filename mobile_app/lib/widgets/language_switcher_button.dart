import 'package:flutter/material.dart';

import '../config/app_languages.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({
    super.key,
    this.compact = false,
    this.margin,
  });

  final bool compact;
  final EdgeInsetsGeometry? margin;

  Future<void> _changeLanguage(BuildContext context, String code) async {
    final l10n = context.l10n;
    try {
      await AuthService.instance.updatePreferredLanguage(code);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.languageUpdated)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.languageUpdateFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = AuthService.instance.preferredLanguageCode;
    final overlayColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return theme.colorScheme.primary.withValues(alpha: 0.16);
      }
      if (states.contains(WidgetState.hovered)) {
        return theme.colorScheme.primary.withValues(alpha: 0.1);
      }
      if (states.contains(WidgetState.focused)) {
        return theme.colorScheme.primary.withValues(alpha: 0.08);
      }
      return Colors.transparent;
    });

    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (_, __) => PopupMenuButton<String>(
        tooltip: context.l10n.language,
        padding: EdgeInsets.zero,
        color: const Color(0xFF1A1A2E),
        style: ButtonStyle(
          overlayColor: overlayColor,
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        onSelected: (value) => _changeLanguage(context, value),
        child: Container(
          margin: margin,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLanguages.flagOf(code),
                style: const TextStyle(fontSize: 16),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  code.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_more_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ),
        ),
        itemBuilder: (_) => AppLanguages.supportedCodes.map(
          (menuCode) {
            final isSelected =
                AuthService.instance.preferredLanguageCode == menuCode;

            return PopupMenuItem<String>(
              value: menuCode,
              child: Container(
                constraints: const BoxConstraints(minWidth: 220),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        AppLanguages.flagOf(menuCode),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _languageMenuLabel(context, menuCode),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  String _languageMenuLabel(BuildContext context, String code) {
    final localized = _languageLabel(context, code);
    final native = AppLanguages.nativeNameOf(code);
    if (localized == native) {
      return localized;
    }
    return '$localized · $native';
  }

  String _languageLabel(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'ar':
        return l10n.arabic;
      case 'en':
        return l10n.english;
      case 'de':
        return l10n.german;
      default:
        return l10n.turkish;
    }
  }
}
