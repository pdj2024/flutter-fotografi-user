import 'package:flutter/material.dart';

class UiStateProvider extends ChangeNotifier {
  // === HeaderInfoCard: in DetailOrderV2 ===
  //
  // untuk kebutuhan card bisa expand

  bool _headerInfoExpanded = false;
  bool get headerInfoExpanded => _headerInfoExpanded;
  void toggleHeaderInfo() {
    _headerInfoExpanded = !_headerInfoExpanded;
    notifyListeners();
  }


}