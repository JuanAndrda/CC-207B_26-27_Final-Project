// The buyer assistant's facts, worked out in plain Dart: price
// comparisons, totals, stock checks, order meanings and listing search.
// The AI only puts these into words, so the numbers never depend on it,
// and they still work when the AI is busy (the fallback).

import 'dart:convert';

import '../models/assistant.dart';
import '../models/listing.dart';
import '../models/order.dart';
import '../models/price_record.dart';
import '../services/price_service.dart';
import 'constants.dart';
import 'format.dart';

// ------------------------------------------------------------ price check

/// A farmer's asking price compared with the PSA reference price.
class PriceComparison {
  const PriceComparison({
    required this.crop,
    required this.reference,
    this.asking,
    this.unit = 'kg',
    this.isOlder = false,
  });

  final String crop;
  final PriceRecord? reference; // null when PSA has no price for the crop
  final double? asking; // null on a price page (no farmer price)
  final String unit;
  final bool isOlder; // the reference is older than the newest PSA month

  /// Asking − reference, in pesos (null when one is missing, or when the
  /// listing is not sold per kg: PSA prices are per kg).
  double? get difference {
    final a = asking, r = reference;
    if (a == null || r == null || unit != 'kg') return null;
    return ((a - r.price) * 100).round() / 100;
  }

  /// The difference as a percent of the reference, e.g. 11.8.
  double? get percent {
    final d = difference, r = reference;
    if (d == null || r == null || r.price == 0) return null;
    return (d / r.price * 1000).round() / 10;
  }

  /// "higher", "lower" or "about the same" (within 5%).
  String? get verdict {
    final p = percent;
    if (p == null) return null;
    if (p.abs() <= 5) return 'about the same as';
    return p > 0 ? 'higher than' : 'lower than';
  }

  /// "Jun 2026", plus "(older price)" when it is old.
  String? get monthText {
    final r = reference;
    if (r == null) return null;
    final month = formatMonthKey(r.month);
    return isOlder ? '$month (older price)' : month;
  }

  List<FactRow> get facts => [
    if (asking != null) FactRow('Asking price', '${formatPeso(asking!)}/$unit'),
    if (reference != null)
      FactRow('PSA reference', '${formatPeso(reference!.price)}/kg'),
    if (monthText != null) FactRow('PSA month', monthText!),
    if (reference == null) const FactRow('PSA reference', 'None for this crop'),
    if (difference != null)
      FactRow(
        'Difference',
        '${difference! >= 0 ? '+' : '−'}${formatPeso(difference!.abs())} '
            '(${percent! >= 0 ? '+' : '−'}${percent!.abs()}%)',
      ),
  ];

  /// One plain sentence, used when the AI is busy.
  String get plainAnswer {
    final r = reference;
    if (r == null) {
      return 'PSA has no farmgate price for $crop yet, so there is nothing '
          'to compare with.';
    }
    final psa =
        'The PSA farmgate price for $crop is ${formatPeso(r.price)}/kg '
        '($monthText). That is what farmers were paid on average in '
        'Iloilo Province.';
    if (asking == null) return psa;
    if (difference == null) {
      return '$psa This listing is sold per $unit, so it can\'t be compared '
          'per kg.';
    }
    return '$psa This asking price is $verdict that, by '
        '${formatPeso(difference!.abs())} (${percent!.abs()}%).';
  }

  Map<String, dynamic> toFacts() => {
    'crop': crop,
    'askingPrice': ?asking,
    'unit': unit,
    'psaReferencePerKg': ?reference?.price,
    'psaMonth': ?monthText,
    'differencePesos': ?difference,
    'differencePercent': ?percent,
    'comparison': ?verdict,
    'psaMeaning':
        'PSA farmgate price = the average price farmers were paid in Iloilo '
        'Province that month, before transport and selling costs.',
  };
}

/// Compares [asking] (optional) with the newest PSA price of [crop].
PriceComparison comparePrice(
  String crop,
  List<PriceRecord> records, {
  double? asking,
  String unit = 'kg',
}) {
  return PriceComparison(
    crop: crop,
    reference: PriceService.latestFor(crop, records),
    asking: asking,
    unit: unit,
    isOlder: PriceService.isOlderPrice(crop, records),
  );
}

