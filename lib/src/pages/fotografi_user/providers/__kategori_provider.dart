import 'package:flutter/material.dart';
import '../../../data/models/kategori_model.dart';
import '../services/kategori_service.dart';

class KategoriProvider with ChangeNotifier {
  final KategoriService service;

  KategoriProvider({required this.service});

  List<KategoriModel> _kategoriList = [];
  KategoriModel? _kategori;
  bool _isLoading = false;
  String? _error;

  List<KategoriModel> get kategoriList => _kategoriList;
  KategoriModel? get kategori => _kategori;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getAll({
    String? noId,
    String? namaKategori,
    String? idMedia,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _kategoriList = await service.getAll(
        noId: noId,
        namaKategori: namaKategori,
        idMedia: idMedia,
        status: status,
        orderBy: orderBy,
        orderDir: orderDir,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(KategoriModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.create(model);
      await getAll(); // Refresh setelah create
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(KategoriModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.update(model);
      await getAll(); // Refresh setelah update
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String noId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.delete(noId);
      await getAll(); // Refresh setelah delete
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
