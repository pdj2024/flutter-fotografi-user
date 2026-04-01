import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';

class PenawaranProvider with ChangeNotifier {
  final PenawaranService penawaranService;

  PenawaranProvider({required this.penawaranService});

  // ===== Variables =====
  List<PenawaranModel> _penawaranList = [];
  bool _isLoadingOffer = true;
  String? _errorOffer;

  // ===== Getters =====
  List<PenawaranModel> get penawaranList => _penawaranList;
  bool get isLoadingOffer => _isLoadingOffer;
  set isLoadingOffer(bool value) {
    _isLoadingOffer = value;
    notifyListeners();
  }

  String? get errorOffer => _errorOffer;
  set errorOffer(String? value) {
    _errorOffer = value;
    notifyListeners();
  }

  Future<void> loadOffer({
    required String userId,
    String? vendorId,
    String status = 'aktif',
  }) async {
    _isLoadingOffer = true;
    _errorOffer = null;
    notifyListeners();

    try {
      final result = await penawaranService.getAll(
          status: status, idCustomer: userId, idVendor: vendorId);

      debugPrint("RESULT PENAWRAN PROVIDER => $result");

      _penawaranList = result;
    } catch (e) {
      _errorOffer = "Error memuat Penawaran";
    } finally {
      _isLoadingOffer = false;
      notifyListeners();
    }
  }

  Future<void> refresh({required String userId}) async {
    await loadOffer(userId: userId);
  }

  Future<List<PenawaranModel>> fetchPenawaranFromRoom(
      List<ChatModel> messages) async {
    _errorOffer = null;
    notifyListeners();

    try {
      final penawaranServ = PenawaranService();

      debugPrint(messages.toString());

      // 2. Kumpulkan no invoice yang tidak null
      debugPrint("=== KUMPULKAN ID Penawaran");
      final Set<String> penawaranIds = {};

      for (final msg in messages) {
        if (msg.noPenawaran != null && msg.noPenawaran!.isNotEmpty) {
          penawaranIds.add(msg.noPenawaran!);
        }
      }
      debugPrint("ID Penawaran dalam room ini: $penawaranIds");

      // Jika tidak ada paket, kembalikan list kosong
      if (penawaranIds.isEmpty) {
        debugPrint("Tidak ada penawaran dalam room ini");
        return [];
      }

      debugPrint("ID penawaran ditemukan dalam chat: $penawaranIds");

      // 3. Fetch semua paket berdasarkan ID
      final penawaranlist =
          await penawaranServ.getAll(idList: penawaranIds.toList());

      return penawaranlist;
    } catch (e) {
      _errorOffer = e.toString();
      debugPrint("Error: $e");
      return [];
    } finally {
      notifyListeners();
    }
  }
}