// ------------------------------------------------------------------ trend

/// How [crop]'s PSA price moved, only from the months we have.
List<FactRow> trendFacts(String crop, List<PriceRecord> records) {
  final mine = records.where((r) => r.crop == crop).toList()
    ..sort((a, b) => a.month.compareTo(b.month));
  if (mine.length < 2) {
    return [
      FactRow('PSA months we have', '${mine.length}'),
      const FactRow('Trend', 'Not enough months to tell'),
    ];
  }
  final first = mine.first, last = mine.last;
  final change = PriceService.monthlyChange(crop, records);
  final overall = last.price - first.price;
  return [
    FactRow(
      'Newest',
      '${formatPeso(last.price)}/kg (${formatMonthKey(last.month)})',
    ),
    if (change != null)
      FactRow(
        'Since the month before',
        '${change >= 0 ? '+' : '−'}${formatPeso(change.abs())}',
      ),
    FactRow(
      'Since ${formatMonthKey(first.month)}',
      '${overall >= 0 ? '+' : '−'}${formatPeso(overall.abs())}',
    ),
  ];
}

// ------------------------------------------------------------- offer math

/// The total for [qty] at [price], and whether enough is available.
List<FactRow> offerFacts({
  required double qty,
  required double price,
  required String unit,
  double? available,
}) {
  final total = orderTotal(qty, price);
  return [
    FactRow('Amount', '${formatQuantity(qty)} $unit'),
    FactRow('Price', '${formatPeso(price)}/$unit'),
    FactRow('Total', formatPeso(total)),
    if (available != null)
      FactRow(
        'Available now',
        qty <= available
            ? '${formatQuantity(available)} $unit (enough)'
            : 'Only ${formatQuantity(available)} $unit available',
      ),
  ];
}

/// What an order's state means, in plain words.
String orderMeaning(CropOrder order, DateTime now) {
  final until = order.reservedUntil;
  return switch (order.stateAt(now)) {
    OrderState.pending =>
      'Waiting for the farmer to answer. Nothing is held for you yet. It '
          'expires on ${formatDate(order.answerBy)}.',
    OrderState.offered =>
      'The farmer offered this. You can accept or decline it until '
          '${formatDate(order.answerBy)}.',
    OrderState.reserved =>
      'Reserved: the farmer is holding it for you'
          '${until == null ? '' : ' until ${formatDate(until)}'}. Agree on '
          'pickup and payment in the chat.',
    OrderState.holdEnded =>
      'The hold ended${until == null ? '' : ' on ${formatDate(until)}'}. '
          'The stock is free again; message the farmer.',
    OrderState.completed => 'Sold: the farmer marked it as sold.',
    OrderState.declined => 'Declined.',
    OrderState.cancelled => 'Cancelled.',
    OrderState.expired => 'Expired: nobody answered within 3 days.',
  };
}

List<FactRow> orderFacts(CropOrder order, DateTime now) => [
  FactRow('Order', '${order.crop}, ${formatQuantity(order.qty)} ${order.unit}'),
  FactRow('Price', '${formatPeso(order.price)}/${order.unit}'),
  FactRow('Total', formatPeso(order.total)),
  FactRow('Status', orderMeaning(order, now)),
];

// ----------------------------------------------------------------- search

/// How to sort search results.
enum SearchSort { price, available, newest }

/// A listing search the app can run: only crops and towns we know.
class SearchQuery {
  const SearchQuery({
    this.crop,
    this.town,
    this.quantity,
    this.sort = SearchSort.price,
  });

  final String? crop; // one of kCrops, or null for any crop
  final String? town; // one of kTowns, or null for any town
  final double? quantity; // how much the buyer wants, if said
  final SearchSort sort;

  bool get isEmpty => crop == null && town == null;
}

