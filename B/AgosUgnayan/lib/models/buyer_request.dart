// A crop request posted by a buyer ("I need 100 kg of tomatoes by Friday"),
// saved in Firestore at requests/{id}.

import 'firestore_date.dart';

/// One thing a buyer wants to buy.
class BuyerRequest {
  const BuyerRequest({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.crop,
    required this.quantity,
    required this.unit,
    required this.targetPrice,
    required this.town,
    required this.neededBy,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String buyerId;
  final String buyerName;
  final String crop;
  final double quantity;
  final String unit;
  final double? targetPrice; // optional: the price the buyer hopes to pay
  final String town;
  final DateTime neededBy;
  final String notes;
  final DateTime createdAt;

  /// A request is closed once its "needed by" day has passed. We work this out
  /// when reading, so nothing has to update the database every day.
  bool get isClosed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return neededBy.isBefore(today);
  }

  /// Builds a request from a Firestore document.
  factory BuyerRequest.fromMap(String id, Map<String, dynamic> data) {
    final target = data['targetPrice'];
    return BuyerRequest(
      id: id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      crop: data['crop'] as String? ?? '',
      quantity: readDouble(data['quantity']),
      unit: data['unit'] as String? ?? 'kg',
      targetPrice: target == null ? null : readDouble(target),
      town: data['town'] as String? ?? '',
      neededBy: readDate(data['neededBy']),
      notes: data['notes'] as String? ?? '',
      createdAt: readDate(data['createdAt']),
    );
  }

  /// The fields we save to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'crop': crop,
      'quantity': quantity,
      'unit': unit,
      'targetPrice': targetPrice,
      'town': town,
      'neededBy': neededBy,
      'notes': notes,
    };
  }
}
