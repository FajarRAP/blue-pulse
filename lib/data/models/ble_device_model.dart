import 'package:equatable/equatable.dart';

import 'package:blue_pulse/core/utils/signal_math.dart';

/// Data Model representing a BLE Peripheral Device with telemetry and proximity information.
class const BleDeviceModel({
  /// Unique hardware identifier: MAC Address on Android or UUID on iOS.
  required final String id,

  /// Advertised local device name or 'Unknown Device' if empty/null.
  required final String name,

  /// Latest raw RSSI measurement in dBm.
  required final int rawRssi,

  /// RSSI smoothed via Exponential Moving Average (EMA).
  required final double smoothedRssi,

  /// Estimated physical distance in meters derived from Log-Distance Path Loss.
  required final double estimatedDistance,

  /// Proximity zone category (veryStrong, strong, fair, weak, veryWeak, lost).
  required final ProximityZone zone,

  /// Timestamp when this device was last observed by the scanner.
  required final DateTime lastSeen,

  /// Timestamp when this device was first recorded.
  final DateTime? _firstSeen,

  /// Calibrated TxPower if advertised by beacon, or null.
  final int? txPower,
}) extends Equatable {
  DateTime get firstSeen => _firstSeen ?? lastSeen;

  /// Reconstitutes a [BleDeviceModel] from an SQLite row or key-value map.
  factory BleDeviceModel.fromMap(Map<String, dynamic> map) {
    final rawRssi =
        ((map['last_rssi'] ?? map['raw_rssi'] ?? map['rawRssi']) as num?)
            ?.toInt() ??
        0;
    final distance =
        ((map['last_distance'] ?? map['distance'] ?? map['estimatedDistance'])
                as num?)
            ?.toDouble() ??
        0.0;
    final zoneStr = (map['last_zone'] ?? map['zone']) as String?;
    final zone = ProximityZone.values.firstWhere(
      (z) => z.name == zoneStr,
      orElse: () => SignalMath.classifyZone(rawRssi),
    );
    final lastSeenMillis =
        ((map['last_seen'] ?? map['lastSeen']) as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final firstSeenMillis =
        ((map['first_seen'] ?? map['firstSeen']) as num?)?.toInt() ??
        lastSeenMillis;

    return BleDeviceModel(
      id: map['id'] as String? ?? '',
      name: (map['name'] as String?)?.isNotEmpty == true
          ? map['name'] as String
          : 'Unknown Device',
      rawRssi: rawRssi,
      smoothedRssi:
          ((map['smoothed_rssi'] ?? map['smoothedRssi']) as num?)?.toDouble() ??
          rawRssi.toDouble(),
      estimatedDistance: distance,
      zone: zone,
      lastSeen: .fromMillisecondsSinceEpoch(lastSeenMillis),
      firstSeen: .fromMillisecondsSinceEpoch(firstSeenMillis),
      txPower: ((map['tx_power'] ?? map['txPower']) as num?)?.toInt(),
    );
  }

  /// Returns a copy of this [BleDeviceModel] with updated fields.
  BleDeviceModel copyWith({
    String? id,
    String? name,
    int? rawRssi,
    double? smoothedRssi,
    double? estimatedDistance,
    ProximityZone? zone,
    DateTime? lastSeen,
    int? txPower,
    DateTime? firstSeen,
  }) {
    return BleDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rawRssi: rawRssi ?? this.rawRssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      zone: zone ?? this.zone,
      lastSeen: lastSeen ?? this.lastSeen,
      txPower: txPower ?? this.txPower,
      firstSeen: firstSeen ?? this.firstSeen,
    );
  }

  /// Converts this entity into a Map suitable for SQLite database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.isEmpty ? 'Unknown Device' : name,
      'last_rssi': rawRssi,
      'last_distance': estimatedDistance,
      'last_zone': zone.name,
      'first_seen': firstSeen.millisecondsSinceEpoch,
      'last_seen': lastSeen.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    rawRssi,
    smoothedRssi,
    estimatedDistance,
    zone,
    lastSeen,
    txPower,
    firstSeen,
  ];
}
