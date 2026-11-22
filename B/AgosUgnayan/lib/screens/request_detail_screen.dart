// F5 Buyer Requests: the details of one request. Farmers can message the
// buyer from here.

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../services/auth_service.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/info_row.dart';
import '../widgets/message_button.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_body.dart';
import '../widgets/status_badge.dart';

/// Shows everything about [request].
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.request});

  final BuyerRequest request;

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser!;
    final amount = '${formatQuantity(request.quantity)} ${request.unit}';
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer request')),
      body: ResponsiveBody(
        maxWidth: AppSizes.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                label: request.isClosed ? 'Closed' : 'Open',
                kind: request.isClosed ? StatusKind.closed : StatusKind.open,
              ),
            ),
            const SizedBox(height: 10),
            PageHeader(
              eyebrow: 'Wanted by ${request.buyerName}',
              title: '${request.crop}, $amount',
              lead:
                  'Needed by ${formatDate(request.neededBy)} in '
                  '${request.town}.',
            ),
            const SizedBox(height: AppSizes.sectionGap),
            Card(
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.person,
                    label: 'Buyer',
                    value: request.buyerName,
                  ),
                  InfoRow(
                    icon: Icons.event,
                    label: 'Needed by',
                    value: formatDate(request.neededBy),
                  ),
                  InfoRow(
                    icon: Icons.location_on,
                    label: 'Town',
                    value: '${request.town}, Iloilo',
                  ),
                  InfoRow(
                    icon: Icons.sell,
                    label: 'Target price',
                    value: request.targetPrice == null
                        ? 'Open to offers'
                        : '${formatPeso(request.targetPrice!)}/${request.unit}',
                  ),
                  if (request.notes.isNotEmpty)
                    InfoRow(
                      icon: Icons.notes,
                      label: 'Notes',
                      value: request.notes,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sectionGap),
            if (me.isFarmer && !request.isClosed)
              MessageButton(
                otherId: request.buyerId,
                otherName: request.buyerName,
                label: 'Message buyer',
                firstMessage:
                    'Hi! I saw your request for ${request.crop} ($amount). '
                    'I can supply it.',
              ),
          ],
        ),
      ),
    );
  }
}
