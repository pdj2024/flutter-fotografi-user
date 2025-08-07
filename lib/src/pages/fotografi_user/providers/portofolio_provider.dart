import 'package:flutter/material.dart';
import '../models/portofolio_model.dart';
import '../services/portofolio_service.dart';

class PortofolioProvider with ChangeNotifier {
  final PortofolioService service;

  PortofolioProvider({required this.service});

  List<PortofolioModel> _portofolioList = [];
  PortofolioModel? _portofolio;
  bool _isLoading = false;
  String? _error;

  List<PortofolioModel> get portofolioList => _portofolioList;
  PortofolioModel? get portofolio => _portofolio;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getAll({
    String? noId,
    String? id_customer,
    String? idVendor,
    String? idMedia,
    String? idKategori,
    String? namaVendor,
    double? ratingVendorMin,
    double? ratingVendorMax,
    int? jumlahPaketMin,
    int? jumlahPaketMax,
    String? jenisMedia,
    String? orderBy,
    String? orderDir,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print("========= GET PORTO: $id_customer");
    try {
      _portofolioList = await service.getAll(
        noId: noId,
        id_customer: id_customer,
        idVendor: idVendor,
        idMedia: idMedia,
        idKategori: idKategori,
        namaVendor: namaVendor,
        ratingVendorMin: ratingVendorMin,
        ratingVendorMax: ratingVendorMax,
        jumlahPaketMin: jumlahPaketMin,
        jumlahPaketMax: jumlahPaketMax,
        jenisMedia: jenisMedia,
        orderBy: orderBy,
        orderDir: orderDir,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> create(PortofolioModel model) async {
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

  Future<void> update(PortofolioModel model) async {
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
