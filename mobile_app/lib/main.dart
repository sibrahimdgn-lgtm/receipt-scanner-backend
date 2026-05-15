import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_languages.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scan_screen.dart';
import 'services/app_startup_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firebase_web_plugin_registrant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReceiptScannerApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrapRuntime());
  });
}

Future<void> _bootstrapRuntime() async {
  await _initializeFirebaseFromMain();
  await AppStartupService.bootstrap();
}

Future<void> _initializeFirebaseFromMain() async {
  try {
    ensureFirebaseWebPluginsRegistered();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    FirebaseBootstrap.markReady();
    developer.log(
      'Firebase initialized for project ${DefaultFirebaseOptions.currentPlatform.projectId}.',
      name: 'ReceiptScanner.Firebase',
    );
  } catch (error, stackTrace) {
    FirebaseBootstrap.recordInitializationFailure(
      error,
      stackTrace,
      context: 'main',
    );
  }
}

class ReceiptScannerApp extends StatelessWidget {
  const ReceiptScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (_, __) => MaterialApp(
        title: 'Receipt Scanner',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(AuthService.instance.locale),
        themeMode: ThemeMode.light,
        locale: AuthService.instance.locale,
        supportedLocales: AppLanguages.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainShell(),
      ),
    );
  }

  ThemeData _buildTheme(Locale locale) {
    const primaryColor = Color(0xFF00B4CE);
    const secondaryColor = Color(0xFF1487B8);
    const tertiaryColor = Color(0xFF86DDF8);
    const surfaceColor = Color(0xFFFFFFFF);
    const surfaceAltColor = Color(0xFFF7F9FC);
    const bgColor = Color(0xFFF4F5F8);
    const textColor = Color(0xFF163247);
    const mutedTextColor = Color(0xFF5E7386);
    const outlineColor = Color(0xFFD7E3EC);
    const outlineVariantColor = Color(0xFFE6EEF5);
    const errorColor = Color(0xFFD64545);

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      onSurface: textColor,
      onSurfaceVariant: mutedTextColor,
      outline: outlineColor,
      outlineVariant: outlineVariantColor,
      error: errorColor,
      onError: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      shadow: const Color(0x12163247),
      scrim: const Color(0x26163247),
      inverseSurface: const Color(0xFF163247),
      onInverseSurface: Colors.white,
    );

    final baseTextTheme = ThemeData.light().textTheme;
    final localizedTextTheme = locale.languageCode == 'ar'
        ? GoogleFonts.notoNaskhArabicTextTheme(baseTextTheme)
        : GoogleFonts.interTextTheme(baseTextTheme);
    final textTheme = localizedTextTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
      decorationColor: textColor,
    );

    WidgetStateProperty<Color?> interactionOverlay(
      Color color, {
      double hoverAlpha = 0.08,
      double pressedAlpha = 0.12,
      double focusedAlpha = 0.06,
    }) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return color.withValues(alpha: pressedAlpha);
        }
        if (states.contains(WidgetState.focused)) {
          return color.withValues(alpha: focusedAlpha);
        }
        if (states.contains(WidgetState.hovered)) {
          return color.withValues(alpha: hoverAlpha);
        }
        return Colors.transparent;
      });
    }

    return ThemeData.light().copyWith(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      canvasColor: surfaceAltColor,
      cardColor: surfaceColor,
      dividerColor: outlineVariantColor,
      shadowColor: colorScheme.shadow,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: mutedTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: const TextStyle(color: mutedTextColor),
        hintStyle: const TextStyle(color: Color(0xFF8AA0B6)),
        prefixIconColor: mutedTextColor,
        suffixIconColor: mutedTextColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: locale.languageCode == 'ar'
              ? GoogleFonts.notoNaskhArabic(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                )
              : GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ).copyWith(
          overlayColor: interactionOverlay(
            Colors.white,
            hoverAlpha: 0.08,
            pressedAlpha: 0.16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(textColor),
          backgroundColor: WidgetStateProperty.all(surfaceColor),
          side: WidgetStateProperty.all(
            const BorderSide(color: outlineColor),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(primaryColor),
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(mutedTextColor),
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            const BorderSide(color: outlineColor),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return surfaceColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return mutedTextColor;
          }),
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: isSelected ? textColor : mutedTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? primaryColor : mutedTextColor,
          );
        }),
        indicatorColor: primaryColor.withValues(alpha: 0.14),
        overlayColor: interactionOverlay(
          primaryColor,
          hoverAlpha: 0.1,
          pressedAlpha: 0.14,
          focusedAlpha: 0.08,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outlineVariantColor),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: textColor),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  late final AnimationController _tabTransitionController;
  late final Animation<double> _tabFadeAnimation;
  late final Animation<Offset> _tabSlideAnimation;

  static const _screens = [
    ScanScreen(),
    DashboardScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();

    _tabFadeAnimation = CurvedAnimation(
      parent: _tabTransitionController,
      curve: Curves.easeOutCubic,
    );

    _tabSlideAnimation = Tween<Offset>(
      begin: const Offset(0.012, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tabTransitionController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _tabTransitionController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != 0 && !AuthService.instance.isLoggedIn) {
      _showSignUpSheet();
      return;
    }
    if (index == _index) {
      return;
    }

    setState(() => _index = index);
    _tabTransitionController.forward(from: 0);
  }

  void _showSignUpSheet() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.trackYourSpending,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trackYourSpendingBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.signUpSignIn),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.maybeLater,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (_, __) => Scaffold(
        body: ClipRect(
          child: FadeTransition(
            opacity: _tabFadeAnimation,
            child: SlideTransition(
              position: _tabSlideAnimation,
              child: IndexedStack(
                index: _index,
                children: _screens,
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavButton(
                    label: l10n.navScan,
                    selected: _index == 0,
                    onTap: () => _onTabTapped(0),
                    icon: const Icon(Icons.camera_alt_outlined),
                    selectedIcon: const Icon(Icons.camera_alt_rounded),
                  ),
                  _BottomNavButton(
                    label: l10n.navDashboard,
                    selected: _index == 1,
                    onTap: () => _onTabTapped(1),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.bar_chart_outlined),
                        if (!AuthService.instance.isLoggedIn)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Icon(
                              Icons.lock,
                              size: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    selectedIcon: const Icon(Icons.bar_chart_rounded),
                  ),
                  _BottomNavButton(
                    label: l10n.navHistory,
                    selected: _index == 2,
                    onTap: () => _onTabTapped(2),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.receipt_long_outlined),
                        if (!AuthService.instance.isLoggedIn)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Icon(
                              Icons.lock,
                              size: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    selectedIcon: const Icon(Icons.receipt_long_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget icon;
  final Widget selectedIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  child: selected ? selectedIcon : icon,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
