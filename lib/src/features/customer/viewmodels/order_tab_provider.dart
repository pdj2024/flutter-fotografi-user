import 'package:flutter/material.dart';

class OrderTabProvider with ChangeNotifier {
 int selectedTabIndex = 0;
  TabController? tabController;

  void setSelectedTabIndex(int index) {
    selectedTabIndex = index;
    // Jika TabController sudah di-set, update index-nya
    if (tabController != null && !tabController!.indexIsChanging) {
      tabController!.animateTo(index);
    }
    notifyListeners();
  }
}
