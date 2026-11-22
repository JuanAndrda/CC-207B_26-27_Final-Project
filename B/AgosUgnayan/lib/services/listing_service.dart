// Reads and writes crop listings in Firestore (listings collection).
// Screens never call Firestore directly; they call this service.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

/// One page of Marketplace results, plus what we need to load the next page.
class ListingPage {
  const ListingPage(this.listings, this.lastDoc, this.hasMore);

  final List<Listing> listings;
  final DocumentSnapshot? lastDoc; // start the next page after this one
  final bool hasMore; // false when there is nothing more to load
}

/// Create, read, update and delete crop listings.
class ListingService {
  // A getter (not a field) so Firebase is only touched when we really use it.
  CollectionReference<Map<String, dynamic>> get _listings =>
      FirebaseFirestore.instance.collection('listings');

  /// Loads one page of the Marketplace, newest first.
  /// [crop] and [town] are optional filters (null = all).
  /// Pass the previous page's [after] to load the next page.
  Future<ListingPage> fetchPage({
    String? crop,
    String? town,
    DocumentSnapshot? after,
  }) {
    return runSafely('load marketplace', () async {
      Query<Map<String, dynamic>> query = _listings;
      if (crop != null) query = query.where('crop', isEqualTo: crop);
      if (town != null) query = query.where('town', isEqualTo: town);
      query = query.orderBy('createdAt', descending: true).limit(kPageSize);
      if (after != null) query = query.startAfterDocument(after);

      final snapshot = await query.get();
      final listings = snapshot.docs
          .map((doc) => Listing.fromMap(doc.id, doc.data()))
          .toList();
      return ListingPage(
        listings,
        snapshot.docs.isEmpty ? after : snapshot.docs.last,
        snapshot.docs.length == kPageSize,
      );
    });
  }

  /// All listings of one farmer, newest first (for My Crops and the
  /// farmer's profile). One farmer has few listings, so we load them all.
  Future<List<Listing>> fetchByFarmer(String farmerId) {
    return runSafely('load farmer listings', () async {
      final snapshot = await _listings
          .where('farmerId', isEqualTo: farmerId)
          .get();
      final listings = snapshot.docs
          .map((doc) => Listing.fromMap(doc.id, doc.data()))
          .toList();
      // Sorting here instead of in Firestore means we need no extra index.
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  /// Loads one listing, or null if it was deleted.
  Future<Listing?> fetchById(String id) {
    return runSafely('load listing', () async {
      final doc = await _listings.doc(id).get();
      if (!doc.exists) return null;
      return Listing.fromMap(doc.id, doc.data()!);
    });
  }

  /// Adds a new listing (when id is empty) or updates an existing one.
  Future<void> save(Listing listing) {
    return runSafely('save listing', () async {
      if (listing.id.isEmpty) {
        await _listings.add({
          ...listing.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _listings.doc(listing.id).update(listing.toMap());
      }
    });
  }

  /// The newest [limit] listings that are for sale, with optional crop
  /// and town filters (null = all). The Market searches, filters, sorts
  /// and splits these into pages on the phone, so all of those work
  /// together. Sold out and removed listings are left out.
  Future<List<Listing>> fetchForMarket({
    String? crop,
    String? town,
    int limit = 100,
  }) {
    return runSafely('load marketplace', () async {
      Query<Map<String, dynamic>> query = _listings;
      if (crop != null) query = query.where('crop', isEqualTo: crop);
      if (town != null) query = query.where('town', isEqualTo: town);
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => Listing.fromMap(doc.id, doc.data()))
          .where((listing) => listing.isActive)
          .toList();
    });
  }

  /// Changes only a listing's status, e.g. to sold out.
  Future<void> setStatus(String id, String status) {
    return runSafely(
      'change listing status',
      () => _listings.doc(id).update({'status': status}),
    );
  }

  Future<void> delete(String id) {
    return runSafely('delete listing', () => _listings.doc(id).delete());
  }

  /// Puts a deleted listing back exactly as it was (for the Undo button).
  Future<void> restore(Listing listing) {
    return runSafely('restore listing', () {
      return _listings.doc(listing.id).set({
        ...listing.toMap(),
        'createdAt': Timestamp.fromDate(listing.createdAt),
      });
    });
  }
}
