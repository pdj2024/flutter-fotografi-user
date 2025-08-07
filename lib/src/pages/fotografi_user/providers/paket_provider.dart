import 'package:flutter/material.dart';
import '../models/paket_model.dart';
import '../services/paket_service.dart';

class PaketProvider with ChangeNotifier {
  final PaketService service;

  PaketProvider({required this.service});

  List<PaketModel> _paketList = [];
  PaketModel? _paket;
  bool _isLoading = false;
  String? _error;

  List<PaketModel> get paketList => _paketList;
  PaketModel? get paket => _paket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getAll({
    String? no_id,
    String? nama_paket,
    String? id_media,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _paketList = await service.getAll(
        noId: no_id,
        namaPaket: nama_paket,
        idVendor: id_media,
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

  Future<void> create(PaketModel model) async {
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

  Future<void> update(PaketModel model) async {
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