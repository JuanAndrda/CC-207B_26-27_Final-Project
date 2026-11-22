// A card that shows one buyer request. Used in My Requests (buyer) and
// Buyer Demand (farmer). Looks like the website's request cards.

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'crop_thumb.dart';
import 'status_badge.dart';

/// Crop and amount, needed-by date, town, target price and an Open/Closed pill.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.trailing,
  });

  final BuyerRequest request;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final amount = '${formatQuantity(request.quantity)} ${request.unit}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CropThumb(icon: Icons.assignment_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.crop}, $amount',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Needed by ${formatDate(request.neededBy)} · '
                      '${request.town}',
                      style: AppTextStyles.meta,
                    ),
                    if (request.targetPrice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Target ${formatPeso(request.targetPrice!)}/${request.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.small),
              // Text, not just color, so the status is clear to everyone.
              StatusBadge(
                label: request.isClosed ? 'Closed' : 'Open',
                kind: request.isClosed ? StatusKind.closed : StatusKind.open,
              ),
              // "?" adds trailing only when it is not null.
              ?trailing,
              if (trailing == null) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
