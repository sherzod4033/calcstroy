import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation_history.dart';

class HistoryStorage {
  HistoryStorage._();

  static const String _historyKey = 'calculation_history_items';
  static const int _maxItems = 100;

  static final HistoryStorage instance = HistoryStorage._();
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<CalculationHistoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              CalculationHistoryItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addItem(CalculationHistoryItem item) async {
    final items = await loadItems();
    items.insert(0, item);
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }
    await _saveItems(items);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    changes.value++;
  }

  Future<void> _saveItems(List<CalculationHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_historyKey, raw);
    changes.value++;
  }
}
