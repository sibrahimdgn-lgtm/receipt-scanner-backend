import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'currency_format.dart';

typedef ReceiptCategoryLabelResolver = String Function(String? value);
typedef PdfFontLoader = Future<pw.Font> Function();

class HistoryPdfLabels {
  const HistoryPdfLabels({
    required this.title,
    required this.generatedOn,
    required this.date,
    required this.vendorName,
    required this.category,
    required this.totalAmount,
    required this.currency,
    required this.totalSpend,
    required this.mixedCurrencies,
  });

  final String title;
  final String generatedOn;
  final String date;
  final String vendorName;
  final String category;
  final String totalAmount;
  final String currency;
  final String totalSpend;
  final String mixedCurrencies;
}

class HistoryPdfFontLoaders {
  const HistoryPdfFontLoaders({
    required this.regular,
    required this.bold,
  });

  final PdfFontLoader regular;
  final PdfFontLoader bold;
}

class _HistoryExportRow {
  const _HistoryExportRow({
    required this.date,
    required this.vendorName,
    required this.categories,
    required this.totalAmount,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String date;
  final String vendorName;
  final String categories;
  final double totalAmount;
  final String currencyCode;
  final String? currencySymbol;
}

class _ResolvedPdfFonts {
  const _ResolvedPdfFonts({
    required this.regular,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font bold;
}

Future<Uint8List> buildHistoryPdfBytes(
  List<dynamic> receipts, {
  required HistoryPdfLabels labels,
  required ReceiptCategoryLabelResolver categoryLabelFor,
  required Locale locale,
  HistoryPdfFontLoaders? fontLoaders,
}) async {
  final rows = _buildRows(
    receipts,
    categoryLabelFor: categoryLabelFor,
  );
  final fonts = await _resolveFonts(locale, fontLoaders);
  final isRtl = locale.languageCode.toLowerCase() == 'ar';
  final document = pw.Document(
    title: labels.title,
    author: 'Receipt Scanner',
  );

  final totalAmount = rows.fold<double>(
    0,
    (sum, row) => sum + row.totalAmount,
  );
  final uniqueCurrencies = rows
      .map(
        (row) => CurrencyFormat.codeWithSymbol(
          currencyCode: row.currencyCode,
          currencySymbol: row.currencySymbol,
        ),
      )
      .where((value) => value.trim().isNotEmpty)
      .toSet();
  final totalSummary = uniqueCurrencies.length == 1
      ? CurrencyFormat.formatAmount(
          totalAmount,
          currencyCode: rows.isNotEmpty ? rows.first.currencyCode : null,
          currencySymbol: rows.isNotEmpty ? rows.first.currencySymbol : null,
        )
      : labels.mixedCurrencies;

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
      build: (context) => [
        pw.Directionality(
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                labels.title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF163247),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '${labels.generatedOn}: ${DateTime.now().toIso8601String().replaceFirst('T', ' ').substring(0, 16)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF5E7386),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: [
                  labels.date,
                  labels.vendorName,
                  labels.category,
                  labels.totalAmount,
                  labels.currency,
                ],
                data: rows
                    .map(
                      (row) => [
                        row.date,
                        row.vendorName,
                        row.categories,
                        CurrencyFormat.formatAmount(
                          row.totalAmount,
                          currencyCode: row.currencyCode,
                          currencySymbol: row.currencySymbol,
                        ),
                        CurrencyFormat.codeWithSymbol(
                          currencyCode: row.currencyCode,
                          currencySymbol: row.currencySymbol,
                        ),
                      ],
                    )
                    .toList(),
                border: pw.TableBorder.all(
                  color: PdfColor.fromInt(0xFFD7E3EC),
                  width: 0.6,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEAF8FB),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF163247),
                  fontSize: 10,
                ),
                cellStyle: pw.TextStyle(
                  color: PdfColor.fromInt(0xFF163247),
                  fontSize: 10,
                ),
                headerAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerLeft,
                },
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                headerPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF7F9FC),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFD7E3EC),
                    width: 0.6,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      labels.totalSpend,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF163247),
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      totalSummary,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF00B4CE),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return document.save();
}

List<_HistoryExportRow> _buildRows(
  List<dynamic> receipts, {
  required ReceiptCategoryLabelResolver categoryLabelFor,
}) {
  return receipts.map((rawReceipt) {
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

    return _HistoryExportRow(
      date: _stringify(receipt['receipt_date']),
      vendorName: _stringify(receipt['vendor_name']),
      categories: categories,
      totalAmount:
          double.tryParse(receipt['total_amount']?.toString() ?? '0') ?? 0,
      currencyCode: CurrencyFormat.normalizeCode(
        receipt['currency_code']?.toString() ?? receipt['currency']?.toString(),
      ),
      currencySymbol: receipt['currency_symbol']?.toString(),
    );
  }).toList();
}

String _stringify(dynamic value) => value?.toString() ?? '';

Future<_ResolvedPdfFonts> _resolveFonts(
  Locale locale,
  HistoryPdfFontLoaders? fontLoaders,
) async {
  final regularLoader = fontLoaders?.regular ?? _defaultRegularFont(locale);
  final boldLoader = fontLoaders?.bold ?? _defaultBoldFont(locale);

  try {
    return _ResolvedPdfFonts(
      regular: await regularLoader(),
      bold: await boldLoader(),
    );
  } catch (_) {
    return _ResolvedPdfFonts(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }
}

PdfFontLoader _defaultRegularFont(Locale locale) {
  if (locale.languageCode.toLowerCase() == 'ar') {
    return () => PdfGoogleFonts.notoNaskhArabicRegular();
  }
  return () => PdfGoogleFonts.interRegular();
}

PdfFontLoader _defaultBoldFont(Locale locale) {
  if (locale.languageCode.toLowerCase() == 'ar') {
    return () => PdfGoogleFonts.notoNaskhArabicBold();
  }
  return () => PdfGoogleFonts.interBold();
}
