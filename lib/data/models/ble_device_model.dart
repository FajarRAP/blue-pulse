import 'package:equatable/equatable.dart';

import 'package:blue_pulse/core/utils/signal_math.dart';

/// Data Model representing a BLE Peripheral Device with telemetry and proximity information.
class const BleDeviceModel({
  required final String id,
  required final String name,
  required final int rawRssi,
  required final double smoothedRssi,
  required final double estimatedDistance,
  required final ProximityZone zone,
  required final DateTime lastSeen,
  final DateTime? firstSeen,
  final int? txPower,
}) extends Equatable {
  /// Reconstitutes a [BleDeviceModel] directly from an SQLite row.
  /// Uses direct table column keys and type casting without redundant fallbacks for non-null columns.
  factory BleDeviceModel.fromMap(Map<String, dynamic> map) {
    return BleDeviceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      rawRssi: map['raw_rssi'] as int,
      smoothedRssi: (map['smoothed_rssi'] as num).toDouble(),
      estimatedDistance: (map['estimated_distance'] as num).toDouble(),
      zone: ProximityZone.values.byName(map['proximity_zone'] as String),
      txPower: map['tx_power'] as int?,
      firstSeen: .fromMillisecondsSinceEpoch(map['first_seen'] as int),
      lastSeen: .fromMillisecondsSinceEpoch(map['last_seen'] as int),
    );
  }

  /// Converts this entity into a Map suitable for SQLite database storage.
  /// 100% mirrors the `device_history` table schema.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'raw_rssi': rawRssi,
      'smoothed_rssi': smoothedRssi,
      'estimated_distance': estimatedDistance,
      'proximity_zone': zone.name,
      'tx_power': txPower,
      'first_seen': (firstSeen ?? lastSeen).millisecondsSinceEpoch,
      'last_seen': lastSeen.millisecondsSinceEpoch,
    };
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
    DateTime? firstSeen,
    int? txPower,
  }) {
    return BleDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rawRssi: rawRssi ?? this.rawRssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      zone: zone ?? this.zone,
      lastSeen: lastSeen ?? this.lastSeen,
      firstSeen: firstSeen ?? this.firstSeen,
      txPower: txPower ?? this.txPower,
    );
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
    firstSeen,
    txPower,
  ];
}
