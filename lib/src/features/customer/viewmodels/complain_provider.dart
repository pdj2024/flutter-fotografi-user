import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/utils/attachment_compressor.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';
import 'package:mpjnew/src/data/models/media_upload_model.dart';
import 'package:mpjnew/src/data/sqflite/complain_database.dart';
import 'package:mpjnew/src/features/customer/services/complain_service.dart';
import 'package:mpjnew/src/features/customer/services/media_service.dart';

class ComplainProvider with ChangeNotifier {
  final ComplainService _service = ComplainService();
  final ComplainDatabase _localService = ComplainDatabase.instance;

  // ── "Apakah order ini sudah punya Complain?" — cache per no_order,
  // dibayangi (mirrored) ke local storage sqflite supaya tidak perlu
  // menyimpan seluruh ComplainModel (termasuk Details) di memory.
  final Map<String, ComplainExistence?> _existsCache = {};
  final Map<String, bool> _checking = {};
  final Map<String, String?> _checkError = {};

  ComplainExistence? getCachedForOrder(String noOrder) => _existsCache[noOrder];
  bool isChecking(String noOrder) => _checking[noOrder] ?? false;
  String? getCheckError(String noOrder) => _checkError[noOrder];


  Future<void> checkForOrder(String noOrder) async {
    if (!_existsCache.containsKey(noOrder)) {
      final cached = await _localService.get(noOrder);
      if (cached != null) {
        _existsCache[noOrder] = cached;
        notifyListeners();
      }
    }

    _checking[noOrder] = true;
    _checkError[noOrder] = null;
    notifyListeners();
    try {
      final list = await _service.getGroup(noOrder: noOrder);
      if (list.isEmpty) {
        _existsCache[noOrder] = null;
      } else {
        final existence = ComplainExistence.fromComplain(list.first);
        _existsCache[noOrder] = existence;
        await _localService.put(noOrder, existence);
      }
    } catch (e) {
      _checkError[noOrder] = e.toString();
      // Sengaja TIDAK anggap "tidak ada" saat error — biar tombol tampilkan
      // retry, bukan salah izinkan bikin complain kedua gara-gara request gagal.
    } finally {
      _checking[noOrder] = false;
      notifyListeners();
    }
  }
  // ====================================================================


  // ── Thread yang sedang dibuka (satu per waktu) ──
  ComplainModel? _active;
  bool _isLoadingActive = false;
  String? _activeError;
  bool _isSending = false;

  ComplainModel? get active => _active;
  bool get isLoadingActive => _isLoadingActive;
  String? get activeError => _activeError;
  bool get isSending => _isSending;

  Future<void> loadActive({String? noOrder, String? noComplain}) async {
    _isLoadingActive = true;
    _activeError = null;
    notifyListeners();
    try {
      final list =
          await _service.getGroup(noOrder: noOrder, noComplain: noComplain);
      _active = list.isNotEmpty ? list.first : null;
      if (_active != null) {
        final existence = ComplainExistence.fromComplain(_active!);
        _existsCache[_active!.noOrder] = existence;
        await _localService.put(_active!.noOrder, existence);
      }
    } catch (e) {
      _activeError = e.toString();
    } finally {
      _isLoadingActive = false;
      notifyListeners();
    }
  }

  void setActive(ComplainModel model) {
    _active = model;
    _activeError = null;
    final existence = ComplainExistence.fromComplain(model);
    _existsCache[model.noOrder] = existence;
    _localService.put(model.noOrder, existence);
    notifyListeners();
  }

  // ====================================================================


  // ── Untuk Chat Complain ──
  /// Upload lampiran yang sudah dikompres di memory oleh [AttachmentCompressor].
  /// Batas 2MB tidak dicek lagi di sini — penolakan sudah terjadi saat user
  /// memilih gambar, jadi yang bisa gagal di titik ini cuma PUT/confirm.
  Future<({List<String> mediaIds, List<String> failed})> uploadAttachments(
    List<PreparedAttachment> items,
    String uploaderId,
  ) async {
    if (items.isEmpty) return (mediaIds: <String>[], failed: <String>[]);

    final failed = <String>[];
    try {
      final mediaService = MediaService();
      final uploadUrls = await mediaService.reqMediaURL(
        items.map((e) => e.extension).toList(),
        uploaderId,
      );

      final uploadResults = <MediaUploadModel>[];
      // Jangan indeks pakai panjang salah satu saja — server bisa saja
      // membalas jumlah URL yang berbeda dari jumlah file yang dikirim.
      final count =
          uploadUrls.length < items.length ? uploadUrls.length : items.length;
      for (var i = 0; i < count; i++) {
        final item = items[i];
        final ok = await mediaService.uploadMediaCloudBytes(
          bytes: item.bytes,
          uploadUrl: uploadUrls[i].uploadUrl,
        );
        // PUT gagal -> jangan ikut dikonfirmasi, supaya tidak terbit media id
        // yang menunjuk objek kosong.
        if (!ok) {
          failed.add(item.fileName);
          continue;
        }
        uploadResults.add(MediaUploadModel(
          idKategori: null,
          uploaderId: uploaderId,
          fileName: item.fileName,
          objectName: uploadUrls[i].objectName,
          originalSize: item.size,
          contentType: item.contentType,
          isSuccess: true,
        ));
      }
      for (var i = count; i < items.length; i++) {
        failed.add(items[i].fileName);
      }

      if (uploadResults.isEmpty) return (mediaIds: <String>[], failed: failed);

      final result =
          await mediaService.confirmationUploadMedia(uploadResults, uploaderId);
      final mediaIds = (result is Map && result['success'] == true)
          ? List<String>.from(result['mediaIds'] ?? [])
          : <String>[];
      return (mediaIds: mediaIds, failed: failed);
    } catch (e) {
      _activeError = 'Gagal upload lampiran: $e';
      notifyListeners();
      return (mediaIds: <String>[], failed: failed);
    }
  }

