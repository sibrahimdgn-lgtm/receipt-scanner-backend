import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class ReceiptDateFormat {
  ReceiptDateFormat._();

  static String? formatLineItemDate(BuildContext context, String? rawDate) {
    final value = rawDate?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) {
      return value;
    }

    final localeName = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('dd-MM-yyyy', localeName).format(parsedDate);
  }
}
