import 'package:flutter/services.dart';

class CardPanInputFormatter extends TextInputFormatter {
  static const int maxDigits = 19;

  static String formatFromAny(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }
    return _format(digits);
  }

  static bool isComplete(String value) {
    final n = value.replaceAll(RegExp(r'\D'), '').length;
    return n >= 13 && n <= maxDigits;
  }

  static String _format(String digits) {
    if (digits.isEmpty) return '';
    final sb = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) sb.write(' ');
      sb.write(digits[i]);
    }
    return sb.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var rawNew = newValue.text.replaceAll(RegExp(r'\D'), '');
    final rawOld = oldValue.text.replaceAll(RegExp(r'\D'), '');
    if (rawNew.length > maxDigits) {
      rawNew = rawNew.substring(0, maxDigits);
    }
    var digits = rawNew;
    var oldDigits = rawOld.length > maxDigits
        ? rawOld.substring(0, maxDigits)
        : rawOld;

    if (newValue.text.length < oldValue.text.length &&
        digits == oldDigits &&
        oldDigits.isNotEmpty) {
      digits = oldDigits.substring(0, oldDigits.length - 1);
    }

    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