/// The crop in [name], matching our names and local names (case-insensitive),
/// or null when it is not one of our 71 crops.
String? matchCrop(String? name) {
  if (name == null) return null;
  final wanted = name.trim().toLowerCase();
  if (wanted.isEmpty) return null;
  for (final crop in kCropCatalog) {
    if (crop.name.toLowerCase() == wanted ||
        crop.localNames.any((n) => n.toLowerCase() == wanted)) {
      return crop.name;
    }
  }
  return null;
}

/// The town in [name] if it is one of ours, else null.
String? matchTown(String? name) {
  if (name == null) return null;
  final wanted = name.trim().toLowerCase();
  for (final town in kTowns) {
    if (town.toLowerCase() == wanted) return town;
  }
  return null;
}

/// A quantity between 0 and 100,000 (anything else is dropped).
double? clampQuantity(Object? value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  if (number == null || number <= 0) return null;
  return number > 100000 ? 100000 : number;
}

/// Reads the AI's JSON, e.g. {"crop":"Tomato","town":"Leon","quantity":10,
/// "sort":"price"}. Unknown crops and towns are dropped, so the AI can't
/// make the app search for something we don't have. Returns null when the
/// text is not usable JSON.
SearchQuery? parseSearchQuery(String text) {
  try {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    final data = jsonDecode(text.substring(start, end + 1));
    if (data is! Map) return null;
    return SearchQuery(
      crop: matchCrop(data['crop'] as String?),
      town: matchTown(data['town'] as String?),
      quantity: clampQuantity(data['quantity']),
      sort: switch (data['sort']) {
        'available' => SearchSort.available,
        'newest' => SearchSort.newest,
        _ => SearchSort.price,
      },
    );
  } catch (_) {
    return null;
  }
}

/// The amount in a question like "pechay 10 kg" or "5 kilos", or null.
double? quantityIn(String text) {
  final match = RegExp(
    r'(\d+(?:\.\d+)?)\s*(kg|kilo|kilos|bundle|sack|piece|pcs)?',
    caseSensitive: false,
  ).firstMatch(text);
  return match == null ? null : clampQuantity(match.group(1));
}

/// The search without AI: finds a known crop and town in the words.
SearchQuery keywordQuery(String text) {
  final lower = text.toLowerCase();
  String? crop;
  for (final info in kCropCatalog) {
    final names = [info.name, ...info.localNames].map((n) => n.toLowerCase());
    if (names.any((n) => RegExp('\\b${RegExp.escape(n)}\\b').hasMatch(lower))) {
      crop = info.name;
      break;
    }
  }
  String? town;
  for (final t in kTowns) {
    if (lower.contains(t.toLowerCase())) {
      town = t;
      break;
    }
  }
  final sort = RegExp(r'most|biggest|largest|available|stock').hasMatch(lower)
      ? SearchSort.available
      : RegExp(r'new|latest|fresh').hasMatch(lower)
      ? SearchSort.newest
      : SearchSort.price;
  return SearchQuery(
    crop: crop,
    town: town,
    quantity: quantityIn(text),
    sort: sort,
  );
}

