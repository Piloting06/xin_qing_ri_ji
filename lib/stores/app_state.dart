import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AppState extends ChangeNotifier {
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _displayName = '';
  int _windowWidth = 0;
  bool _animActive = false;

  String get selectedDate => _selectedDate;
  String get displayName => _displayName;
  int get windowWidth => _windowWidth;
  bool get animActive => _animActive;

  void setSelectedDate(String d) {
    if (_selectedDate != d) {
      _selectedDate = d;
      notifyListeners();
    }
  }

  void setDisplayName(String n) {
    if (_displayName != n) {
      _displayName = n;
      notifyListeners();
    }
  }

  void setWindowWidth(int w) {
    _windowWidth = w;
  }

  void setAnimActive(bool a) {
    if (_animActive != a) {
      _animActive = a;
      notifyListeners();
    }
  }
}
