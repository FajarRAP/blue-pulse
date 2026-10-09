import 'package:flutter/foundation.dart';

import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';

/// ViewModel for Screen 3: Riwayat Perangkat (History Log View).
///
/// Coordinates reading previously observed BLE devices from SQLite persistence,
/// handling device deletion, clearing entire history, and managing loading / error states.
class HistoryViewModel(final DeviceHistoryRepository _historyRepository)
    extends ChangeNotifier {
  List<BleDeviceModel> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // --- Getters ---

  /// List of historical devices, ordered newest first (`last_seen DESC`).
  List<BleDeviceModel> get devices => List.unmodifiable(_devices);

  /// Whether history data is currently being fetched from local persistence.
  bool get isLoading => _isLoading;

  /// Error message string if a persistence operation fails.
  String? get errorMessage => _errorMessage;

  /// Helper getter indicating whether the history list is currently empty.
  bool get isEmpty => _devices.isEmpty;

  // --- Actions ---

  /// Fetches historical devices from SQLite via [DeviceHistoryRepository] and updates state.
  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _devices = await _historyRepository.getHistory();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convenience alias for [loadHistory] for pull-to-refresh interactions.
  Future<void> refreshHistory() => loadHistory();

  /// Removes an individual device record by its unique hardware [id] from SQLite
  /// and updates the in-memory list.
  Future<void> deleteDevice(String id) async {
    try {
      await _historyRepository.deleteDevice(id);
      _devices.removeWhere((device) => device.id == id);
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  /// Removes all persisted device records from SQLite and clears the in-memory list.
  Future<void> clearAllHistory() async {
    try {
      await _historyRepository.clearAll();
      _devices.clear();
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }
}
