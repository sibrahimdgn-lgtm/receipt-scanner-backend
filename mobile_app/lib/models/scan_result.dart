// Data models for the receipt scan API response.
import '../config/receipt_categories.dart';

class LineItem {
  final String lineItemId;
  final String itemName;
  final String? transactionDate;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String categoryKey;

  const LineItem({
    required this.lineItemId,
    required this.itemName,
    this.transactionDate,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.categoryKey,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      lineItemId: json['line_item_id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? 'Unknown item',
      transactionDate: _toOptionalString(
        json['transaction_date']?.toString(),
      ),
      quantity: _toDouble(json['quantity'], fallback: 1),
      unitPrice: _toDouble(json['unit_price']),
      totalPrice: _toDouble(json['total_price']),
      categoryKey: ReceiptCategories.normalize(
        json['category_key']?.toString() ?? json['category']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'transaction_date': transactionDate,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'category_key': categoryKey,
      'category': categoryKey,
    };
  }
}

class ScanResult {
  final String receiptId;
  final String vendorName;
  final String receiptDate;
  final String currencyCode;
  final String? currencySymbol;
  final String? currencySource;
  final double currencyConfidence;
  final double totalAmount;
  final double taxAmount;
  final List<LineItem> lineItems;

  const ScanResult({
    required this.receiptId,
    required this.vendorName,
    required this.receiptDate,
    required this.currencyCode,
    this.currencySymbol,
    this.currencySource,
    required this.currencyConfidence,
    required this.totalAmount,
    required this.taxAmount,
    required this.lineItems,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // The API wraps the receipt inside a "receipt" key.
    final receipt = json.containsKey('receipt')
        ? json['receipt'] as Map<String, dynamic>
        : json;

    final rawItems = receipt['line_items'] as List<dynamic>? ?? [];

    return ScanResult(
      receiptId: receipt['receipt_id']?.toString() ?? '',
      vendorName: receipt['vendor_name']?.toString() ?? 'Unknown vendor',
      receiptDate: receipt['receipt_date']?.toString() ?? '',
      currencyCode: receipt['currency_code']?.toString() ??
          receipt['currency']?.toString() ??
          json['currency_code']?.toString() ??
          json['currency']?.toString() ??
          'TRY',
      currencySymbol: receipt['currency_symbol']?.toString(),
      currencySource: receipt['currency_source']?.toString(),
      currencyConfidence: _toDouble(
        receipt['currency_confidence'] ?? json['currency_confidence'],
      ),
      totalAmount: _toDouble(receipt['total_amount']),
      taxAmount: _toDouble(receipt['tax_amount']),
      lineItems: rawItems
          .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_name': vendorName,
      'receipt_date': receiptDate,
      'currency': currencyCode,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_source': currencySource,
      'currency_confidence': currencyConfidence,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
    };
  }
}

// ── Helpers ────────────────────────────────────────────────────
double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

String? _toOptionalString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
