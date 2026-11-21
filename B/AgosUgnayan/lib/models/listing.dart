// A crop listing posted by a farmer, saved in Firestore at listings/{id}.

import 'firestore_date.dart';

/// One crop a farmer is selling, e.g. "Tomato, 50 kg at ₱45.00/kg".
class Listing {
  const Listing({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.crop,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.town,
    required this.harvestDate,
    required this.description,
    required this.aiAssisted,
    required this.createdAt,
  });

  final String id; // empty for a new listing that is not saved yet
  final String farmerId;
  final String farmerName;
  final String crop; // one of kCrops
  final double quantity;
  final String unit; // one of kUnits
  final double price; // asking price per unit, in pesos
  final String town;
  final DateTime? harvestDate; // optional
  final String description;
  final bool aiAssisted; // true if the AI assistant helped fill the form
  final DateTime createdAt;

  /// Builds a listing from a Firestore document.
  factory Listing.fromMap(String id, Map<String, dynamic> data) {
    return Listing(
      id: id,
      farmerId: data['farmerId'] as String? ?? '',
      farmerName: data['farmerName'] as String? ?? '',
      crop: data['crop'] as String? ?? '',
      quantity: readDouble(data['quantity']),
      unit: data['unit'] as String? ?? 'kg',
      price: readDouble(data['price']),
      town: data['town'] as String? ?? '',
      harvestDate: readOptionalDate(data['harvestDate']),
      description: data['description'] as String? ?? '',
      aiAssisted: data['aiAssisted'] as bool? ?? false,
      createdAt: readDate(data['createdAt']),
    );
  }

  /// The fields we save to Firestore. createdAt is set by the service.
  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'crop': crop,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'town': town,
      'harvestDate': harvestDate,
      'description': description,
      'aiAssisted': aiAssisted,
    };
  }
}
