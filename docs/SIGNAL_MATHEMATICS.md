# BLE Signal Mathematics & Telemetry Specification

Dokumen ini mendokumentasikan spesifikasi matematis, teori perambatan gelombang radio Bluetooth Low Energy (BLE), formula estimasi jarak, dan algoritma *smoothing* yang diimplementasikan pada kelas `SignalMath` (`lib/core/utils/signal_math.dart`).

---

## 1. Log-Distance Path Loss Model (Estimasi Jarak)

Sinyal radio frekuensi (RF) pada frekuensi 2.4 GHz mengalami pelemahan (*attenuation*) seiring bertambahnya jarak dari pemancar (*transmitter*). Hubungan antara daya sinyal yang diterima (**RSSI**) dan jarak fisik ($d$) dimodelkan menggunakan **Log-Distance Path Loss Model**:

$$\text{RSSI} = \text{TxPower} - 10 \cdot n \cdot \log_{10}(d)$$

Dengan menyelesaikan persamaan di atas untuk jarak $d$ (dalam satuan meter), diperoleh formula:

$$d = 10^{\left(\frac{\text{TxPower} - \text{RSSI}}{10 \cdot n}\right)}$$

### Parameter Formula:
| Parameter | Deskripsi | Nilai Default | Referensi Domain |
| :--- | :--- | :--- | :--- |
| $\text{RSSI}$ | *Received Signal Strength Indicator* terukur (dBm). | Dinamis (dari hardware) | Paket Advertising BLE |
| $\text{TxPower}$ | Daya RSSI terkalibrasi pada jarak tepat 1 meter (dBm). | `-59 dBm` | `AppConstants.defaultTxPower` |
| $n$ | *Path-Loss Exponent* lingkungan (koefisien redaman). | `2.4` (Indoor office/home) | `AppConstants.defaultPathLossExponent` |

### Karakteristik & Nilai Eksponen ($n$):
- Ruang hampa / Free space: $n = 2.0$
- Lingkungan dalam ruangan dengan line-of-sight (LOS): $n = 1.6 - 2.0$
- Lingkungan dalam ruangan dengan hambatan / dinding / furnitur: $n = 2.4 - 3.5$
- Lingkungan padat industri / terhalang logam: $n = 4.0 - 6.0$

### Penanganan Kasus Batas (Edge Cases):
1. **$\text{RSSI} \ge 0\text{ dBm}$**: Secara fisik tidak mungkin terjadi pada penerimaan sinyal BLE pasif di antena ponsel pintar (0 dBm = 1 mW daya pancar langsung). Nilai $\ge 0$ menandakan kesalahan hardware atau status *disconnected*. Fungsi mengembalikan batas aman `-1.0` (merepresentasikan jarak tidak valid / *N/A*).
2. **$\text{RSSI} < -95\text{ dBm}$**: Berada di bawah *noise floor* sensitivitas penerima RF BLE sebagian besar chipset ponsel. Sinyal dianggap terputus atau hilang (*lost*), sehingga fungsi mengembalikan `-1.0`.

---

## 2. Exponential Moving Average / EMA (Peredaman Jitter)

Sinyal radio BLE di dunia nyata sangat rentan terhadap gangguan interferensi eksternal, fenomena *multipath fading* (pantulan sinyal dari dinding/lantai), dan redaman oleh tubuh manusia (*body shadowing*). Hal ini menyebabkan nilai RSSI mentah (*raw RSSI*) berfluktuasi drastis (misal melompat dari -55 dBm ke -72 dBm lalu kembali ke -58 dBm dalam hitungan milidetik).

Untuk mencegah antarmuka pengguna (UI radar dan daftar perangkat) bergetar atau melompat-lompat (*jittering*), diterapkan filter **Exponential Moving Average (EMA)**:

$$\text{RSSI}_{\text{smoothed}} = \alpha \cdot \text{RSSI}_{\text{current}} + (1 - \alpha) \cdot \text{RSSI}_{\text{prev}}$$

### Parameter Smoothing:
- **$\alpha$ (*Smoothing Factor*)**: Nilai antara $0.0$ dan $1.0$.
  * Default: `0.35` (`AppConstants.defaultEmaAlpha`).
  * Nilai $\alpha = 0.35$ memberikan kompromi optimal: cukup responsif terhadap pergerakan pengguna nyata ke arah beacon (< 0.5 detik lag), namun cukup stabil untuk menyaring *spike noise*.
- **Inisialisasi (*Cold Start*)**:
  * Ketika perangkat baru pertama kali terdeteksi ($\text{RSSI}_{\text{prev}} == 0$), filter langsung diinisialisasi dengan $\text{RSSI}_{\text{current}}$ tanpa memperhitungkan nilai nol awal.

---

## 3. Pemetaan Zona Kedekatan (Proximity Zone Classification)

Sesuai tabel spesifikasi studi kasus Goodeva (Halaman 2), spektrum kekuatan sinyal diklasifikasikan ke dalam 6 zona kedekatan diskret:

| Rentang RSSI (dBm) | Enum `ProximityZone` | Label Display | Perkiraan Jarak | Representasi Warna UI | Token Warna |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **-10 s/d -30 dBm** | `.veryStrong` | Sangat Kuat | `< 1 meter` | Hijau Terang (`#00C853`) | `AppColors.signalVeryStrong` |
| **-30 s/d -50 dBm** | `.strong` | Kuat | `1 – 3 meter` | Hijau/Cyan (`#00B0FF`) | `AppColors.signalStrong` |
| **-50 s/d -70 dBm** | `.fair` | Cukup | `3 – 10 meter` | Kuning/Amber (`#FFD600`) | `AppColors.signalFair` |
| **-70 s/d -80 dBm** | `.weak` | Lemah | `10 – 20 meter` | Oranye (`#FF9100`) | `AppColors.signalWeak` |
| **-80 s/d -90 dBm** | `.veryWeak` | Sangat Lemah | `> 20 meter` | Merah (`#FF1744`) | `AppColors.signalVeryWeak` |
| **< -90 dBm** atau $\ge 0$ | `.lost` | Sinyal Hilang | `Terputus / Di luar jangkauan` | Abu-abu (`#9E9E9E`) | `AppColors.signalLost` |

---

## 4. Referensi Implementasi Kode

- **Kelas Implementasi:** [`SignalMath`](file:///C:/Users/fajar/.gemini/antigravity/worktrees/goodeva_test/implement_signal_math_engine/lib/core/utils/signal_math.dart)
- **Konstanta Domain:** [`AppConstants`](file:///C:/Users/fajar/.gemini/antigravity/worktrees/goodeva_test/implement_signal_math_engine/lib/core/constants/app_constants.dart)
- **Palet Warna Telemetri:** [`AppColors`](file:///C:/Users/fajar/.gemini/antigravity/worktrees/goodeva_test/implement_signal_math_engine/lib/core/constants/app_colors.dart)
- **Unit Test Suite:** [`signal_math_test.dart`](file:///C:/Users/fajar/.gemini/antigravity/worktrees/goodeva_test/implement_signal_math_engine/test/unit/signal_math_test.dart)
