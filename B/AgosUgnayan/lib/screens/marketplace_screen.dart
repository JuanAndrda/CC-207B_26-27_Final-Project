// F2 Marketplace: buyers browse every crop for sale. It has a search box
// (debounced), crop and town filters, pull-to-refresh, and loads 20
// listings at a time as the buyer scrolls down (pagination).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../services/listing_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

/// The buyer's Market tab.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _service = ListingService();
  final _scrollController = ScrollController();
  Timer? _searchTimer;

  List<Listing> _listings = [];
  DocumentSnapshot? _lastDoc; // where the next page starts
  bool _hasMore = true;
  bool _isLoading = true; // first page
  bool _isLoadingMore = false; // next pages
  String? _error;

  String _search = '';
  String? _crop; // null = all crops
  String? _town; // null = all towns

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    // Load the next page when the buyer is near the bottom of the list.
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels > position.maxScrollExtent - 200) _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _service.fetchPage(crop: _crop, town: _town);
      if (!mounted) return;
      setState(() {
        _listings = page.listings;
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.fetchPage(
        crop: _crop,
        town: _town,
        after: _lastDoc,
      );
      if (!mounted) return;
      setState(() {
        _listings.addAll(page.listings);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      // Keep what we have; scrolling again will retry.
    }
    if (mounted) setState(() => _isLoadingMore = false);
  }

  /// Waits 300 ms after the last key press before filtering, so the list
  /// doesn't jump on every letter (debounce).
  void _onSearchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _search = text.trim().toLowerCase());
    });
  }

  /// Search matches the crop, farmer, town or description of loaded listings.
  List<Listing> get _visibleListings {
    if (_search.isEmpty) return _listings;
    return _listings.where((listing) {
      final text =
          '${listing.crop} ${listing.farmerName} ${listing.town} '
                  '${listing.description}'
              .toLowerCase();
      return text.contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleListings;
    return Scaffold(
      appBar: AppBar(title: const Text('MARKETPLACE')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFirstPage,
              child: AsyncStateView(
                isLoading: _isLoading,
                errorMessage: _error,
                onRetry: _loadFirstPage,
                isEmpty: visible.isEmpty,
                emptyMessage: _search.isNotEmpty
                    ? 'No results for "$_search".'
                    : 'No crops for sale with these filters yet.',
                builder: (context) => ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  // One extra row at the end for the "loading more" spinner.
                  itemCount: visible.length + 1,
                  itemBuilder: (context, index) {
                    if (index == visible.length) return _buildListEnd();
                    final listing = visible[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.small),
                      child: ListingCard(
                        listing: listing,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ListingDetailScreen(listing: listing),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search box, town dropdown and crop chips.
  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search crop, farmer, town…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.small),
              DropdownButton<String?>(
                value: _town,
                hint: const Text('All towns'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All towns')),
                  for (final town in kTowns)
                    DropdownMenuItem(value: town, child: Text(town)),
                ],
                onChanged: (town) {
                  setState(() => _town = town);
                  _loadFirstPage();
                },
              ),
            ],
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final crop in [null, ...kCrops])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(crop ?? 'All crops'),
                      selected: _crop == crop,
                      onSelected: (_) {
                        setState(() => _crop = crop);
                        _loadFirstPage();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Spinner while loading more, or "That's everything" at the very end.
  Widget _buildListEnd() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text("That's all the crops for now.")),
      );
    }
    return const SizedBox(height: 48);
  }
}
