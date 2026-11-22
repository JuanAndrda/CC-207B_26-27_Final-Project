// How one crop listing looks. ListingCard is a row for lists (My Crops, a
// farmer's profile); ListingGridCard is a tile for the Marketplace grid.
// Both match the website's crop rows and crop cards.

import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'crop_thumb.dart';

/// Crop, amount, town and farmer on the left, asking price on the right.
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                const CropThumb(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.crop,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: AppTextStyles.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.small),
                PriceText(price: listing.price, unit: listing.unit),
                // "?" adds trailing only when it is not null.
                ?trailing,
                if (trailing == null) const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Marketplace tile: green photo area on top, crop and price below.
class ListingGridCard extends StatelessWidget {
  const ListingGridCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo placeholder, 16:10 like the website's crop cards.
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.eco_outlined,
                  size: 36,
                  color: AppColors.link,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.crop,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatQuantity(listing.quantity)} ${listing.unit} · '
                    '${listing.town}',
                    style: AppTextStyles.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    listing.farmerName,
                    style: AppTextStyles.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  PriceText(
                    price: listing.price,
                    unit: listing.unit,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A price in dark green with a small grey "/kg" after it, e.g. "₱45.00/kg".
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    required this.unit,
    this.fontSize = 17,
  });

  final double price;
  final String unit;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: formatPeso(price),
        style: AppTextStyles.price.copyWith(fontSize: fontSize),
        children: [
          TextSpan(
            text: '/$unit',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
