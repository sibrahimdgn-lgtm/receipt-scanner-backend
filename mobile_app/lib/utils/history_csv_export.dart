typedef ReceiptCategoryLabelResolver = String Function(String? value);

class HistoryCsvHeaders {
  const HistoryCsvHeaders({
    required this.date,
    required this.vendorName,
    required this.categories,
    required this.totalAmount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.itemCount,
    required this.receiptId,
  });

  final String date;
  final String vendorName;
  final String categories;
  final String totalAmount;
  final String currencyCode;
  final String currencySymbol;
  final String itemCount;
  final String receiptId;

  List<String> toRow() => [
        date,
        vendorName,
        categories,
        totalAmount,
        currencyCode,
        currencySymbol,
        itemCount,
        receiptId,
      ];
}

String buildHistoryCsv(
  List<dynamic> receipts, {
  required HistoryCsvHeaders headers,
  required ReceiptCategoryLabelResolver categoryLabelFor,
}) {
  final rows = <List<String>>[headers.toRow()];

  for (final rawReceipt in receipts) {
    final receipt = Map<String, dynamic>.from(rawReceipt as Map);
    final lineItems = ((receipt['line_items'] as List?) ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();

    final categories = lineItems
        .map(
          (item) => categoryLabelFor(
            item['category_key']?.toString() ?? item['category']?.toString(),
          ),
        )
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .join(' | ');

    rows.add([
      _stringify(receipt['receipt_date']),
      _stringify(receipt['vendor_name']),
      categories,
      _stringify(receipt['total_amount']),
      _stringify(receipt['currency_code'] ?? receipt['currency']),
      _stringify(receipt['currency_symbol']),
      _stringify(receipt['item_count']),
      _stringify(receipt['receipt_id']),
    ]);
  }

  return rows.map(_encodeCsvRow).join('\r\n');
}

String _stringify(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String _encodeCsvRow(List<String> fields) {
  return fields.map(_escapeCsvField).join(',');
}

String _escapeCsvField(String value) {
  final escaped = value.replaceAll('"', '""');
  if (escaped.contains(',') ||
      escaped.contains('"') ||
      escaped.contains('\n') ||
      escaped.contains('\r')) {
    return '"$escaped"';
  }
  return escaped;
}
