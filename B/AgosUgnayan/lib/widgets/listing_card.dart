// A card that shows one crop listing. Used in My Crops, the Marketplace and
// a farmer's profile, so listings look the same everywhere.

import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../utils/format.dart';
import '../utils/theme.dart';

/// Crop, amount, asking price, town and farmer of one listing.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.trailing,
    this.showFarmer = true,
  });

  final Listing listing;
  final VoidCallback onTap;

  /// Optional widget on the right, e.g. an Edit/Delete menu.
  final Widget? trailing;

  /// False on screens that are already about one farmer.
  final bool showFarmer;

  @override
  Widget build(BuildContext context) {
    final details = [
      '${formatQuantity(listing.quantity)} ${listing.unit}',
      listing.town,
      if (showFarmer) listing.farmerName,
    ].join(' · ');

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePadding,
          vertical: 4,
        ),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.eco, color: AppColors.primaryDark),
        ),
        title: Text(
          listing.crop,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(details),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${formatPeso(listing.price)}/${listing.unit}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            // "?" adds trailing only when it is not null.
            ?trailing,
          ],
        ),
      ),
    );
  }
}
