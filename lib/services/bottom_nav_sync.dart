import 'package:flutter/foundation.dart';

class BottomNavSync {
  static final ValueNotifier<int> _index = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _index;

  static int get currentIndex => _index.value;

  static void setIndex(int index) {
    if (_index.value == index) return;
    _index.value = index;
  }
}

