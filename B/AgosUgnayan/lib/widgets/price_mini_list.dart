// A short list of crop prices for the home dashboards: photo, crop, newest
// PSA price and the change from the month before (▲ green, ▼ red, always
// with the arrow so color is not the only sign).

import 'package:flutter/material.dart';

import '../models/price_record.dart';
import '../screens/price_detail_screen.dart';
import '../services/price_service.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'crop_thumb.dart';
import 'listing_card.dart';

/// Rows for [crops] (only crops that have a price are shown).
class PriceMiniList extends StatelessWidget {
  const PriceMiniList({super.key, required this.crops, required this.records});

  final List<String> crops;
  final List<PriceRecord> records;

  @override
  Widget build(BuildContext context) {
    final withPrice = [
      for (final crop in crops)
        if (PriceService.latestFor(crop, records) != null) crop,
    ];
    if (withPrice.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(
          'No PSA prices yet. The admin downloads them from PSA OpenSTAT.',
          style: AppTextStyles.lead,
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < withPrice.length; i++) ...[
          if (i > 0) const Divider(),
          _row(context, withPrice[i]),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, String crop) {
    final history = PriceService.historyFor(crop, records);
    final latest = history.last;
    final previous = history.length > 1 ? history[history.length - 2] : null;
    final change = previous == null ? 0.0 : latest.price - previous.price;
    final (text, color) = previous == null || change == 0
        ? ('No change', AppColors.textMuted)
        : change > 0
        ? ('▲ ${formatPeso(change)}', AppColors.primaryDark)
        : ('▼ ${formatPeso(change.abs())}', AppColors.danger);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PriceDetailScreen(crop: crop, history: history),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CropThumb(crop: crop, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crop, style: AppTextStyles.cardTitle),
                  Text(
                    'PSA · ${formatMonthKey(latest.month)}',
                    style: AppTextStyles.meta,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(price: latest.price, unit: 'kg', fontSize: 15),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
