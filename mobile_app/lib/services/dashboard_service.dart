import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class DashboardService extends ChangeNotifier {
  static final DashboardService instance = DashboardService._();
  DashboardService._();

  Future<Map<String, dynamic>> fetchSummary({
    String period = 'daily',
    String? currencyCode,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/dashboard/summary').replace(
      queryParameters: {
        'period': period,
        if (currencyCode != null && currencyCode.trim().isNotEmpty)
          'currency': currencyCode.trim().toUpperCase(),
      },
    );
    final res = await http.get(
      uri,
      headers:
          await AuthService.instance.requestHeadersAsync(includeAuth: true),
    );
    if (res.statusCode != 200) throw Exception('Failed to load dashboard.');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchHistory({int page = 1}) async {
    final uri =
        Uri.parse('${AppConfig.baseUrl}/api/dashboard/history?page=$page');
    final res = await http.get(
      uri,
      headers:
          await AuthService.instance.requestHeadersAsync(includeAuth: true),
    );
    if (res.statusCode != 200) throw Exception('Failed to load history.');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> updateReceipt(
      String receiptId, Map<String, dynamic> updateData) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/receipts/$receiptId');
    final res = await http.put(
      uri,
      headers: await AuthService.instance.requestHeadersAsync(
        includeAuth: true,
        extra: {'Content-Type': 'application/json'},
      ),
      body: jsonEncode(updateData),
    );
    if (res.statusCode != 200) {
      final error = jsonDecode(res.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to update receipt: $error');
    }
    notifyListeners();
  }

  Future<void> deleteReceipt(String receiptId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/receipts/$receiptId');
    final res = await http.delete(
      uri,
      headers:
          await AuthService.instance.requestHeadersAsync(includeAuth: true),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete receipt.');
    }
    notifyListeners();
  }
}
