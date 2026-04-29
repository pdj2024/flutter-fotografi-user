# Fotografi Customer App

> **Confidential — Property of Pacific Data Jaya**

Aplikasi mobile berbasis Flutter untuk pelanggan layanan fotografi. Platform ini menghubungkan pelanggan dengan vendor fotografi, mencakup pencarian vendor, pemesanan paket, pembayaran, chat real-time, dan pelacakan progres pesanan.

---

## Daftar Isi

- [Gambaran Umum](#gambaran-umum)
- [Fitur Utama](#fitur-utama)
- [Arsitektur](#arsitektur)
- [Struktur Folder](#struktur-folder)
- [Tech Stack](#tech-stack)
- [Dependencies](#dependencies)
- [Setup & Instalasi](#setup--instalasi)
- [Konfigurasi](#konfigurasi)
- [Alur Navigasi](#alur-navigasi)
- [Manajemen State](#manajemen-state)
- [Sistem Penyimpanan Lokal](#sistem-penyimpanan-lokal)
- [Notifikasi Push (FCM)](#notifikasi-push-fcm)
- [Integrasi Pembayaran](#integrasi-pembayaran)
- [Model Data](#model-data)

---

## Gambaran Umum

| Properti        | Nilai                                          |
|-----------------|------------------------------------------------|
| **Nama App**    | mpjnew (Aplikasi Fotografi Customer)           |
| **Versi**       | 1.0.6+12                                       |
| **Platform**    | Android                                        |
| **Framework**   | Flutter (Dart SDK ^3.5.3)                      |
| **Base API**    | `https://fotoapi1.padajaya.biz.id/api`         |
| **Owner**       | Pacific Data Jaya                              |

---

## Fitur Utama

Aplikasi memiliki 4 modul utama yang ditampilkan lewat bottom navigation bar:

### 1. Home / Explore
- Melihat daftar vendor fotografi
- Pencarian vendor berdasarkan nama atau kategori
- Melihat portofolio dan paket fotografer
- Filter berdasarkan kota dan kategori
- Menyimpan vendor ke daftar favorit

### 2. Chat / Pesan
- Percakapan real-time antara pelanggan dan vendor
- Berbagi paket, penawaran, dan detail pesanan melalui chat
- Mendukung pesan teks dan gambar
- Status pengiriman pesan: pending → sent → received → read
- Offline-first: pesan tersimpan di Isar DB dan disinkron saat online
- Notifikasi pesan baru via FCM

### 3. Pesanan / Riwayat
- Pesanan belum dibayar (dengan aksi pembayaran langsung)
- Pesanan sedang berjalan (dengan timeline progres status)
- Pesanan selesai (dengan opsi ulasan)
- Pelacakan status progres fotografi secara rinci
- Unduh hasil foto melalui link

### 4. Akun / Profil
- Kelola profil pelanggan
- Pengaturan aplikasi
- Halaman syarat & ketentuan / legal
- Logout

### Fitur Lintas Modul
- Autentikasi via Google OAuth (Firebase Auth)
- Pembayaran via Midtrans (VA, QRIS, payment link)
- Notifikasi push (chat, progres pesanan, ulasan, pembayaran)
- Pengecekan versi aplikasi otomatis
- Dukungan lokasi dan peta (Google Maps)
- Upload dan crop gambar

---

## Arsitektur

Aplikasi menggunakan pola **MVVM (Model-View-ViewModel)** dengan **Provider** sebagai state management.

```
┌──────────────────────────────────────────────────┐
│                   UI Layer (View)                │
│         Pages, Widgets, Dialogs, Shimmer         │
└─────────────────────┬────────────────────────────┘
                      │ notifyListeners / watch
┌─────────────────────▼────────────────────────────┐
│             ViewModel Layer (Provider)            │
│     ChangeNotifier classes — business logic,     │
│     state, formatting, coordination              │
└─────────────────────┬────────────────────────────┘
                      │ calls
┌─────────────────────▼────────────────────────────┐
│              Service Layer                        │
│   API Services, Local Storage, FCM, Auth         │
└─────────────────────┬────────────────────────────┘
                      │ reads/writes
┌─────────────────────▼────────────────────────────┐
│              Data Layer                           │
│   Models, Hive Entities, Isar Entities, SQLite   │
└──────────────────────────────────────────────────┘
```

---

## Struktur Folder

```
lib/
├── main.dart                        # Entry point — inisialisasi Firebase, Hive, Isar, Provider DI
└── src/
    ├── features/
    │   ├── auth/
    │   │   ├── services/
    │   │   │   └── user_provider.dart          # State autentikasi & profil user
    │   │   ├── view/
    │   │   │   └── user_login.dart             # Halaman login Google
    │   │   └── widget/
    │   │       └── role_card.dart
    │   │
    │   └── customer/
    │       ├── services/                        # Lapisan akses API
    │       │   ├── paket_service.dart
    │       │   ├── vendor_service.dart
    │       │   ├── pesanan_service.dart
    │       │   ├── penawaran_service.dart
    │       │   ├── portofolio_service.dart
    │       │   ├── customer_service.dart
    │       │   ├── kategori_service.dart
    │       │   ├── kota_service.dart
    │       │   ├── history_order_service.dart
    │       │   ├── device_token_service.dart
    │       │   └── local_storage_service.dart
    │       │
    │       ├── viewmodels/                      # ChangeNotifier — state & logika bisnis
    │       │   ├── chat_provider.dart           # State chat (Isar offline-first)
    │       │   ├── pesanan_provider.dart        # State pesanan (Hive cache)
    │       │   ├── paket_provider.dart
    │       │   ├── vendor_provider.dart
    │       │   ├── portofolio_provider.dart
    │       │   ├── history_order_provider.dart
    │       │   ├── kategori_provider.dart
    │       │   ├── order_tab_provider.dart
    │       │   ├── room_chat_provider.dart
    │       │   └── penawaran_provider.dart
    │       │
    │       ├── view/
    │       │   ├── main_menu.dart               # Shell navigasi 4 tab
    │       │   ├── customer_home_page.dart      # Tab Home
    │       │   ├── search_page.dart
    │       │   ├── vendor_bio_page.dart
    │       │   ├── single_post_page.dart
    │       │   ├── paket_ulasan_list_page.dart
    │       │   │
    │       │   ├── chat/
    │       │   │   ├── chat_list_page.dart      # Tab Chat — daftar room
    │       │   │   ├── room_chat_page.dart      # Halaman pesan dalam room
    │       │   │   ├── domain/
    │       │   │   └── data/service/
    │       │   │       └── chat_api_service.dart
    │       │   │
    │       │   ├── history/
    │       │   │   ├── main_order_page.dart     # Tab Pesanan (3 sub-tab)
    │       │   │   ├── detail_order_page_V2.dart
    │       │   │   ├── finished_order_page.dart
    │       │   │   ├── webview_page.dart        # Webview payment gateway
    │       │   │   └── widget/
    │       │   │
    │       │   ├── account/
    │       │   │   ├── customer_account_page.dart  # Tab Akun
    │       │   │   ├── edit_account_page.dart
    │       │   │   ├── setting_page.dart
    │       │   │   └── legal_page.dart
    │       │   │
    │       │   └── payment/
    │       │       ├── detail_pembayaran_page.dart
    │       │       └── waiting_payment_page.dart
    │       │
    │       └── widget/                          # Komponen UI yang dipakai ulang
    │           ├── dialog/
    │           ├── payment/
    │           ├── field/
    │           ├── shimmer/
    │           └── (chat bubbles, cards, etc.)
    │
    ├── data/
    │   ├── models/                              # Model respons API (plain Dart class)
    │   │   ├── vendor_model.dart
    │   │   ├── customer_model.dart
    │   │   ├── chat_model.dart
    │   │   ├── room_chat_model.dart
    │   │   ├── history_order_model.dart
    │   │   ├── payment_model.dart
    │   │   └── ...
    │   │
    │   ├── hive_entity/                         # Model cache lokal (Hive)
    │   │   ├── pesanan_model.dart               # Pesanan tersimpan offline
    │   │   ├── paket_model.dart
    │   │   ├── penawaran_model.dart
    │   │   └── portofolio_model.dart
    │   │
    │   ├── isar/                                # Database chat offline (Isar)
    │   │   ├── data/
    │   │   │   ├── chat_message_entity.dart
    │   │   │   └── room_chat_entity.dart
    │   │   └── service/
    │   │       ├── chat_isar_service.dart       # CRUD Isar
    │   │       ├── chat_storage_service.dart    # Antrian pesan FCM
    │   │       └── chat_sync_service.dart       # Sinkronisasi API ↔ Isar
    │   │
    │   └── repositories/
    │
    └── core/
        ├── services/
        │   ├── api_client.dart                  # HTTP client (retry, token refresh)
        │   ├── auth_service_instance.dart       # Singleton auth
        │   ├── token_storage_service.dart       # Penyimpanan token aman
        │   ├── cache_manager.dart               # Cache gambar
        │   ├── version_check_service.dart
        │   │
        │   └── fcm/                             # Firebase Cloud Messaging
        │       ├── fcm_service.dart
        │       ├── handlers/
        │       │   ├── chat_notification_handler.dart
        │       │   ├── payment_notification_handler.dart
        │       │   └── progres_notification_handler.dart
        │       └── utils/
        │
        ├── routing/
        │   └── navigation_provider.dart         # Navigasi terpusat (multi-navigator)
        │
        └── constants/
            ├── constants.dart                   # Warna, URL, konfigurasi app
            ├── text_style.dart
            ├── status_progres_constant.dart
            └── helper.dart
```

---

## Tech Stack

| Lapisan              | Teknologi                                         |
|----------------------|---------------------------------------------------|
| UI Framework         | Flutter + Material Design 3                       |
| State Management     | Provider (ChangeNotifier)                         |
| Backend API          | REST HTTP — ApiClient custom (retry, token refresh)|
| Autentikasi          | Google OAuth + Firebase Auth                      |
| Real-time / Push     | Firebase Cloud Messaging (FCM)                    |
| Database Lokal Chat  | Isar (offline-first)                              |
| Cache Lokal          | Hive (pesanan, paket, portofolio)                 |
| Preferensi           | SharedPreferences                                 |
| Token Aman           | FlutterSecureStorage                              |
| Pembayaran           | Midtrans SDK (VA, QRIS, payment link)             |
| Peta                 | Google Maps Flutter + Geolocator                  |
| Media                | ImagePicker, ImageCropper, VideoEditor            |
| Notifikasi Lokal     | FlutterLocalNotifications                         |
| Fonts                | Google Fonts                                      |
| Lokalisasi           | intl (ID, EN)                                     |

---

## Dependencies

### State & DI
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `provider` | ^6.1.2 | State management utama |
| `equatable` | ^2.0.8 | Perbandingan objek |

### Firebase
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `firebase_core` | ^3.2.0 | Inisialisasi Firebase |
| `firebase_auth` | ^5.1.2 | Autentikasi |
| `firebase_messaging` | latest | Push notification |
| `firebase_storage` | ^12.1.1 | Storage file |
| `cloud_firestore` | latest | Database cloud |

### Storage Lokal
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `hive` | ^2.2.3 | NoSQL cache (pesanan, paket) |
| `hive_flutter` | ^1.1.0 | Integrasi Hive dengan Flutter |
| `sqflite` | latest | SQLite |
| `shared_preferences` | ^2.2.2 | KV storage |
| `flutter_secure_storage` | ^10.0.0 | Penyimpanan token aman |

### UI & Media
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `shimmer` | ^3.0.0 | Loading skeleton |
| `google_fonts` | ^8.0.2 | Custom font |
| `flutter_expandable_fab` | ^2.5.2 | Expandable FAB |
| `fl_chart` | ^0.68.0 | Chart/grafik |
| `cached_network_image` | latest | Gambar dengan cache |
| `image_picker` | ^1.0.4 | Pilih gambar dari galeri/kamera |
| `image_cropper` | ^9.1.0 | Crop gambar |
| `video_editor` | ^3.0.0 | Editor video |
| `video_player` | ^2.8.1 | Putar video |
| `photo_manager` | ^3.0.0 | Akses galeri |
| `webview_flutter` | ^4.13.1 | WebView |
| `flutter_html` | ^3.0.0 | Render HTML |

### Lokasi & Peta
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `google_maps_flutter` | ^2.5.0 | Tampilan peta |
| `geolocator` | ^13.0.1 | GPS |
| `geocoding` | ^3.0.0 | Konversi koordinat ↔ alamat |
| `location_picker_flutter_map` | ^1.1.0 | Picker lokasi interaktif |

### Utilitas
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `intl` | ^0.20.2 | Format tanggal, angka, i18n |
| `url_launcher` | ^6.1.14 | Buka URL eksternal |
| `permission_handler` | ^11.0.1 | Manajemen izin perangkat |
| `connectivity_plus` | ^7.0.0 | Cek koneksi jaringan |
| `midtrans_sdk` | ^0.4.0 | Payment gateway |
| `google_sign_in` | ^6.1.6 | Login Google |
| `uuid` | ^4.2.1 | Generate UUID |
| `decimal` | ^3.0.2 | Perhitungan desimal presisi |
| `workmanager` | ^0.9.0+3 | Background task |
| `flutter_background_service` | ^5.0.5 | Layanan background |
| `flutter_foreground_task` | ^9.1.0 | Foreground service |
| `wakelock_plus` | ^1.4.0 | Cegah layar mati |

### Dev Dependencies
| Package | Versi | Kegunaan |
|---------|-------|----------|
| `hive_generator` | ^2.0.1 | Code gen adapter Hive |
| `build_runner` | 2.4.13 | Code generation |
| `flutter_launcher_icons` | ^0.14.4 | Generate ikon launcher |
| `flutter_native_splash` | ^2.4.7 | Splash screen native |

---

## Setup & Instalasi

### Prasyarat
- Flutter SDK ^3.5.3
- Dart SDK (bundled dengan Flutter)
- Android Studio / VS Code
- Firebase project yang sudah dikonfigurasi
- Google Maps API key
- Midtrans merchant key

### Langkah Instalasi

**1. Clone repository**
```bash
git clone <repository-url>
cd flutter-fotografi-user
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Generate kode Hive**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**4. Generate splash screen & launcher icon**
```bash
dart run flutter_native_splash:create
dart run flutter_launcher_icons
```

**5. Jalankan aplikasi**
```bash
flutter run
```

---

## Konfigurasi

### Firebase
Pastikan file konfigurasi berikut sudah ada:
- `android/app/google-services.json` — Firebase Android config

### API & Kunci

Konfigurasi utama ada di [lib/src/core/constants/constants.dart](lib/src/core/constants/constants.dart):

```dart
// Base URL API backend
static const String baseUrl = 'https://fotoapi1.padajaya.biz.id/api';

// Midtrans
static const String midtransClientKey = '...';
```

### Google Maps
Tambahkan API key di `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### Konfigurasi Android Tambahan
- **Min SDK:** 21
- **Target SDK:** 34
- **16KB page size support:** Aktif (dikonfigurasi di `build.gradle`)
- **Multidex:** Aktif

---

## Alur Navigasi

Aplikasi menggunakan arsitektur **multi-navigator** dengan bottom navigation bar 4 tab. Setiap tab memiliki `GlobalKey<NavigatorState>` sendiri sehingga stack navigasi masing-masing tab bersifat independen.

```
MyApp
└── SplashScreen
    ├── UserLoginPage          (jika belum login)
    └── MainMenu               (jika sudah login)
        ├── Tab 0: CustomerHomePage
        │   ├── SearchPage
        │   ├── VendorBioPage
        │   ├── SinglePostPage
        │   └── VendorListPackagePage
        │
        ├── Tab 1: ChatListPage
        │   └── RoomChatPage
        │
        ├── Tab 2: MainOrderPage
        │   ├── DetailOrderPageV2
        │   ├── DetailPembayaranPage
        │   ├── WaitingPaymentPage
        │   ├── WebviewPage       (Midtrans)
        │   └── FinishedOrderPage
        │
        └── Tab 3: CustomerAccountPage
            ├── EditAccountPage
            ├── SettingPage
            └── LegalPage
```

**Deep linking via notifikasi:** FCM dapat langsung membuka halaman tertentu (misalnya room chat atau detail pesanan) saat notifikasi diklik.

---

## Manajemen State

State management menggunakan **Provider** (`ChangeNotifier`). Semua provider di-inject secara global di `main.dart` via `MultiProvider`.

| Provider | Tanggung Jawab |
|----------|---------------|
| `UserProvider` | Status login, profil pelanggan, token FCM |
| `NavigationProvider` | Tab aktif, navigator per-tab, routing |
| `ChatProvider` | Daftar room chat, sinkron Isar ↔ API |
| `RoomChatProvider` | Pesan dalam satu room, send & receive |
| `PesananProvider` | Pesanan aktif (Hive cache + API) |
| `HistoryOrderProvider` | Riwayat pesanan selesai |
| `VendorProvider` | Daftar vendor, filter, pencarian |
| `PaketProvider` | Paket fotografi vendor |
| `PortofolioProvider` | Portofolio vendor |
| `KategoriProvider` | Kategori layanan |
| `PenawaranProvider` | Penawaran dari vendor |
| `OrderTabProvider` | State sub-tab pada halaman pesanan |

---

## Sistem Penyimpanan Lokal

Aplikasi menggunakan tiga lapisan penyimpanan lokal:

### 1. Isar — Chat (Offline-First)
Digunakan untuk menyimpan pesan chat agar dapat dibaca tanpa koneksi.

- **`ChatMessageEntity`** — Pesan individual
- **`RoomChatEntity`** — Data room chat
- **`ChatIsarService`** — CRUD operasi Isar
- **`ChatStorageService`** — Antrian pesan dari FCM saat app di background
- **`ChatSyncService`** — Sinkronisasi dua arah antara Isar dan server

### 2. Hive — Cache Data (Pesanan, Paket, dll.)
Digunakan untuk cache data yang sering diakses agar respons UI lebih cepat.

- **`PesananModel`** — Cache pesanan aktif
- **`PaketModel`** — Cache paket fotografi
- **`PenawaranModel`** — Cache penawaran
- **`PortofolioModel`** — Cache portofolio
- **`MediaUrlModel`** — Cache URL media

### 3. SharedPreferences & FlutterSecureStorage
- `SharedPreferences` — Preferensi user, flag onboarding
- `FlutterSecureStorage` — Token autentikasi (disimpan terenkripsi)

---

## Notifikasi Push (FCM)

Sistem notifikasi menggunakan Firebase Cloud Messaging dengan arsitektur berbasis handler terpisah per tipe.

### Tipe Notifikasi

| Tipe | Handler | Aksi |
|------|---------|------|
| `chat` | `ChatNotificationHandler` | Simpan pesan ke Isar, tampilkan notifikasi |
| `progres` | `ProgresNotificationHandler` | Update status pesanan, notifikasi |
| `payment` | `PaymentNotificationHandler` | Update status bayar, notifikasi |
| `review` | *(via FCM service)* | Reminder ulasan |

### Alur FCM

```
FCM Message diterima
    │
    ├─ App di Foreground → FCMService.handleForegroundMessage()
    │       └─ Handler spesifik → update state + notifikasi lokal
    │
    ├─ App di Background → onBackgroundMessage()
    │       └─ ChatStorageService.enqueue() → Isar antrian
    │
    └─ App ditutup (terminated) → onMessageOpenedApp()
            └─ NavigationProvider.navigateFromNotification()
```

---

## Integrasi Pembayaran

Pembayaran menggunakan **Midtrans SDK** dengan mendukung tiga metode:

| Metode | Widget | Keterangan |
|--------|--------|------------|
| Virtual Account (VA) | `VaPaymentCard` | Transfer bank |
| QRIS | `QrisPaymentCard` | Scan QR code |
| Payment Link | `CounterPaymentCard` | Link ke halaman Midtrans |

**Alur Pembayaran:**
1. Pelanggan memilih pesanan yang belum dibayar
2. Buka `DetailPembayaranPage` — tampil metode bayar
3. Pilih metode → arahkan ke `WaitingPaymentPage` atau `WebviewPage`
4. Setelah Midtrans mengkonfirmasi → FCM kirim notifikasi payment
5. `PaymentNotificationHandler` update status pesanan

---

## Model Data

### CustomerModel
```
noId, userName, namaDisplay, email, kota,
status, pernahOrder, saves (favorit), likes, deviceTokens
```

### VendorModel
```
noId, username, email, kota, rating,
portofolio[], paket[], hargaMin, hargaMax, deskripsiBio
```

### PesananModel (Hive Entity)
```
noBukti, status, statusProgresPesanan
idVendor, idCustomer, namaVendor, namaCustomer
idPaket, namaPaket, harga
lokasi, kota, tglRealisasi
metodeBayar, statusBayar, midtransOrderId, paymentNumbers
linkUrl (hasil foto), createdAt, updatedAt
```

### ChatModel
```
messageId, roomId, senderId, message,
jenisPesan (text | image | paket | penawaran | pesanan),
sendStatus (pending | sent | received | read | failed)
```

### PaymentModel
```
idPaymentGateway, status, expiryTime, paymentLink,
vaNumbers[], qrisUrl
```

### HistoryOrderModel
```
noOrder, statusProgressPesanan, tglUpdate, description
```

---

## API Client

`ApiClient` di [lib/src/core/services/api_client.dart](lib/src/core/services/api_client.dart) adalah HTTP client kustom dengan fitur:

- **Token refresh otomatis** — Jika respons 401, coba refresh token Firebase lalu ulangi request
- **Retry dengan exponential backoff** — Maksimal 3 percobaan untuk error jaringan
- **Header standar** — `Authorization`, `X-Jenis-User: Customer`, `X-User-Role`
- **Session expiry handling** — Jika refresh gagal, logout otomatis dan arahkan ke login

---

*Dokumentasi ini dibuat berdasarkan analisis kode sumber versi 1.0.6+12.*
