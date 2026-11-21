// A farmer's public profile: name, town, and all their crops for sale.
// Buyers can follow the farmer or message them from here.

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/followed_item.dart';
import '../models/listing.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../utils/app_exception.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/follow_button.dart';
import '../widgets/listing_card.dart';
import '../widgets/message_button.dart';
import 'listing_detail_screen.dart';

/// Loads and shows the farmer with id [farmerId].
class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  AppUser? _farmer;
  List<Listing> _listings = [];
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
      // Load the profile and the listings at the same time.
      final results = await Future.wait([
        AuthService().loadOtherUser(widget.farmerId),
        ListingService().fetchByFarmer(widget.farmerId),
      ]);
      if (!mounted) return;
      setState(() {
        _farmer = results[0] as AppUser;
        _listings = results[1] as List<Listing>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FARMER')),
      body: AsyncStateView(
        isLoading: _isLoading,
        errorMessage: _error,
        onRetry: _load,
        isEmpty: _farmer == null,
        emptyMessage: 'This farmer was not found.',
        builder: (context) => _buildProfile(_farmer!),
      ),
    );
  }

  Widget _buildProfile(AppUser farmer) {
    final isBuyer = AuthService.currentUser!.isBuyer;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: Text(farmer.name[0].toUpperCase()),
          ),
          title: Text(farmer.name, style: AppTextStyles.pageTitle),
          subtitle: Text('Farmer · ${farmer.town}, Iloilo'),
        ),
        if (farmer.about.isNotEmpty) Text(farmer.about),
        const SizedBox(height: AppSizes.fieldGap),
        if (isBuyer) ...[
          MessageButton(
            otherId: farmer.id,
            otherName: farmer.name,
            label: 'Message ${farmer.name}',
          ),
          const SizedBox(height: AppSizes.small),
          FollowButton(
            targetId: farmer.id,
            type: FollowType.farmer,
            title: farmer.name,
            subtitle: 'Farmer · ${farmer.town}',
          ),
        ],
        const SizedBox(height: AppSizes.sectionGap),
        Text(
          'CROPS FOR SALE (${_listings.length})',
          style: AppTextStyles.eyebrow,
        ),
        const SizedBox(height: AppSizes.small),
        if (_listings.isEmpty) const Text('No crops for sale right now.'),
        for (final listing in _listings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.small),
            child: ListingCard(
              listing: listing,
              showFarmer: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(listing: listing),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
