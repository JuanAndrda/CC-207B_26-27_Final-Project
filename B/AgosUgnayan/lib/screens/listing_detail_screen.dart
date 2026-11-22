// F2 Marketplace: the details of one crop listing. Buyers can follow it,
// message the farmer, or open the farmer's profile.

import 'package:flutter/material.dart';

import '../models/followed_item.dart';
import '../models/listing.dart';
import '../services/auth_service.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/ai_assistant_box.dart';
import '../widgets/follow_button.dart';
import '../widgets/info_row.dart';
import '../widgets/listing_card.dart';
import '../widgets/message_button.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_body.dart';
import 'farmer_profile_screen.dart';

/// Shows everything about [listing].
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser!;
    final isMine = listing.farmerId == me.id;
    final amount = '${formatQuantity(listing.quantity)} ${listing.unit}';

    return Scaffold(
      appBar: AppBar(title: Text(listing.crop)),
      body: ResponsiveBody(
        maxWidth: AppSizes.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            // Photo placeholder, like the website's crop hero image.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: AppColors.primaryLight,
                  child: const Icon(
                    Icons.eco_outlined,
                    size: 56,
                    color: AppColors.link,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.fieldGap),
            PageHeader(
              eyebrow: '${listing.town}, Iloilo',
              title: listing.crop,
              lead: '$amount available from ${listing.farmerName}.',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  price: listing.price,
                  unit: listing.unit,
                  fontSize: 26,
                ),
                const SizedBox(width: AppSizes.small),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('asking price', style: AppTextStyles.meta),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sectionGap),
            Card(
              child: Column(
                children: [
                  InfoRow(icon: Icons.scale, label: 'Available', value: amount),
                  InfoRow(
                    icon: Icons.location_on,
                    label: 'Town',
                    value: '${listing.town}, Iloilo',
                  ),
                  InfoRow(
                    icon: Icons.event,
                    label: 'Harvest date',
                    value: listing.harvestDate == null
                        ? 'Not given'
                        : formatDate(listing.harvestDate!),
                  ),
                  InfoRow(
                    icon: Icons.person,
                    label: 'Farmer',
                    value: listing.farmerName,
                  ),
                  if (listing.description.isNotEmpty)
                    InfoRow(
                      icon: Icons.notes,
                      label: 'Description',
                      value: listing.description,
                    ),
                ],
              ),
            ),
            if (listing.aiAssisted) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: AiGeneratedChip(),
              ),
              const SizedBox(height: 4),
              const Text(
                'The farmer used the AI assistant to write this listing and '
                'checked it before posting.',
                style: AppTextStyles.meta,
              ),
            ],
            const SizedBox(height: AppSizes.sectionGap),
            // Buyers get actions; a farmer looking at their own crop does not.
            if (!isMine && me.isBuyer) ...[
              MessageButton(
                otherId: listing.farmerId,
                otherName: listing.farmerName,
                label: 'Message farmer',
                firstMessage:
                    'Hi! Is your ${listing.crop} ($amount) still available?',
              ),
              const SizedBox(height: AppSizes.small),
              Row(
                children: [
                  Expanded(
                    child: FollowButton(
                      targetId: listing.id,
                      type: FollowType.listing,
                      title: '${listing.crop} · $amount',
                      subtitle:
                          '${formatPeso(listing.price)}/${listing.unit} · '
                          '${listing.farmerName}, ${listing.town}',
                    ),
                  ),
                  const SizedBox(width: AppSizes.small),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FarmerProfileScreen(farmerId: listing.farmerId),
                        ),
                      ),
                      icon: const Icon(Icons.person),
                      label: const Text('View farmer'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
