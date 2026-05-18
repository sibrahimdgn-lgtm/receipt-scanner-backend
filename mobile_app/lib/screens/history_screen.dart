import 'package:flutter/material.dart';

import '../config/receipt_categories.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/csv_download_service.dart';
import '../services/dashboard_service.dart';
import '../utils/currency_format.dart';
import '../utils/history_csv_export.dart';
import '../utils/receipt_date_format.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/hover_lift_card.dart';
import '../widgets/language_switcher_button.dart';
import '../widgets/motion_reveal.dart';
import '../widgets/scan_feedback_widgets.dart';
import 'edit_receipt_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _receipts = [];
  bool _loading = true;
  String? _error;

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
    if (!AuthService.instance.isLoggedIn) {
      setState(() {
        _receipts = [];
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
      final data = await DashboardService.instance.fetchHistory();
      if (mounted) {
        setState(() {
          _receipts = data['receipts'] as List;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.failedToLoadHistory;
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportReceipts() async {
    if (_receipts.isEmpty) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    try {
      final csv = buildHistoryCsv(
        _receipts,
        headers: HistoryCsvHeaders(
          date: l10n.date,
          vendorName: l10n.vendorName,
          categories: l10n.category,
          totalAmount: l10n.total,
          currencyCode: l10n.currencyCode,
          currencySymbol: l10n.currencySymbolLabel,
          itemCount: l10n.items,
          receiptId: 'receipt_id',
        ),
        categoryLabelFor: (value) => ReceiptCategories.labelFor(context, value),
      );

      final dateLabel = DateTime.now().toIso8601String().split('T').first;
      await downloadCsvFile(
        filename: 'receipt-history-$dateLabel.csv',
        csvContent: csv,
      );

      if (!mounted) {
        return;
      }

      _showStatusSnackBar(
        message: l10n.receiptExportDownloaded,
        icon: Icons.download_done_rounded,
        accentColor: theme.colorScheme.primary,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showStatusSnackBar(
        message: l10n.receiptExportFailed,
        icon: Icons.error_outline_rounded,
        accentColor: theme.colorScheme.error,
      );
    }
  }

  void _showStatusSnackBar({
    required String message,
    required IconData icon,
    required Color accentColor,
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
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBackdrop(
        child: RefreshIndicator(
          onRefresh: _load,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.colorScheme.surface,
                pinned: true,
                expandedHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    l10n.receiptsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                actions: [
                  if (AuthService.instance.isLoggedIn &&
                      !_loading &&
                      _error == null &&
                      _receipts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: _exportReceipts,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.28),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(l10n.exportCsv),
                        ),
                      ),
                    ),
                  const LanguageSwitcherButton(
                    margin: EdgeInsets.only(right: 12),
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
                      l10n.historySignInPrompt,
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
              else if (_receipts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: MotionReveal(
                      delay: const Duration(milliseconds: 140),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noReceiptsYet,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.scanFirstReceipt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, index) => MotionReveal(
                        delay: Duration(milliseconds: 60 * index.clamp(0, 8)),
                        child: _ReceiptCard(
                          receipt: _receipts[index],
                          onChanged: _load,
                        ),
                      ),
                      childCount: _receipts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatefulWidget {
  final Map<String, dynamic> receipt;
  final Future<void> Function() onChanged;

  const _ReceiptCard({
    required this.receipt,
    required this.onChanged,
  });

  @override
  State<_ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<_ReceiptCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final receipt = widget.receipt;
    final vendor = receipt['vendor_name'] as String? ?? l10n.unknownVendor;
    final date = receipt['receipt_date'] as String? ?? '';
    final total = double.tryParse(receipt['total_amount'].toString()) ?? 0;
    final itemCount = int.tryParse(receipt['item_count'].toString()) ?? 0;
    final currencyCode = CurrencyFormat.normalizeCode(
      receipt['currency_code']?.toString() ??
          receipt['currency']?.toString() ??
          AuthService.instance.shopCurrencyCode,
    );
    final currencySymbol = CurrencyFormat.normalizeSymbol(
      receipt['currency_symbol']?.toString(),
    );

    return HoverLiftCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      glowColor: theme.colorScheme.primary,
      lift: 8,
      enablePress: true,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _expanded
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$date  ·  ${l10n.itemCountLabel(itemCount)}  ·  ${CurrencyFormat.codeWithSymbol(currencyCode: currencyCode, currencySymbol: currencySymbol)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormat.formatAmount(
                            total,
                            currencyCode: currencyCode,
                            currencySymbol: currencySymbol,
                          ),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: _expanded
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _statCell(l10n.items, '$itemCount', theme),
                                    _divider(),
                                    _statCell(
                                      l10n.total,
                                      CurrencyFormat.formatAmount(
                                        total,
                                        currencyCode: currencyCode,
                                        currencySymbol: currencySymbol,
                                      ),
                                      theme,
                                    ),
                                    _divider(),
                                    _statCell(
                                      l10n.date,
                                      date.length >= 10
                                          ? date.substring(0, 10)
                                          : date,
                                      theme,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 12),
                                if (receipt['line_items'] != null &&
                                    (receipt['line_items'] as List).isNotEmpty)
                                  ...((receipt['line_items'] as List)
                                      .map((lineItem) {
                                    final quantity = double.tryParse(
                                            lineItem['quantity']?.toString() ??
                                                '1') ??
                                        1;
                                    final price = double.tryParse(
                                            lineItem['total_price']
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    final formattedTransactionDate =
                                        ReceiptDateFormat.formatLineItemDate(
                                      context,
                                      lineItem['transaction_date']?.toString(),
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${quantity.toInt()}x',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lineItem['item_name']
                                                          ?.toString() ??
                                                      l10n.unknownItem,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurface,
                                                  ),
                                                ),
                                                if (formattedTransactionDate !=
                                                    null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 2,
                                                    ),
                                                    child: Text(
                                                      formattedTransactionDate,
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            CurrencyFormat.formatAmount(
                                              price,
                                              currencyCode: currencyCode,
                                              currencySymbol: currencySymbol,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }))
                                else
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      l10n.noExtractedItems,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.edit_note,
                                            size: 18),
                                        label: Text(l10n.editReceiptData),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              theme.colorScheme.primary,
                                          side: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.3),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditReceiptScreen(
                                                  receipt: receipt),
                                            ),
                                          );
                                          if (result == true) {
                                            await widget.onChanged();
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: BorderSide(
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor:
                                                theme.colorScheme.surface,
                                            title: Text(
                                              l10n.deleteReceiptTitle,
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            content: Text(
                                              l10n.deleteReceiptBody,
                                              style: TextStyle(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(
                                                  l10n.cancel,
                                                  style: TextStyle(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: Text(
                                                  l10n.delete,
                                                  style: const TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          try {
                                            await DashboardService.instance
                                                .deleteReceipt(
                                                    receipt['receipt_id']);
                                            await widget.onChanged();
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(l10n
                                                      .failedToDeleteReceipt),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      child: const Icon(Icons.delete_outline,
                                          size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}
