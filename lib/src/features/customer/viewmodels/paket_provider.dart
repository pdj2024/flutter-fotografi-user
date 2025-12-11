import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';

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

  Future<List<PaketModel>> fetchPaketFromRoom(List<ChatModel> messages) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paketServ = PaketService();

      print(messages);

      // 2. Kumpulkan idPaket yang tidak null
      print("=== KUMPULKAN ID PAKET");
      final Set<String> paketIds = {};

      for (final msg in messages) {
        if (msg.idPaket != null && msg.idPaket!.isNotEmpty) {
          paketIds.add(msg.idPaket!);
        }
      }
      print("ID Paket dalam room ini: $paketIds");

      // Jika tidak ada paket, kembalikan list kosong
      if (paketIds.isEmpty) {
        print("Tidak ada paket dalam room ini");
        return [];
      }

      print("ID Paket ditemukan dalam chat: $paketIds");

      // 3. Fetch semua paket berdasarkan ID
      final paketList = await paketServ.getAll(idList: paketIds.toList());

      return paketList;
    } catch (e) {
      _error = e.toString();
      print("Error: $e");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
