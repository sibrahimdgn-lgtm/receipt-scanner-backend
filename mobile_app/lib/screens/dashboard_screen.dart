import 'package:flutter/material.dart';

import '../config/app_languages.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../utils/currency_format.dart';
import '../utils/dashboard_trend.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/dashboard_trend_chart.dart';
import '../widgets/hover_lift_card.dart';
import '../widgets/language_switcher_button.dart';
import '../widgets/motion_reveal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _cardShadow = [
    BoxShadow(
      color: Color(0x0F102A43),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _selectedPeriod = 'daily';
  String? _selectedCurrencyCode;

  List<Map<String, dynamic>> get _availableCurrencies {
    final rawList = (_data?['availableCurrencies'] as List?) ?? const [];
    return rawList
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  String get _activeCurrencyCode => CurrencyFormat.normalizeCode(
        _data?['activeCurrency']?.toString() ??
            _selectedCurrencyCode ??
            AuthService.instance.shopCurrencyCode,
      );

  String? get _activeCurrencySymbol {
    for (final currency in _availableCurrencies) {
      final code = CurrencyFormat.normalizeCode(
        currency['currency_code']?.toString(),
      );
      if (code == _activeCurrencyCode) {
        return CurrencyFormat.normalizeSymbol(
          currency['currency_symbol']?.toString(),
        );
      }
    }
    return null;
  }

  bool get _hasMixedCurrencies =>
      _data?['hasMixedCurrencies'] == true || _availableCurrencies.length > 1;

  @override
  void initState() {
    super.initState();
    DashboardService.instance.addListener(_load);
    AuthService.instance.addListener(_load);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    DashboardService.instance.removeListener(_load);
    AuthService.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;

    if (!AuthService.instance.isLoggedIn) {
      setState(() {
        _data = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DashboardService.instance.fetchSummary(
        period: _selectedPeriod,
        currencyCode: _selectedCurrencyCode,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _selectedCurrencyCode = data['activeCurrency']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.failedToLoadDashboard;
        _loading = false;
      });
    }
  }

  Future<void> _changeCurrency(String code) async {
    if (code == _selectedCurrencyCode) {
      return;
    }
    setState(() => _selectedCurrencyCode = code);
    await _load();
  }

  String _formatAmount(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return CurrencyFormat.formatAmount(
      amount,
      currencyCode: _activeCurrencyCode,
      currencySymbol: _activeCurrencySymbol,
    );
  }

  Widget _reveal(
    int order,
    Widget child, {
    Offset beginOffset = const Offset(0, 0.08),
  }) {
    return MotionReveal(
      delay: Duration(milliseconds: 70 * order),
      beginOffset: beginOffset,
      child: child,
    );
  }

  BoxDecoration _panelDecoration(
    ThemeData theme, {
    Color? color,
    Border? border,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: theme.colorScheme.outlineVariant),
      boxShadow: _cardShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackdrop(
        child: RefreshIndicator(
          onRefresh: _load,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 100,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.navDashboard,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        AuthService.instance.shopName ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  const LanguageSwitcherButton(
                    margin: EdgeInsets.only(right: 4),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _load,
                  ),
                ],
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!AuthService.instance.isLoggedIn)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.dashboardSignInPrompt,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _reveal(0, _buildSpendingCards(theme, l10n)),
                      const SizedBox(height: 20),
                      _reveal(1, _buildCurrencyPanel(theme, l10n)),
                      const SizedBox(height: 28),
                      _reveal(
                        2,
                        _buildSectionHeader(l10n.spendingTrends, theme),
                        beginOffset: const Offset(-0.04, 0.05),
                      ),
                      const SizedBox(height: 12),
                      _reveal(3, _buildTrendToggle(theme, l10n)),
                      const SizedBox(height: 24),
                      _reveal(4, _buildTrendChart(l10n)),
                      const SizedBox(height: 28),
                      _reveal(
                        5,
                        _buildSectionHeader(l10n.spendingByCategory, theme),
                        beginOffset: const Offset(-0.04, 0.05),
                      ),
                      const SizedBox(height: 12),
                      _reveal(6, _buildCategories(theme, l10n)),
                      const SizedBox(height: 32),
                      _reveal(
                        7,
                        _buildSectionHeader(l10n.topSpots, theme),
                        beginOffset: const Offset(-0.04, 0.05),
                      ),
                      const SizedBox(height: 12),
                      _reveal(8, _buildVendors(theme, l10n)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingCards(ThemeData theme, dynamic l10n) {
    final summary = Map<String, dynamic>.from(
      _data?['summary'] as Map? ?? const {},
    );

    return Row(
      children: [
        _summaryCard(
          l10n.totalSpend,
          summary['total_spend'],
          theme,
          theme.colorScheme.primary,
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(width: 16),
        _summaryCountCard(
          l10n.totalReceipts,
          summary['receipt_count'],
          theme,
          theme.colorScheme.secondary,
          icon: Icons.receipt_long_rounded,
        ),
      ],
    );
  }

  Widget _buildCurrencyPanel(ThemeData theme, dynamic l10n) {
    final currencies = _availableCurrencies;
    final activeLabel = CurrencyFormat.codeWithSymbol(
      currencyCode: _activeCurrencyCode,
      currencySymbol: _activeCurrencySymbol,
    );

    return HoverLiftCard(
      glowColor: theme.colorScheme.secondary,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: _panelDecoration(theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasMixedCurrencies
                      ? l10n.dashboardCurrencyFilter
                      : l10n.receiptCurrency,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _hasMixedCurrencies
                  ? l10n.dashboardCurrencyFilterBody
                  : l10n.dashboardCurrencySingleBody(activeLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: currencies.isEmpty
                  ? [
                      _currencyChip(
                        theme,
                        l10n,
                        code: _activeCurrencyCode,
                        symbol: _activeCurrencySymbol,
                        totalSpend: 0,
                        receiptCount: 0,
                        isSelected: true,
                      ),
                    ]
                  : currencies.map((currency) {
                      final code = CurrencyFormat.normalizeCode(
                        currency['currency_code']?.toString(),
                      );
                      final symbol = CurrencyFormat.normalizeSymbol(
                        currency['currency_symbol']?.toString(),
                      );
                      final totalSpend = double.tryParse(
                            currency['total_spend']?.toString() ?? '0',
                          ) ??
                          0;
                      final receiptCount = int.tryParse(
                            currency['receipt_count']?.toString() ?? '0',
                          ) ??
                          0;

                      return _currencyChip(
                        theme,
                        l10n,
                        code: code,
                        symbol: symbol,
                        totalSpend: totalSpend,
                        receiptCount: receiptCount,
                        isSelected: code == _activeCurrencyCode,
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyChip(
    ThemeData theme,
    dynamic l10n, {
    required String code,
    required String? symbol,
    required double totalSpend,
    required int receiptCount,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _changeCurrency(code),
      borderRadius: BorderRadius.circular(14),
      child: HoverLiftCard(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        glowColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        lift: 6,
        hoverScale: 1.01,
        enablePress: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 152,
          padding: const EdgeInsets.all(16),
          decoration: _panelDecoration(
            theme,
            radius: 18,
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CurrencyFormat.codeWithSymbol(
                  currencyCode: code,
                  currencySymbol: symbol,
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormat.formatAmount(
                  totalSpend,
                  currencyCode: code,
                  currencySymbol: symbol,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.receiptCountLabel(receiptCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCountCard(
    String label,
    dynamic count,
    ThemeData theme,
    Color color, {
    required IconData icon,
  }) {
    final value = int.tryParse(count?.toString() ?? '0') ?? 0;
    return Expanded(
      child: HoverLiftCard(
        glowColor: color,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _panelDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    String label,
    dynamic value,
    ThemeData theme,
    Color color, {
    required IconData icon,
  }) {
    return Expanded(
      child: HoverLiftCard(
        glowColor: color,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _panelDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatAmount(value),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendToggle(ThemeData theme, dynamic l10n) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C102A43),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'daily', label: Text(l10n.daily)),
            ButtonSegment(value: 'weekly', label: Text(l10n.weekly)),
            ButtonSegment(value: 'monthly', label: Text(l10n.monthly)),
            ButtonSegment(value: 'yearly', label: Text(l10n.yearly)),
          ],
          selected: {_selectedPeriod},
          onSelectionChanged: (selection) {
            setState(() => _selectedPeriod = selection.first);
            _load();
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.standard,
            minimumSize: WidgetStateProperty.all(const Size(84, 46)),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.colorScheme.primary;
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.colorScheme.onPrimary;
              }
              return theme.colorScheme.onSurfaceVariant;
            }),
            textStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return theme.textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              );
            }),
            side: WidgetStateProperty.all(BorderSide.none),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.pressed)) {
                return theme.colorScheme.primary.withValues(alpha: 0.12);
              }
              if (states.contains(WidgetState.hovered)) {
                return theme.colorScheme.primary.withValues(alpha: 0.08);
              }
              return Colors.transparent;
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(dynamic l10n) {
    final trend = DashboardTrendBucket.fromList(_data?['trend']);
    final periodTrunc = _data?['periodDetails']?['trunc'] as String? ?? 'day';
    final drilldownPeriod =
        _data?['periodDetails']?['drilldownPeriod'] as String?;

    return DashboardTrendChart(
      trend: trend,
      periodTrunc: periodTrunc,
      selectedPeriod: _selectedPeriod,
      drilldownPeriod: drilldownPeriod,
      noDataText: l10n.noSpendingDataYet,
      activeCurrencyCode: _activeCurrencyCode,
      activeCurrencySymbol: _activeCurrencySymbol,
    );
  }

  Widget _buildCategories(ThemeData theme, dynamic l10n) {
    final categories = (_data?['categories'] as List?) ?? const [];
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: _cardShadow,
        ),
        child: Text(
          l10n.scanToSeeCategories,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final maxVal = categories.fold<double>(
      0,
      (maxValue, category) {
        final current = double.tryParse(category['total'].toString()) ?? 0;
        return current > maxValue ? current : maxValue;
      },
    );

    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      const Color(0xFF1F6FEB),
      const Color(0xFF63C5DA),
      const Color(0xFF2CB1BC),
      const Color(0xFF486581),
    ];

    return Column(
      children: categories.asMap().entries.map((entry) {
        final category = entry.value['category'] as String;
        final total = double.tryParse(entry.value['total'].toString()) ?? 0;
        final percentage = maxVal > 0 ? total / maxVal : 0.0;
        final color = colors[entry.key % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormat.formatAmount(
                      total,
                      currencyCode: _activeCurrencyCode,
                      currencySymbol: _activeCurrencySymbol,
                    ),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                  color: color,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVendors(ThemeData theme, dynamic l10n) {
    final vendors = (_data?['vendors'] as List?) ?? const [];
    if (vendors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: _cardShadow,
        ),
        child: Text(
          l10n.scanToSeeTopSpots,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final maxVal = vendors.fold<double>(
      0,
      (maxValue, vendor) {
        final current = double.tryParse(vendor['total'].toString()) ?? 0;
        return current > maxValue ? current : maxValue;
      },
    );

    final colors = [
      theme.colorScheme.tertiary,
      const Color(0xFF2CB1BC),
      const Color(0xFF486581),
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      const Color(0xFF1F6FEB),
    ];

    return Column(
      children: vendors.asMap().entries.map((entry) {
        final vendor = entry.value['vendor'] as String;
        final total = double.tryParse(entry.value['total'].toString()) ?? 0;
        final percentage = maxVal > 0 ? total / maxVal : 0.0;
        final color = colors[entry.key % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vendor,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormat.formatAmount(
                      total,
                      currencyCode: _activeCurrencyCode,
                      currencySymbol: _activeCurrencySymbol,
                    ),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                  color: color,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
