// Monthly reference prices (prices collection). The last loaded prices are
// also saved on the phone with shared_preferences, so the Prices tab still
// works without internet and says when the copy was saved.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_record.dart';
import '../utils/app_exception.dart';
import '../utils/app_logger.dart';
import '../utils/format.dart';

/// The prices plus where they came from.
class PriceData {
  const PriceData(this.records, {this.savedCopyFrom});

  final List<PriceRecord> records;

  /// Set when the internet failed and we show the copy saved on this date.
  final DateTime? savedCopyFrom;
}

/// Loading and saving reference prices.
class PriceService {
  static const _cacheKey = 'prices_cache';
  static const _cacheTimeKey = 'prices_cache_time';

  CollectionReference<Map<String, dynamic>> get _prices =>
      FirebaseFirestore.instance.collection('prices');

  /// Loads the last 12 months of prices for every crop. If that fails, falls
  /// back to the copy saved on this phone. Throws only if there is no copy.
  Future<PriceData> fetchRecent() async {
    try {
      final records = await runSafely('load prices', () async {
        final now = DateTime.now();
        final from = monthKeyOf(DateTime(now.year - 1, now.month));
        final snapshot = await _prices
            .where('month', isGreaterThanOrEqualTo: from)
            .get();
        return snapshot.docs
            .map((doc) => PriceRecord.fromMap(doc.data()))
            .toList();
      });
      await _saveCopy(records);
      return PriceData(records);
    } on AppException {
      final copy = await _loadCopy();
      if (copy == null) rethrow; // no saved copy: show the error
      return copy;
    }
  }

  /// Saves (or replaces) one crop's price for one month. Admin only.
  Future<void> save(PriceRecord record, String adminId) {
    return runSafely('save price', () {
      return _prices.doc(record.docId).set({
        ...record.toMap(),
        'enteredBy': adminId,
        'enteredAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// The newest price for [crop] from [records], or null if there is none.
  static PriceRecord? latestFor(String crop, List<PriceRecord> records) {
    final forCrop = historyFor(crop, records);
    return forCrop.isEmpty ? null : forCrop.last;
  }

  /// All prices of one crop, oldest month first (the order the chart needs).
  static List<PriceRecord> historyFor(String crop, List<PriceRecord> records) {
    final list = records.where((r) => r.crop == crop).toList();
    list.sort((a, b) => a.month.compareTo(b.month));
    return list;
  }

  Future<void> _saveCopy(List<PriceRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(records.map((r) => r.toMap()).toList());
      await prefs.setString(_cacheKey, json);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      AppLogger.error('saving price copy failed', e); // not fatal
    }
  }

  Future<PriceData?> _loadCopy() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKey);
    final time = prefs.getString(_cacheTimeKey);
    if (json == null || time == null) return null;
    final list = (jsonDecode(json) as List)
        .map((item) => PriceRecord.fromMap(item as Map<String, dynamic>))
        .toList();
    return PriceData(list, savedCopyFrom: DateTime.parse(time));
  }
}
