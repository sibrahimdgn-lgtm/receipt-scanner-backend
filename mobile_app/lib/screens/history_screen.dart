import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../utils/currency_format.dart';
import '../utils/receipt_date_format.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/hover_lift_card.dart';
import '../widgets/language_switcher_button.dart';
import '../widgets/motion_reveal.dart';
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
                pinned: true,
                expandedHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    l10n.receiptsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: const [
                  LanguageSwitcherButton(
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
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white54),
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
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.scanFirstReceipt,
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 13,
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
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: _expanded ? 0.12 : 0.06),
            ),
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
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.secondary.withValues(alpha: 0.2),
                          ],
                        ),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$date  ·  ${l10n.itemCountLabel(itemCount)}  ·  ${CurrencyFormat.codeWithSymbol(currencyCode: currencyCode, currencySymbol: currencySymbol)}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
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
                          color: Colors.white24,
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
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
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
                                Container(height: 1, color: Colors.white12),
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
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
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
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
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
                                                      style: const TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 12,
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
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
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
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
                                                const Color(0xFF1A1A2E),
                                            title: Text(
                                              l10n.deleteReceiptTitle,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            content: Text(
                                              l10n.deleteReceiptBody,
                                              style: const TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(
                                                  l10n.cancel,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
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
          style: const TextStyle(color: Colors.white38, fontSize: 11),
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

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white12);
}