  /// Dipanggil pull-to-refresh DAN hook refetch dari FCM.
  Future<void> refreshActive() async {
    if (_active == null) return;
    await loadActive(
        noComplain: _active!.noComplain, noOrder: _active!.noOrder);
  }

  Future<bool> createComplain({
    required String noOrder,
    required String senderId,
    required String tipeUser,
    required String judul,
    required String message,
    List<String>? idMedia,
  }) async {
    _isSending = true;
    notifyListeners();
    try {
      await _service.sendMessage(
        noOrder: noOrder,
        senderId: senderId,
        tipeUser: tipeUser,
        judul: judul,
        message: message,
        noComplain: '',
        idMedia: idMedia,
      );
      await loadActive(noOrder: noOrder);
      return true;
    } catch (e) {
      _activeError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> sendReply({
    required String senderId,
    required String tipeUser,
    required String message,
    List<String>? idMedia,
  }) async {
    if (_active == null || _active!.isClosed) return false;
    _isSending = true;
    notifyListeners();
    try {
      await _service.sendMessage(
        noOrder: _active!.noOrder,
        senderId: senderId,
        tipeUser: tipeUser,
        message: message,
        noComplain: _active!.noComplain,
        idMedia: idMedia,
      );
      await refreshActive();
      return true;
    } catch (e) {
      _activeError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Hook FCM: hanya refetch kalau notif ini untuk thread yang lagi dibuka.
  /// Juga refresh list Complain (Setting) kalau pernah dibuka sesi ini,
  /// supaya last-message/urutannya ikut update tanpa perlu refresh manual.
  void onComplainDetailPushReceived({String? noComplain, String? noOrder}) {
    // Pencocokan berdasarkan noComplain & noOrder
    final matches = _active != null &&
        ((noComplain != null && noComplain == _active!.noComplain) ||
            (noOrder != null && noOrder == _active!.noOrder));
    if (matches) {
      refreshActive();
    }
    if (_lastHeaderSenderId != null) loadHeaders(_lastHeaderSenderId!);
  }

  /// FCM komplain_header: complain baru muncul, atau ditutup admin.
  /// - Invalidate cache "order ini punya complain?" -> tombol di halaman
  ///   order akan re-check pas dibuka lagi (kasus baru-muncul).
  /// - Refresh thread aktif kalau itu yang lagi dibuka (kasus ditutup).
  /// - Refresh ComplainListPage kalau pernah dibuka sesi ini.
  String? _lastHeaderSenderId;

  void onComplainHeaderPushReceived({String? noComplain, String? noOrder}) {
    if (noOrder != null) {
      _existsCache.remove(noOrder);
      _localService.remove(noOrder);
    }
    if (noComplain != null &&
        _active != null &&
        _active!.noComplain == noComplain) {
      refreshActive();
    }
    if (_lastHeaderSenderId != null) loadHeaders(_lastHeaderSenderId!);
  }
  // ====================================================================


  void clearActive() {
    _active = null;
    _activeError = null;
    notifyListeners();
  }

  // ── List ringkas — dipakai menu "Complain" di halaman Setting ──
  List<ComplainHeaderModel> _headers = [];
  bool _isLoadingHeaders = false;
  String? _headersError;

  List<ComplainHeaderModel> get headers => _headers;
  bool get isLoadingHeaders => _isLoadingHeaders;
  String? get headersError => _headersError;

  /// Tanpa filter status -> balikin aktif + selesai sekaligus.
  ///
  /// [reset] mengosongkan daftar lama dulu — dipakai saat halaman baru dibuka
  /// supaya tidak sempat menampilkan data sesi sebelumnya lalu berganti
  /// sendiri. Pull-to-refresh & refresh dari FCM memakai `false` agar daftar
  /// yang sedang dilihat tidak berkedip kosong.
  Future<void> loadHeaders(String senderId, {bool reset = false}) async {
    _lastHeaderSenderId = senderId;
    if (reset) _headers = [];
    _isLoadingHeaders = true;
    _headersError = null;
    notifyListeners();
    try {
      _headers = await _service.getHeader(senderId: senderId);
      _headers.sort((a, b) {
        final aTime = a.lastUpdated ?? a.tglCreated ?? DateTime(0);
        final bTime = b.lastUpdated ?? b.tglCreated ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
    } catch (e) {
      _headersError = e.toString();
    } finally {
      _isLoadingHeaders = false;
      notifyListeners();
    }
  }
}
