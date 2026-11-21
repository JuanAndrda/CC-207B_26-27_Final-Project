// F6 Reference Prices: one crop's price over the last 12 months, as a line
// chart (fl_chart) and as a list.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/price_record.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/theme.dart';

/// Price history of [crop]. [history] is sorted oldest month first.
class PriceDetailScreen extends StatelessWidget {
  const PriceDetailScreen({
    super.key,
    required this.crop,
    required this.history,
  });

  final String crop;
  final List<PriceRecord> history;

  @override
  Widget build(BuildContext context) {
    final latest = history.last;
    return Scaffold(
      appBar: AppBar(title: Text(crop.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Text(
            '${formatPeso(latest.price)}/kg',
            style: AppTextStyles.pageTitle.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            '$kPriceSource, ${formatMonthKey(latest.month)}',
            style: AppTextStyles.eyebrow,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          const Text('LAST 12 MONTHS', style: AppTextStyles.eyebrow),
          const SizedBox(height: AppSizes.small),
          SizedBox(height: 220, child: _buildChart()),
          const SizedBox(height: AppSizes.sectionGap),
          // Newest month first in the list.
          for (final record in history.reversed)
            ListTile(
              dense: true,
              title: Text(formatMonthKey(record.month)),
              trailing: Text('${formatPeso(record.price)}/kg'),
            ),
        ],
      ),
    );
  }

  /// A line chart: x = month number (0, 1, 2…), y = price.
  Widget _buildChart() {
    final spots = [
      for (var i = 0; i < history.length; i++)
        FlSpot(i.toDouble(), history[i].price),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              // Skip the label at the very top: it is an odd number that
              // overlaps the line above it.
              getTitlesWidget: (value, meta) => value == meta.max
                  ? const SizedBox.shrink()
                  : Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              // Show the month's short name, e.g. "Aug", under each point.
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                final label = formatMonthKey(history[index].month);
                return Text(
                  label.substring(0, 3),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: AppColors.primaryDark,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
