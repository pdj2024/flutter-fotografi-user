import 'package:flutter/material.dart';
import '../../../data/models/vendor_model.dart';
import '../services/vendor_service.dart';

class VendorProvider with ChangeNotifier {
  final VendorService service;

  VendorProvider({required this.service});

  List<VendorModel> _vendorList = [];
  VendorModel? _vendor;
  bool _isLoading = false;
  String? _error;

  List<VendorModel> get vendorList => _vendorList;
  VendorModel? get vendor => _vendor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getAll({
    String? no_id,
    String? namaDisplay,
    String? id_media,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vendorList = await service.getAll(
        no_id: no_id,
        namaDisplay: namaDisplay,
        id_media: id_media,
        status: status,
        orderBy: orderBy,
        orderDir: orderDir,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> create(VendorModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.create(model);
      await getAll(); // refresh setelah tambah
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> update(VendorModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.update(model);
      await getAll(); // refresh setelah update
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> delete(String noId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.delete(noId);
      await getAll(); // refresh setelah hapus
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