/// Up to [limit] listings that match [query] and still have stock, sorted.
/// When the buyer said an amount, listings with enough stock come first.
List<Listing> searchListings(
  List<Listing> listings,
  SearchQuery query, {
  int limit = 5,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final found = listings.where((l) {
    if (!l.isActive || l.availableAt(at) <= 0) return false;
    if (query.crop != null && l.crop != query.crop) return false;
    if (query.town != null && l.town != query.town) return false;
    return true;
  }).toList();
  found.sort((a, b) {
    final qty = query.quantity;
    if (qty != null) {
      final aEnough = a.availableAt(at) >= qty,
          bEnough = b.availableAt(at) >= qty;
      if (aEnough != bEnough) return aEnough ? -1 : 1;
    }
    return switch (query.sort) {
      SearchSort.price => a.price.compareTo(b.price),
      SearchSort.available => b.availableAt(at).compareTo(a.availableAt(at)),
      SearchSort.newest => b.createdAt.compareTo(a.createdAt),
    };
  });
  return found.take(limit).toList();
}

// -------------------------------------------------------- intent and data

/// Guesses what kind of question [text] is, using the page as a hint.
AssistantIntent detectIntent(String text, AssistantPage page) {
  final lower = text.toLowerCase();
  bool has(String pattern) => RegExp(pattern).hasMatch(lower);
  if (has(
    r'\bhow (do|can|to)\b|\bwhat is\b.*\b(order|request|follow)|'
    r'\bwhere (do|can)\b|\bexpired?\b|\bfollow',
  )) {
    if (!has(r'how much|total')) return AssistantIntent.howTo;
  }
  if (has(r'reserved|status|waiting|offer mean|what does .* mean')) {
    return page.order != null
        ? AssistantIntent.orderStatus
        : AssistantIntent.howTo;
  }
  if (has(r'how much|total|magkano|pila|for \d|\d+\s*(kg|kilo)')) {
    if (page.listing != null || page.order != null) {
      return AssistantIntent.offerMath;
    }
  }
  if (has(r'going up|trend|rising|falling|tumaas|bumaba')) {
    return AssistantIntent.trend;
  }
  if (has(
    r'fair|expensive|cheap(er)? than|reference|psa|explain .*price|'
    r'mahal|barato',
  )) {
    if (page.pageCrop != null || keywordQuery(text).crop != null) {
      return AssistantIntent.priceCheck;
    }
  }
  if (has(
    r'find|cheapest|search|available|near|where|show|looking for|'
    r'may .* ba|buy',
  )) {
    return AssistantIntent.search;
  }
  if (keywordQuery(text).crop != null) return AssistantIntent.search;
  return AssistantIntent.howTo;
}

/// Farmer-written text (titles, descriptions, notes) is data, not orders
/// for the AI: we cut it short and remove characters that could fake the
/// start or end of our data block.
String cleanUntrusted(String text, {int max = 120}) {
  final flat = text
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(RegExp(r'[<>{}\[\]`]'), '');
  return flat.length <= max ? flat.trim() : '${flat.substring(0, max).trim()}…';
}

/// A listing as facts for the AI: only what the Market already shows.
/// No ids, no emails, no phone numbers.
Map<String, dynamic> listingFacts(Listing l, {DateTime? now}) => {
  'title': cleanUntrusted(l.headline, max: 40),
  'crop': l.crop,
  'pricePerUnit': l.price,
  'unit': l.unit,
  'available': l.availableAt(now ?? DateTime.now()),
  'town': l.town,
  'farmer': cleanUntrusted(l.farmerName, max: 40),
};

/// The facts as compact JSON, cut to about 600 tokens (~2,400 characters).
String factsJson(Map<String, dynamic> facts, {int maxChars = 2400}) {
  final text = jsonEncode(facts);
  return text.length <= maxChars ? text : text.substring(0, maxChars);
}

// ----------------------------------------------------------------- limits

/// Keeps the assistant inside Gemini's free tier: one question at a
/// time, 3 seconds between questions and 20 questions per session.
class AssistantLimits {
  AssistantLimits({
    this.cooldown = const Duration(seconds: 3),
    this.maxPerSession = 20,
  });

  final Duration cooldown;
  final int maxPerSession;
  bool isBusy = false;
  DateTime? _lastAsked;
  int asked = 0;

  /// Null when the buyer may ask now; otherwise the friendly reason.
  /// After [maxPerSession] questions the buyer can still ask: the app then
  /// answers with its own facts only (see [aiAllowed]).
  String? whyNot(DateTime now) {
    if (isBusy) return 'Please wait for the answer to the last question.';
    final last = _lastAsked;
    if (last != null && now.difference(last) < cooldown) {
      return 'Please wait a few seconds before the next question.';
    }
    return null;
  }

  /// True when the AI may be used for this question (else: facts only).
  bool get aiAllowed => asked < maxPerSession;

  /// Call when a question starts; [usesAi] counts it toward the limit.
  void started(DateTime now, {bool usesAi = true}) {
    isBusy = true;
    _lastAsked = now;
    if (usesAi) asked++;
  }

  void finished() => isBusy = false;

  void reset() {
    asked = 0;
    _lastAsked = null;
    isBusy = false;
  }
}
