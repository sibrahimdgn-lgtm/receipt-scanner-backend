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
    const primaryColor = Color(0xFF00BFA6);
    const secondaryColor = Color(0xFF6C63FF);
    const surfaceColor = Color(0xFF1E1E2C);
    const bgColor = Color(0xFF13131D);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onSurface: Colors.white,
      error: const Color(0xFFFF5252),
    );

    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = locale.languageCode == 'ar'
        ? GoogleFonts.notoNaskhArabicTextTheme(baseTextTheme)
        : GoogleFonts.interTextTheme(baseTextTheme);

    WidgetStateProperty<Color?> interactionOverlay(
      Color color, {
      double hoverAlpha = 0.1,
      double pressedAlpha = 0.14,
      double focusedAlpha = 0.08,
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

    return ThemeData.dark().copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      textTheme: textTheme,
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
          overlayColor: interactionOverlay(Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          overlayColor: interactionOverlay(primaryColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        overlayColor: interactionOverlay(
          primaryColor,
          hoverAlpha: 0.12,
          pressedAlpha: 0.18,
          focusedAlpha: 0.1,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
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
      backgroundColor: const Color(0xFF1A1A2E),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trackYourSpendingBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
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
                style: const TextStyle(color: Colors.white38, fontSize: 14),
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
            color: const Color(0xFF1A1A2E),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onTabTapped,
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.camera_alt_outlined),
                selectedIcon: const Icon(Icons.camera_alt_rounded),
                label: l10n.navScan,
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    const Icon(Icons.bar_chart_outlined),
                    if (!AuthService.instance.isLoggedIn)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child:
                            Icon(Icons.lock, size: 10, color: Colors.white38),
                      ),
                  ],
                ),
                selectedIcon: const Icon(Icons.bar_chart_rounded),
                label: l10n.navDashboard,
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    if (!AuthService.instance.isLoggedIn)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child:
                            Icon(Icons.lock, size: 10, color: Colors.white38),
                      ),
                  ],
                ),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: l10n.navHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
