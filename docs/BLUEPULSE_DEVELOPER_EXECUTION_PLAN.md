# Master Execution Plan: BluePulse Mobile BLE Tracker
**Target Role:** Senior Flutter Developer Agent  
**Architect:** Software Architect  
**Project Baseline:** `blue_pulse` (`com.bluepulse.app`)  
**Base Commit:** `be69303`  
**Framework:** Flutter 3.47+ / Dart 3.13+ (Targeting Android & iOS)

---

## 1. Mission Overview & Boundaries

Anda ditugaskan mengimplementasikan aplikasi **BluePulse** secara *end-to-end* sesuai spesifikasi studi kasus Goodeva.
**Prinsip Utama:** *Clean, testable, production-ready, no overengineering*. Jangan membuat layer abstraksi yang berlebihan (hindari membuat kelas *UseCase* 1 baris yang hanya meneruskan panggilan repository).

### Aturan Bahasa & Sintaks Dart 3.13+ (Modern Idiomatic Dart)
Wajib diterapkan oleh developer di seluruh penulisan kode:
1. **Dot Shorthands (`.member`)** — [Dokumentasi Resmi: Dot shorthands](https://dart.dev/language/dot-shorthands): Gunakan shorthand dot saat context type diketahui compiler (e.g. `alignment: .center`, `fontWeight: .bold`, `mainAxisAlignment: .spaceBetween`, `colorScheme: .fromSeed(...)`, `status: .scanning`).
2. **Primary Constructors** — [Dokumentasi Resmi: Primary constructors](https://dart.dev/language/primary-constructors): Gunakan sintaks modern primary constructor pada model/data class. Bebas menggunakan **named parameter** (`class BleDeviceModel({required final String id, ...});`) untuk kelas dengan banyak properti agar instansiasinya eksplisit dan *clean*, atau positional jika kelasnya sederhana.
3. **Omit Redundant Types (Type Inference)**: Jangan menulis ulang tipe di sisi kiri deklarasi jika sudah jelas di sisi kanan (e.g. `static const primarySeed = Color(0xFF0066FF);`, `final list = <String>[];`). *Pengecualian:* Tipe eksplisit hanya diwajibkan untuk sealed class / polymorphism / generic abstraction (e.g. `final ScannerState state = ScannerInitial();`).
4. **No Hungarian/Prefix on Interfaces (Effective Dart)**: DILARANG menggunakan prefix `I` pada interface (seperti `IDeviceHistoryRepository` atau `IBleService`). Gunakan nama alami untuk interface/abstraksi (`abstract interface class DeviceHistoryRepository`) dan akhiran `Impl` untuk implementasinya (`class DeviceHistoryRepositoryImpl implements DeviceHistoryRepository`).
5. **Dumb Components & Pure Presentation**:
   - Seluruh Page/Screen dan Widget wajib dirancang sebagai **Dumb Widgets / Pure Components**:
     * Menerima state/data primitif atau entitas via constructor.
     * Mengeluarkan aksi/interaksi user via callback (`onTap`, `onPressed`, `onChanged`, dll).
     * DILARANG mengakses Service Locator (`locator<...>()`) atau memicu side-effects langsung di dalam dumb widget.
     * Smart Container / Page Wrapper bertanggung jawab mengikat ViewModel ke Dumb Widget.
6. **Widget Previews dengan `@BluePulsePreview`**:
   - Setiap Page/Screen, Widget publik, maupun private widget dari sebuah halaman wajib menyertakan preview function dengan anotasi `@BluePulsePreview` (dari `package:blue_pulse/core/utils/preview_annotations.dart`):
     * Argumen `name`: Nama widget / page / state preview (e.g. `name: 'Device Card'`, `name: 'Empty'`).
     * Argumen `group`: Dibiarkan kosong/default untuk widget publik. Khusus untuk **private widget**, isi dengan nama Page/Screen tempat private widget tersebut digunakan (e.g. `group: 'ScannerScreen'`).
7. **Absolute Package Imports (No Relative Imports)**:
   - Wajib menggunakan absolute package import di seluruh file project:
     `import 'package:blue_pulse/...'`
   - DILARANG menggunakan relative import (`../../widgets/...` atau `../models/...`).
8. **Pemanfaatan Core Extensions (`extensions.dart`)**:
   - Maksimalkan penggunaan extension yang tersedia di `package:blue_pulse/core/utils/extensions.dart`:
     * `NumX` (`num_ext.dart`): `.allPadding`, `.hPadding`, `.vPadding`, `.hGap`, `.wGap`, `.sliverHGap`, `.radius`, `.r`, `.ms`, `.seconds`.
     * `BuildContextX` (`build_context_ext.dart`): `context.scheme`, `context.text`, `context.mediaQuery`, `context.theme`.
     * `DateTimeX`, `DoubleX`, `IntX`.
   - Hindari deklarasi manual berulang untuk padding, gap/SizedBox, duration, dan radius jika extension sudah menyediakannya.

---

## 2. Directory Layout to Implement

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Color palette (Radar rings, signal zone colors)
│   │   └── app_constants.dart      # Scanning timeouts, default TxPower (-59), EMA alpha
│   ├── di/
│   │   └── injection.dart          # GetIt service locator setup
│   └── utils/
│       ├── signal_math.dart        # Log-distance path loss, EMA filter, Proximity Zone mapper
│       └── time_formatter.dart     # Relative time formatting ("2 mins ago", etc.)
├── data/
│   ├── datasources/
│   │   └── local_database.dart     # SQLite openDatabase helper, schema migration
│   ├── models/
│   │   └── ble_device_model.dart   # BleDeviceModel entity & SQLite serialization
│   └── repositories/
│       └── device_history_repository.dart # IDeviceHistoryRepository + Implementation
├── services/
│   ├── ble_service.dart            # IBleService + FlutterBluePlus scanning stream wrapper
│   └── permission_service.dart     # Android 12+ (Scan/Connect) & iOS Bluetooth permissions
├── viewmodels/
│   ├── scanner_viewmodel.dart      # ViewModel Screen 1: Scan control, real-time sort & filter
│   ├── radar_viewmodel.dart        # ViewModel Screen 2: Target tracking, EMA smoothing, watchdog
│   └── history_viewmodel.dart      # ViewModel Screen 3: SQLite history loader & clearing
├── views/
│   ├── scanner/
│   │   ├── scanner_screen.dart     # Dashboard Scanner View
│   │   └── widgets/
│   │       ├── device_card.dart    # Device list tile with signal badge
│   │       └── filter_bar.dart     # Search field & RSSI threshold chips
│   ├── radar/
│   │   ├── radar_screen.dart       # Detailed Target Tracking View
│   │   └── widgets/
│   │       ├── radar_canvas.dart   # CustomPainter: Concentric radar zones & animated ripple
│   │       └── telemetry_card.dart # Signal metrics (raw vs smoothed dBm, distance, zone)
│   └── history/
│       ├── history_screen.dart     # History Log View
│       └── widgets/
│           └── history_card.dart   # Card with device details & formatted last seen timestamp
└── main.dart                       # App entry point, DI init, Lifecycle observer
```

---

## 3. Step-by-Step Milestones & Detailed Implementation Tasks

---

### 🔹 Milestone 1: Dependencies, Android Permissions & DI Container
**Commit Message:** `feat: configure dependencies, ble permissions, and di container`

1. **Update `pubspec.yaml`**:
   Tambahkan dependensi berikut (mengadopsi arsitektur decoupling Flutter 3.47+):
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     cupertino_icons: ^1.0.8
     material_ui: ^1.0.0
     flutter_blue_plus: ^1.35.0
     sqflite: ^2.3.3+1
     path: ^1.9.0
     permission_handler: ^11.3.1
     get_it: ^7.7.0
     intl: ^0.19.0
   ```
   *Prinsip Arsitektur Decoupling:*
   - Hanya layer UI (Presentation / Views & Leaf Widgets) yang mengimpor `package:material_ui/material_ui.dart` (bukan `package:flutter/material.dart`).
   - Layer Non-UI (ViewModel, Service, Repository, Model, Utils) dilarang mengimpor `material_ui` agar tetap murni *design-agnostic* (gunakan `package:flutter/foundation.dart` untuk `ChangeNotifier` / `ValueNotifier` atau `dart:ui` untuk `Color`).
   Jalankan: `flutter pub get`.

2. **Update `android/app/build.gradle.kts`**:
   Pastikan `minSdk` minimal bernilai `21` (kebutuhan `flutter_blue_plus`):
   ```kotlin
   defaultConfig {
       applicationId = "com.bluepulse.app"
       minSdk = 21
       targetSdk = flutter.targetSdkVersion
       ...
   }
   ```

3. **Update `android/app/src/main/AndroidManifest.xml`**:
   Tambahkan izin Bluetooth dan fitur BLE sebelum tag `<application>`:
   ```xml
   <!-- Legacy Bluetooth permissions for Android 11 or lower -->
   <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="30" />

   <!-- Modern Bluetooth permissions for Android 12+ (API 31+) -->
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
       android:usesPermissionFlags="neverForLocation" />
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

   <!-- BLE hardware requirement -->
   <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
   ```

4. **Setup Theming (Material 3) & `lib/core/constants/app_colors.dart`**:
   - Terapkan standar **Material Design 3** (`useMaterial3: true`) dengan *single primary seed*:
     * `static const primarySeed = Color(0xFF0066FF);` (Electric Bluetooth Blue — tanpa redundant type `Color`).
     * Seluruh palet tema (surface, card, background, onSurface, dll.) di-generate otomatis via `colorScheme: .fromSeed(seedColor: AppColors.primarySeed)`.
   - Warna **Kategori Sinyal (Semantic Telemetry Tokens)** ditetapkan eksplisit dan independen sesuai dokumen studi kasus:
     * `static const zoneVeryStrong = Color(0xFF00C853);` (Green, < 1m)
     * `static const zoneStrong = Color(0xFF00B0FF);` (Cyan / Light Blue, 1 - 3m)
     * `static const zoneFair = Color(0xFFFFD600);` (Yellow / Amber, 3 - 10m)
     * `static const zoneWeak = Color(0xFFFF9100);` (Orange, 10 - 20m)
     * `static const zoneVeryWeak = Color(0xFFFF1744);` (Red, > 20m)
     * `static const zoneLost = Color(0xFF9E9E9E);` (Grey, Sinyal Hilang)

5. **Setup `lib/core/constants/app_constants.dart`**:
   - Konstanta domain (tanpa redundant types):
     * `static const scanTimeout = Duration(seconds: 15);`
     * `static const defaultTxPower = -59;`
     * `static const pathLossExponent = 2.4;`
     * `static const emaAlpha = 0.35;`

6. **Setup `lib/core/di/injection.dart`**:
   - Buat instance `final locator = GetIt.instance;` dan fungsi skeleton:
     ```dart
     Future<void> setupLocator() async {
       // Service & repository registrations will be filled in Milestone 2
     }
     ```

7. **Update `lib/main.dart`**:
   - Panggil `WidgetsFlutterBinding.ensureInitialized()` dan `await setupLocator()` sebelum `runApp()`.
   - Konfigurasi `MaterialApp` dengan dot shorthand:
     ```dart
     MaterialApp(
       title: 'BluePulse',
       theme: ThemeData(
         useMaterial3: true,
         colorScheme: .fromSeed(seedColor: AppColors.primarySeed),
       ),
       ...
     )
     ```

---

### 🔹 Milestone 2: Signal Math Engine, Models & SQLite Persistence
**Commit Message:** `feat: implement signal processing math, sqlite storage, and ble service`

1. **Implement `lib/core/utils/signal_math.dart`**:
   - `enum ProximityZone`:
     ```dart
     enum ProximityZone {
       veryStrong, // -10 s/d -30 dBm: < 1 meter
       strong,     // -30 s/d -50 dBm: 1 - 3 meter
       fair,       // -50 s/d -70 dBm: 3 - 10 meter
       weak,       // -70 s/d -80 dBm: 10 - 20 meter
       veryWeak,   // -80 s/d -90 dBm: > 20 meter
       lost;       // < -90 dBm: Sinyal Hilang / Putus
     }
     ```
   - `static ProximityZone classifyZone(int rssi)`:
     Implementasikan rentang sesuai tabel spesifikasi studi kasus secara presisi.
   - `static double calculateDistance(int rssi, {int txPower = -59, double n = 2.4})`:
     $$d = 10^{\frac{\text{txPower} - \text{rssi}}{10 \cdot n}}$$
     Jika `rssi == 0` atau `rssi < -95`, kembalikan `double.infinity` atau $-1.0$.
   - `static double smoothRssi(double prevSmoothed, int currentRaw, {double alpha = 0.35})`:
     Exponential Moving Average (EMA). Jika `prevSmoothed == 0`, gunakan `currentRaw.toDouble()`.

2. **Implement `lib/data/models/ble_device_model.dart`**:
   - Primary constructor dengan named parameters:
     ```dart
     class BleDeviceModel({
       required final String id,
       required final String name,
       required final int rawRssi,
       required final double smoothedRssi,
       required final double estimatedDistance,
       required final ProximityZone zone,
       required final DateTime lastSeen,
       final DateTime? firstSeen,
       final int? txPower,
     });
     ```
   - Method: `copyWith()`, `toMap()`, `fromMap()` (100% memetakan semua field ke/dari tabel SQLite).

3. **Implement `lib/data/datasources/local_database.dart`**:
   - Buat database `AppConstants.databaseName` ('devices.db').
   - Buat tabel `AppConstants.historyTableName` ('device_history') dengan kolom yang 100% merefleksikan model:
     ```sql
     CREATE TABLE device_history (
         id TEXT PRIMARY KEY,
         name TEXT NOT NULL,
         raw_rssi INTEGER NOT NULL,
         smoothed_rssi REAL NOT NULL,
         estimated_distance REAL NOT NULL,
         proximity_zone TEXT NOT NULL,
         tx_power INTEGER,
         first_seen INTEGER NOT NULL,
         last_seen INTEGER NOT NULL
     );
     CREATE INDEX idx_last_seen ON device_history(last_seen DESC);
     ```

4. **Implement `lib/data/repositories/device_history_repository.dart`**:
   - `abstract interface class DeviceHistoryRepository`:
     - Method `Future<void> upsertDevice(BleDeviceModel device)`
     - Method `Future<List<BleDeviceModel>> getHistory()`
     - Method `Future<void> deleteDevice(String id)`
     - Method `Future<void> clearAll()`
   - `class DeviceHistoryRepositoryImpl implements DeviceHistoryRepository`:
     - Implementasi menggunakan `LocalDatabase` dan `sqflite` dengan conflictAlgorithm: `.replace`.

5. **Implement `lib/services/permission_service.dart`**:
   - `abstract interface class PermissionService`:
     - Method `Future<bool> requestBlePermissions()`
     - Method `Future<bool> checkBlePermissions()`
     - Method `Future<void> openSettings()`
   - `class PermissionServiceImpl implements PermissionService`:
     - Handle Android 12+ (`Permission.bluetoothScan`, `Permission.bluetoothConnect`) dan Android $\le$ 11 (`Permission.locationWhenInUse`).

6. **Implement `lib/services/ble_service.dart`**:
   - `abstract interface class BleService`:
     - `Stream<List<ScanResult>> get scanResultsStream`
     - `Stream<BluetoothAdapterState> get adapterStateStream`
     - `Stream<bool> get isScanningStream`
     - `Future<void> startScan({Duration? timeout})`
     - `Future<void> stopScan()`
     - `bool get isScanning`
     - `Future<bool> get isSupported`
   - `class BleServiceImpl implements BleService`:
     - Implementasi wrapper `FlutterBluePlus`.

---

### 🔹 Milestone 3: Screen 1 - Dashboard Scanner (Scan, Auto-Sort, Multi-Filter)
**Commit Message:** `feat(scanner): build real-time ble scanner dashboard with sorting and filters`

1. **Implement `lib/viewmodels/scanner_viewmodel.dart`**:
   - `ChangeNotifier` state:
     - `bool isScanning`
     - `String searchQuery` (filter name / MAC)
     - `int? rssiThreshold` (e.g. -80 dBm, null = all)
     - `List<BleDeviceModel> get filteredAndSortedDevices`:
       * Filter sesuai `searchQuery` (case-insensitive contains pada name atau MAC).
       * Filter sinyal: `device.rawRssi >= threshold`.
       * **Auto-sort:** Urutkan dari sinyal terkuat ke terlemah (**RSSI descending**, misal -35 dBm berada di atas -75 dBm).
     - Debounce sync ke `device_history_repository` saat mendeteksi device baru/update.
     - Penanganan status Bluetooth mati via `adapterStateStream`.

2. **Implement `lib/views/scanner/scanner_screen.dart`**:
   - **Header Card**: Ringkasan status ("Siap Memindai" / "Sedang Memindai..."), jumlah perangkat ditemukan, status Bluetooth.
   - **Start / Stop Button**: Floating action button / header toggle yang menonjol dan responsif.
   - **Filter & Search Bar (`filter_bar.dart`)**:
     - TextField pencarian dengan tombol hapus (clear).
     - Filter Chips: `Semua`, `≥ -80 dBm`, `≥ -70 dBm`, `≥ -60 dBm`.
   - **Device List (`device_card.dart`)**:
     - Menampilkan: Device Name (bold), MAC/UUID (monospace font kecil), Badge RSSI mentah (`-45 dBm`), Estimasi Jarak (`1.5 m`), dan Proximity Zone Pill dengan warna sesuai zona.
     - On tap $\rightarrow$ Navigate ke **Screen 2: Radar View**.

---

### 🔹 Milestone 4: Screen 2 - Detail Pelacakan / Radar View
**Commit Message:** `feat(radar): add target tracking screen with dynamic radar visualizer`

1. **Implement `lib/viewmodels/radar_viewmodel.dart`**:
   - Mengunci satu target `BleDeviceModel targetDevice`.
   - Mendengarkan pembaruan sinyal real-time perangkat target dari `ble_service`.
   - Menerapkan smoothing EMA pada RSSI setiap kali paket baru masuk.
   - **Watchdog Signal Lost**: Timer cek berkala (tiap 1 detik). Jika tidak ada paket masuk selama > 10 detik, ubah status menjadi `ProximityZone.lost` ("Sinyal Hilang / Putus").
   - Menghitung **Signal Stability Score**: stabilitas variansi delta RSSI (Persentase % atau status "Sangat Stabil / Fluktuatif").

2. **Implement `lib/views/radar/widgets/radar_canvas.dart` (Dumb Component)**:
   - `CustomPainter` dengan animasi rotasi gelombang/pulse sweep (`AnimationController`).
   - Murni *dumb widget*: hanya menerima data model/distance/zone dan callback animasi.
   - Gambar 5 lingkaran konsentris dengan label jarak: `<1m`, `1-3m`, `3-10m`, `10-20m`, `>20m`.
   - Gambar titik **Blip Perangkat Target**:
     - Radius blip dari pusat radar dipetakan secara proporsional dari estimasi jarak (0 meter di pusat, >20 meter di batas luar radar).
     - Warna blip dan lingkaran aktif berubah dinamis sesuai `ProximityZone` (Hijau $\rightarrow$ Biru $\rightarrow$ Kuning $\rightarrow$ Oranye $\rightarrow$ Merah $\rightarrow$ Abu-abu).
     - Efek denyut (*pulse ping*) membesar saat paket baru terdeteksi.
   - Sertakan preview: `@BluePulsePreview(name: 'Radar Canvas')`.

3. **Implement `lib/views/radar/widgets/telemetry_card.dart` (Dumb Component)**:
   - Murni *dumb widget*: menerima nilai metrik dan state koneksi.
   - Tampilkan metrik detail dalam grid kartu memanfaatkan `NumX` spacing (`.hGap`, `.wGap`, `.allPadding`, `.radius`):
     * Raw RSSI vs Smoothed RSSI
     * Estimasi Jarak Akurat
     * Kategori Sinyal (Zone Badge)
     * Status Koneksi / Heartbeat Packet Rate (packets/sec)
     * Last Packet Timestamp
   - Sertakan preview: `@BluePulsePreview(name: 'Telemetry Card')`.

4. **Implement `lib/views/radar/radar_screen.dart`**:
   - Struktur: Dumb View (`_RadarView` / dumb sub-widgets) + Screen Wrapper yang mengikat `RadarTrackingViewModel`.
   - Tombol kembali (Back) dan indikator status pelacakan aktif.
   - Preview function:
     * `@BluePulsePreview(name: 'Tracking Active', group: 'RadarScreen')`
     * `@BluePulsePreview(name: 'Signal Lost', group: 'RadarScreen')`
   - Gunakan **absolute package import** dan manfaatkan extension (`context.scheme`, `context.text`, `.radius`, dll).

---

### 🔹 Milestone 5: Screen 3 - Riwayat Perangkat (History Log)
**Commit Message:** `feat(history): implement local persistent history log view`

1. **Implement `lib/viewmodels/history_viewmodel.dart`**:
   - Membaca daftar riwayat perangkat dari `DeviceHistoryRepository`.
   - Method `refreshHistory()`.
   - Method `deleteItem(String id)`.
   - Method `clearAllHistory()`.

2. **Implement `lib/views/history/widgets/history_card.dart` (Dumb Component)**:
   - Murni *dumb widget*: menerima `BleDeviceModel`, relative timestamp string, dan callbacks (`onTap`, `onDelete`).
   - Tampilkan: Device Name, MAC, Sinyal terakhir, Kategori zona terakhir, dan **Relative Timestamp** (misal: "Baru saja", "5 menit lalu", "Kemarin 14:20").
   - Preview function: `@BluePulsePreview(name: 'History Card')`.

3. **Implement `lib/views/history/history_screen.dart`**:
   - Struktur: Dumb View (`_HistoryView`) + Screen Wrapper yang mengikat `HistoryViewModel`.
   - List data perangkat tersimpan dari SQLite.
   - Action dialog: Konfirmasi hapus per item dan tombol "Hapus Semua Riwayat".
   - Preview function:
     * `@BluePulsePreview(name: 'History Populated', group: 'HistoryScreen')`
     * `@BluePulsePreview(name: 'History Empty', group: 'HistoryScreen')`
   - Wajib gunakan **absolute package import** dan manfaatkan extension (`context.scheme`, `context.text`, `NumX`, dll).

---

### 🔹 Milestone 6: Error Handling, Resilience & App Lifecycle
**Commit Message:** `feat(lifecycle): implement background pause-resume and edge-case error resilience`

1. **App Lifecycle Policy (`WidgetsBindingObserver`)**:
   - Di `main.dart` atau wrapper screen utama:
     - Saat `AppLifecycleState.paused` / `inactive`: otomatis panggil `bleService.stopScan()` untuk mencegah pemborosan daya baterai dan mematuhi kebijakan background BLE Android/iOS.
     - Saat `AppLifecycleState.resumed`: jika sebelumnya sedang dalam mode scan aktif, panggil `startScan()` kembali secara mulus.
2. **Bluetooth Adapter State Resilience**:
   - Jika pengguna mematikan Bluetooth saat aplikasi sedang berjalan/memindai:
     * Hentikan stream pemindaian secara aman tanpa crash.
     * Tampilkan SnackBar / Persistent Banner dengan tombol "Nyalakan Bluetooth".
3. **Screen Rotation & Configuration Changes**:
   - Seluruh ViewModel disimpan dalam lifecycle yang independen dari siklus render widget (state tidak hilang saat rotasi portrait/landscape).

---

### 🔹 Milestone 7: Unit Testing & Verifikasi
**Commit Message:** `test: add unit tests for signal math, proximity zones, and scanner filters`

1. **Buat `test/unit/signal_math_test.dart`**:
   - Uji klasifikasi seluruh 6 `ProximityZone` sesuai rentang dBm tabel studi kasus.
   - Uji rumus Log-Distance Path Loss dengan berbagai variasi RSSI (-30, -50, -70, -85 dBm).
   - Uji EMA filter (memastikan `alpha` menghasilkan nilai yang ter-smoothing dengan benar).
2. **Buat `test/unit/scanner_filter_test.dart`**:
   - Uji pengurutan RSSI descending (terkuat di paling awal).
   - Uji pencarian berdasarkan Nama dan MAC Address.
   - Uji threshold filter (hanya sinyal $\ge$ ambang batas yang lolos).
3. **Jalankan Verifikasi**:
   `flutter test` $\rightarrow$ Pastikan **100% tests pass**.

---

### 🔹 Milestone 8: Hulu-ke-Hilir Documentation (README.md) & Build APK
**Commit Message:** `docs: complete hulu-ke-hilir readme and build release apk`

1. **Dokumentasikan `README.md` secara Komprehensif**:
   Sesuai panduan submission studi kasus:
   - **Product Overview & Features**: Penjelasan solusi BluePulse.
   - **Arsitektur & Tech Stack**: Penjelasan Clean MVVM, Service Locator, SQLite, dan justifikasi pemilihan library.
   - **Formula & Teori Sinyal**: Penjelasan rumus Path Loss, nilai konstanta $n$ dan $\text{TxPower}$, serta filter EMA.
   - **Tabel Pemetaan Zona Kedekatan**: Cantumkan tabel 6 zona dari brief.
   - **Instruksi Setup & Cara Menjalankan**: Langkah clone, `flutter pub get`, build Android/iOS.
   - **Edge Cases & Error Handling**: Penanganan permission, adapter mati, lifecycle background.
   - **Asumsi Teknis & Kendala yang Dihadapi (Sesuai Konteks Pengerjaan)**:
      1. *Keterbatasan Perangkat Pengujian*: Pengujian fisik terbatas pada perangkat Android riil. Meskipun basis kode dirancang multiplatform dengan flutter_blue_plus, pengujian hardware dan verifikasi build difokuskan pada platform Android.
     2. *Learning Curve BLE & Estimasi Jarak RF*: Domain Bluetooth Low Energy dan perambatan sinyal radio (path loss, multipath fading, estimasi jarak dari RSSI) merupakan hal baru bagi kandidat dengan learning curve yang cukup berat, yang kemudian berhasil diakselerasi dan dirumuskan secara sistematis dengan bantuan AI pair programming (Antigravity).
2. **Build Release APK**:
   Jalankan:
   ```powershell
   flutter build apk --release
   ```
   Pastikan file APK berhasil ter-generate di `build/app/outputs/flutter-apk/app-release.apk`.

---

## 4. Verification & Acceptance Criteria for Developer Agent

| Item | Perintah Verifikasi | Kriteria Lolos |
| :--- | :--- | :--- |
| **Dart Analysis** | `flutter analyze` | 0 issues found |
| **Unit Tests** | `flutter test` | Semua test case lolos tanpa error |
| **Local Database** | Verifikasi CRUD | Data perangkat tersimpan dan tetap ada setelah restart |
| **Release Build** | `flutter build apk --release` | File APK selesai dibuat tanpa error gradle |
| **Git Log** | `git log --oneline` | Riwayat commit runtut dari awal hingga akhir |
