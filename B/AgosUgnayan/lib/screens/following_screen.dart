// Following tab (replaces the old Follow and Saved features): the buyer
// switches between the crop listings and the farmers they follow.

import 'package:flutter/material.dart';

import '../models/followed_item.dart';
import '../services/auth_service.dart';
import '../services/following_service.dart';
import '../services/listing_service.dart';
import '../utils/app_exception.dart';
import '../utils/snackbars.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/crop_thumb.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_page.dart';
import 'farmer_profile_screen.dart';
import 'listing_detail_screen.dart';

/// Followed crop listings or farmers, picked with a segmented button.
class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final _service = FollowingService();
  final _userId = AuthService.currentUser!.id;
  String _type = FollowType.listing; // which segment is selected
  List<FollowedItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetch(_userId, _type);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Opens the listing or the farmer, then reloads in case they unfollowed.
  Future<void> _open(FollowedItem item) async {
    Widget? page;
    if (item.type == FollowType.farmer) {
      page = FarmerProfileScreen(farmerId: item.targetId);
    } else {
      try {
        final listing = await ListingService().fetchById(item.targetId);
        if (listing != null) page = ListingDetailScreen(listing: listing);
      } catch (e) {
        if (mounted) showError(context, friendlyMessage(e));
        return;
      }
    }
    if (!mounted) return;
    if (page == null) {
      // The farmer deleted or sold this crop.
      showMessage(context, 'This crop is no longer for sale. We removed it.');
      await _unfollow(item, quiet: true);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
    _load();
  }

  Future<void> _unfollow(FollowedItem item, {bool quiet = false}) async {
    try {
      await _service.unfollow(_userId, item.targetId);
      if (!mounted) return;
      setState(() => _items.remove(item));
      if (!quiet) showMessage(context, 'Removed from Following.');
    } catch (e) {
      if (mounted) showError(context, friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListings = _type == FollowType.listing;
    return TabPage(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'Saved for later',
            title: 'Following',
            lead: 'Crops and farmers you follow.',
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: AppColors.link),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: FollowType.listing,
                  label: Text('Crop Listings'),
                  icon: Icon(Icons.grass),
                ),
                ButtonSegment(
                  value: FollowType.farmer,
                  label: Text('Farmers'),
                  icon: Icon(Icons.agriculture),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() => _type = value.first);
                _load();
              },
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: AsyncStateView(
                isLoading: _isLoading,
                errorMessage: _error,
                onRetry: _load,
                isEmpty: _items.isEmpty,
                emptyMessage: isListings
                    ? 'You are not following any crops yet.\n'
                          'Tap Follow on a crop in the Market.'
                    : 'You are not following any farmers yet.\n'
                          'Tap Follow on a farmer\'s profile.',
                builder: (context) => ListView.builder(
                  padding: TabPage.listPadding,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.small),
                      child: ListTile(
                        onTap: () => _open(item),
                        contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                        leading: isListings
                            ? const CropThumb()
                            : CircleAvatar(
                                radius: 23,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  item.title.isEmpty
                                      ? '?'
                                      : item.title[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: AppTextStyles.meta,
                        ),
                        trailing: IconButton(
                          tooltip: 'Unfollow',
                          icon: const Icon(
                            Icons.favorite,
                            color: AppColors.danger,
                          ),
                          onPressed: () => _unfollow(item),
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
}
