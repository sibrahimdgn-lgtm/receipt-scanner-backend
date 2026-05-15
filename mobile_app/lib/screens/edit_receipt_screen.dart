import 'package:flutter/material.dart';

import '../config/receipt_categories.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../utils/currency_format.dart';

class EditReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> receipt;
  const EditReceiptScreen({super.key, required this.receipt});

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vendorCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _taxCtrl;

  List<Map<String, dynamic>> _items = [];
  bool _saving = false;

  String get _currencyCode => CurrencyFormat.normalizeCode(
        _currencyCtrl.text.isEmpty
            ? widget.receipt['currency_code']?.toString() ??
                widget.receipt['currency']?.toString() ??
                AuthService.instance.shopCurrencyCode
            : _currencyCtrl.text,
      );

  String? get _currencySymbol => CurrencyFormat.normalizeSymbol(
        _currencyCode ==
                CurrencyFormat.normalizeCode(
                  widget.receipt['currency_code']?.toString() ??
                      widget.receipt['currency']?.toString(),
                )
            ? widget.receipt['currency_symbol']?.toString()
            : null,
      );

  @override
  void initState() {
    super.initState();
    _vendorCtrl = TextEditingController(
      text: widget.receipt['vendor_name']?.toString() ?? '',
    );
    _dateCtrl = TextEditingController(
      text: widget.receipt['receipt_date']?.toString() ?? '',
    );
    _currencyCtrl = TextEditingController(
      text: widget.receipt['currency_code']?.toString() ??
          widget.receipt['currency']?.toString() ??
          AuthService.instance.shopCurrencyCode,
    );
    _totalCtrl = TextEditingController(
      text: widget.receipt['total_amount']?.toString() ?? '',
    );
    _taxCtrl = TextEditingController(
      text: widget.receipt['tax_amount']?.toString() ?? '',
    );

    final lineItemsData = widget.receipt['line_items'];
    if (lineItemsData is List) {
      _items = lineItemsData.map((entry) {
        final item = Map<String, dynamic>.from(entry);
        item['category'] = ReceiptCategories.normalize(
          item['category_key']?.toString() ?? item['category']?.toString(),
        );
        return item;
      }).toList();
    }
  }

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _dateCtrl.dispose();
    _currencyCtrl.dispose();
    _totalCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    var total = 0.0;
    for (final item in _items) {
      total += double.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
    }
    _totalCtrl.text = total.toStringAsFixed(2);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updateData = {
        'vendor_name': _vendorCtrl.text.trim(),
        'receipt_date': _dateCtrl.text.trim(),
        'currency_code': _currencyCtrl.text.trim().toUpperCase(),
        'total_amount': double.tryParse(_totalCtrl.text) ?? 0,
        'tax_amount': double.tryParse(_taxCtrl.text) ?? 0,
        'line_items': _items
            .map(
              (item) => {
                'item_name': item['item_name'],
                'transaction_date': item['transaction_date'],
                'quantity': item['quantity'],
                'unit_price': item['unit_price'],
                'total_price': item['total_price'],
                'category_key': ReceiptCategories.normalize(
                  item['category']?.toString(),
                ),
              },
            )
            .toList(),
      };

      await DashboardService.instance
          .updateReceipt(widget.receipt['receipt_id'], updateData);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(l10n.editReceiptDetails),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                l10n.save,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.generalInfo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _vendorCtrl,
                label: l10n.vendorName,
                icon: Icons.store,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _dateCtrl,
                      label: l10n.dateIso,
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(
                      controller: _currencyCtrl,
                      label: CurrencyFormat.labelWithSymbol(
                        l10n.currencyCode,
                        currencyCode: _currencyCode,
                        currencySymbol: _currencySymbol,
                      ),
                      icon: Icons.currency_exchange,
                      onChanged: (_) => setState(() {}),
                      uppercase: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _totalCtrl,
                label: CurrencyFormat.labelWithSymbol(
                  l10n.total,
                  currencyCode: _currencyCode,
                  currencySymbol: _currencySymbol,
                ),
                icon: Icons.attach_money,
                isNumber: true,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.currencyCodeHint,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.extractedItems,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => setState(() {
                      _items.add({
                        'item_name': '',
                        'transaction_date': null,
                        'quantity': 1,
                        'unit_price': 0,
                        'total_price': 0,
                        'category': ReceiptCategories.defaultCategory,
                      });
                      _recalculateTotal();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item['item_name']?.toString() ?? '',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n.itemName,
                              ),
                              onChanged: (value) => item['item_name'] = value,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => setState(() {
                              _items.removeAt(index);
                              _recalculateTotal();
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item['quantity']?.toString() ?? '1',
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n.quantityShort,
                              ),
                              onChanged: (value) {
                                item['quantity'] = double.tryParse(value) ?? 1;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue:
                                  item['total_price']?.toString() ?? '0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: CurrencyFormat.labelWithSymbol(
                                  l10n.price,
                                  currencyCode: _currencyCode,
                                  currencySymbol: _currencySymbol,
                                ),
                              ),
                              onChanged: (value) {
                                item['total_price'] =
                                    double.tryParse(value) ?? 0;
                                _recalculateTotal();
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: ReceiptCategories.normalize(
                          item['category']?.toString(),
                        ),
                        dropdownColor: theme.colorScheme.surface,
                        decoration: InputDecoration(
                          labelText: l10n.category,
                        ),
                        items: ReceiptCategories.values
                            .map(
                              (categoryKey) => DropdownMenuItem<String>(
                                value: categoryKey,
                                child: Text(
                                  ReceiptCategories.labelFor(
                                    context,
                                    categoryKey,
                                  ),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          item['category'] = ReceiptCategories.normalize(value);
                        }),
                      ),
                    ],
                  ),
                );
              }),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.noLineItems,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool uppercase = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textCapitalization:
          uppercase ? TextCapitalization.characters : TextCapitalization.none,
      onChanged: onChanged,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
