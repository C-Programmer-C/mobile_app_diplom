import 'package:flutter/foundation.dart';

class CartSync {
  static final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _tick;

  static void notifyChanged() {
    _tick.value = _tick.value + 1;
  }
}

