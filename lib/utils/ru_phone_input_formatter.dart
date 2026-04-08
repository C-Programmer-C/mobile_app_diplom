import 'package:flutter/services.dart';

class RuPhoneInputFormatter extends TextInputFormatter {
  static String formatFromAny(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return _format(_normalizeDigits(digits));
  }

  static bool isComplete(String value) {
    final digits = _normalizeDigits(value.replaceAll(RegExp(r'\D'), ''));
    return digits.length == 11 && digits.startsWith('7');
  }

  static String _normalizeDigits(String digits) {
    var d = digits;
    if (d.length == 10) d = '7$d';
    if (d.startsWith('8') && d.length >= 11) d = '7${d.substring(1)}';
    if (d.startsWith('7') && d.length > 11) d = d.substring(0, 11);
    return d;
  }

  static String _format(String digits) {
    if (digits.isEmpty) return '';
    if (!digits.startsWith('7')) return digits;

    if (digits.length == 1) return '+7';
    if (digits.length <= 4) return '+7 (${digits.substring(1)})';
    if (digits.length <= 7) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4)}';
    }
    if (digits.length <= 9) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9, 11)}';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatFromAny(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
