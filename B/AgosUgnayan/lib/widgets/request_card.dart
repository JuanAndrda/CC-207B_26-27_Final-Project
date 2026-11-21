// A card that shows one buyer request. Used in My Requests (buyer) and
// Buyer Demand (farmer).

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../utils/format.dart';
import '../utils/theme.dart';

/// Crop, amount, needed-by date, town and an Open/Closed label.
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
    final target = request.targetPrice == null
        ? ''
        : ' · target ${formatPeso(request.targetPrice!)}/${request.unit}';
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.assignment, color: AppColors.primaryDark),
        ),
        title: Text('${request.crop} · $amount'),
        subtitle: Text(
          'Needed by ${formatDate(request.neededBy)} · ${request.town}$target',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text, not just color, so the status is clear to everyone.
            Text(
              request.isClosed ? 'Closed' : 'Open',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: request.isClosed
                    ? AppColors.textMuted
                    : AppColors.primaryDark,
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
