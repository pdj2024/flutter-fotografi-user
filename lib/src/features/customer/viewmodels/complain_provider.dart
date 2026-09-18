import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/utils/attachment_compressor.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';
import 'package:mpjnew/src/data/models/media_upload_model.dart';
import 'package:mpjnew/src/data/sqflite/complain_database.dart';
import 'package:mpjnew/src/features/customer/services/complain_service.dart';
import 'package:mpjnew/src/features/customer/services/media_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kComplainPendingRefetchKey = 'complain_pending_refetch';
const _kActiveComplainKey = 'complain_active_id';

class ComplainProvider with ChangeNotifier {
  final ComplainService _service = ComplainService();
  final ComplainDatabase _localService = ComplainDatabase.instance;

  // ═══════════════════════════════════════════════════════════════════════
  // DRAINED MESSAGE — antrean "thread mana yang perlu di-refetch"
  //
  // Beda dengan chat: Complain tidak punya tabel pesan lokal (cuma cache
  // existence "apakah order ini punya complain" di ComplainDatabase), dan
  // payload FCM complain cuma bawa ID (No_Complain/No_Order) + judul/body
  // notifikasi siap tampil -- tidak pernah bawa isi pesan. Jadi antrean ini
  // TIDAK bisa merekonstruksi pesan dari data lokal seperti chat
  // (_kBgQueueKey/enqueueBackgroundMessage) -- satu-satunya yang bisa
  // disimpan adalah "id complain ini butuh refetch", dan drain-nya SELALU
  // berujung ke network call (getGroup/refreshActive), bukan insert lokal.
  // Target realistisnya: pesan pasti muncul begitu user buka/resume ke
  // thread itu, tanpa perlu pull-to-refresh manual -- bukan "tersedia
  // instan offline" seperti chat.
  static Future<void> enqueuePendingComplainRefetch(String id) async {
    if (id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_kComplainPendingRefetchKey) ?? [];
      if (!existing.contains(id)) {
        existing.add(id);
        final trimmed =
            existing.length > 100 ? existing.sublist(existing.length - 100) : existing;
        await prefs.setStringList(_kComplainPendingRefetchKey, trimmed);
        debugPrint('[ComplainProvider] 📋 Pending refetch enqueued: $id');
      }
    } catch (e) {
      debugPrint('[ComplainProvider] ⚠️ enqueuePendingComplainRefetch: $e');
    }
  }

  static Future<List<String>> getPendingComplainRefetchIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // SharedPreferences instance di-cache in-memory per isolate sejak
      // panggilan pertama (biasanya jauh sebelum ini, saat app boot).
      // FCM background handler menulis id baru dari ISOLATE TERPISAH --
      // tanpa reload(), isolate utama (tempat app UI/lifecycle observer
      // hidup, sudah lama pegang instance lama) tidak pernah melihat
      // tulisan itu sampai app benar-benar di-restart. reload() paksa
      // baca ulang dari native storage supaya id yang baru saja diantre
      // dari background ikut kebaca di sini.
      await prefs.reload();
      return prefs.getStringList(_kComplainPendingRefetchKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Hapus SATU id dari antrean — bukan clear semua, supaya id lain yang
  /// belum berhasil diproses tidak ikut hilang kalau satu drain gagal.
  static Future<void> removePendingComplainRefetch(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_kComplainPendingRefetchKey) ?? [];
      if (existing.remove(id)) {
        await prefs.setStringList(_kComplainPendingRefetchKey, existing);
      }
    } catch (e) {
      debugPrint('[ComplainProvider] ⚠️ removePendingComplainRefetch: $e');
    }
  }

  static Future<void> setActiveComplainPref(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null || id.isEmpty) {
        await prefs.remove(_kActiveComplainKey);
      } else {
        await prefs.setString(_kActiveComplainKey, id);
      }
    } catch (e) {
      debugPrint('[ComplainProvider] ⚠️ setActiveComplainPref: $e');
    }
  }

  static Future<String?> getActiveComplainPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kActiveComplainKey);
    } catch (_) {
      return null;
    }
  }

  /// Dipanggil saat thread dibuka dan saat app resume (lihat
  /// ComplainThreadPage._init()/didChangeAppLifecycleState). Cuma
  /// memastikan thread yang lagi dibuka ikut ter-refresh; untuk thread lain
  /// yang tidak sedang dibuka, cukup invalidate cache existence-nya supaya
  /// indikator "sudah ada complain?" re-check saat order-nya dibuka lagi.
  Future<void> drainPendingComplainRefetch() async {
    final ids = await getPendingComplainRefetchIds();
    debugPrint('[ComplainProvider] 🔄 Draining pending complain refetch: $ids');
    if (ids.isEmpty) return;
    for (final id in ids) {
      final matchesActive = _active != null &&
          (_active!.noComplain == id || _active!.noOrder == id);
      try {
        if (matchesActive) {
          await refreshActive();
        } else {
          _existsCache.remove(id);
          await _localService.remove(id);
        }
        await removePendingComplainRefetch(id);
      } catch (e) {
        debugPrint('[ComplainProvider] ⚠️ drainPendingComplainRefetch($id): $e');
        // Biarkan di antrean — dicoba lagi drain berikutnya.
      }
    }
  }
  // ═══════════════════════════════════════════════════════════════════════

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

  /// Tutup complain yang sedang aktif (aksi customer, dari menu titik-tiga
  /// di thread page). PUT /complain/update-header bersifat FULL-REPLACE --
  /// field yang tidak dikirim akan ditimpa kosong -- jadi field lengkap
  /// (Prioritas/Assigned_To/Hasil_Akhir/dll, yang tidak ada di ComplainModel
  /// dari get-group) HARUS dibaca dulu lewat get-header sebelum PUT, supaya
  /// nilai yang mungkin sudah diisi admin tidak ikut hilang.
  Future<bool> closeComplain({String hasilAkhir = ''}) async {
    if (_active == null) return false;
    final noComplain = _active!.noComplain;
    try {
      final headers = await _service.getHeader(
        senderId: _active!.idCustomer,
        noComplain: noComplain,
      );
      final current = headers.firstOrNull;
      if (current == null) {
        _activeError = 'Data complain tidak ditemukan untuk ditutup';
        notifyListeners();
        return false;
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _service.updateHeader(noComplain: noComplain, body: {
        'No_Order': current.noOrder,
        'Sender_Id': current.senderId,
        'Tipe_User': current.tipeUser,
        'Judul': current.judul,
        'Status': 'selesai',
        'Tgl_Closed': nowIso,
        'Prioritas': current.prioritas,
        'Assigned_To': current.assignedTo,
        'Hasil_Akhir': hasilAkhir.isNotEmpty ? hasilAkhir : current.hasilAkhir,
        'Last_Complain': null,
        'Last_Complain_At': null,
      });

      _active = _active!.copyWith(
        status: 'selesai',
        tglClosed: DateTime.tryParse(nowIso),
      );
      final existence = ComplainExistence.fromComplain(_active!);
      _existsCache[_active!.noOrder] = existence;
      await _localService.put(_active!.noOrder, existence);
      notifyListeners();
      return true;
    } catch (e) {
      _activeError = e.toString();
      notifyListeners();
      return false;
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
      // Refetch + isi ulang cache (bukan sekadar invalidate) supaya
      // halaman detail order yang sedang terbuka (Consumer2<PesananProvider,
      // ComplainProvider>) ikut rebuild lewat notifyListeners() di
      // checkForOrder(), tanpa perlu navigasi ulang/pull-to-refresh manual.
      checkForOrder(noOrder);
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
