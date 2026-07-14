import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Centralized state management for elderly selection across all caregiver screens.
///
/// Solves the problem of each screen maintaining its own elderly list and
/// selected elderly ID independently, causing desync when switching tabs.
class ElderlyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _elderlyList = [];
  int? _selectedElderlyId;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get elderlyList => _elderlyList;
  int? get selectedElderlyId => _selectedElderlyId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasElderly => _elderlyList.isNotEmpty;

  /// Returns the currently selected elderly's full data map, or null.
  Map<String, dynamic>? get selectedElderly {
    if (_selectedElderlyId == null || _elderlyList.isEmpty) return null;
    try {
      return _elderlyList.firstWhere((e) => e['id'] == _selectedElderlyId);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: selected elderly's display name.
  String get selectedElderlyName {
    final e = selectedElderly;
    if (e == null) return '';
    return e['fullname']?.toString() ?? 'N/A';
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  /// Load elderly list from API. Automatically selects the first elderly if
  /// none is currently selected, or restores the previously selected one.
  Future<void> loadElderlyList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.getElderlyList();
    if (result['success'] == true) {
      final list =
          (result['elderly_list'] as List).cast<Map<String, dynamic>>();
      _elderlyList = list;

      if (list.isNotEmpty) {
        // Restore previously selected elderly if still in the list
        if (_selectedElderlyId != null &&
            list.any((e) => e['id'] == _selectedElderlyId)) {
          // Keep current selection
        } else if (ApiService.currentElderlyId != null &&
            list.any((e) => e['id'] == ApiService.currentElderlyId)) {
          _selectedElderlyId = ApiService.currentElderlyId;
        } else {
          _selectedElderlyId = list.first['id'] as int;
        }
        ApiService.currentElderlyId = _selectedElderlyId;
      } else {
        _selectedElderlyId = null;
        ApiService.currentElderlyId = null;
      }
    } else {
      _error = result['error']?.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Switch to a different elderly. Notifies all listeners (screens) to reload.
  void switchElderly(int elderlyId) {
    if (_selectedElderlyId == elderlyId) return;
    _selectedElderlyId = elderlyId;
    ApiService.currentElderlyId = elderlyId;
    notifyListeners();
    // Also trigger the global data refresh so screens listening to that also update
    ApiService.notifyDataChanged();
  }

  /// Refresh the list from API (e.g. after adding a new elderly).
  Future<void> refresh() async {
    await loadElderlyList();
  }

  /// Utility: calculate age from date of birth string.
  static int? calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return null;
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  // ── InheritedWidget-style access ─────────────────────────────────────────────

  /// Access the provider from the widget tree.
  /// Usage: ElderlyProvider.of(context)
  static ElderlyProvider? _instance;

  static ElderlyProvider get instance {
    _instance ??= ElderlyProvider();
    return _instance!;
  }
}
