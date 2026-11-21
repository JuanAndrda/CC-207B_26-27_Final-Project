// F6 Reference Prices: the latest monthly price of every crop, with the
// change from the month before. Works offline using the saved copy.
// The admin also gets an "Add price" button here.

import 'package:flutter/material.dart';

import '../models/price_record.dart';
import '../services/auth_service.dart';
import '../services/price_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import 'admin_price_form_screen.dart';
import 'price_detail_screen.dart';

/// Prices tab for farmers and the admin.
class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  PriceData? _data;
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
      final data = await PriceService().fetchRecent();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openAdminForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminPriceFormScreen()),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final records = _data?.records ?? [];
    // Only crops that have at least one price.
    final crops = kCrops
        .where((crop) => PriceService.latestFor(crop, records) != null)
        .toList();
    final isAdmin = AuthService.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('MARKET PRICES')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openAdminForm,
              icon: const Icon(Icons.add),
              label: const Text('Add price'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncStateView(
          isLoading: _isLoading,
          errorMessage: _error,
          onRetry: _load,
          isEmpty: crops.isEmpty,
          emptyMessage: isAdmin
              ? 'No prices yet. Tap "Add price" to enter this month\'s prices.'
              : 'No reference prices yet. Please check again later.',
          builder: (context) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              const Text(
                'Reference farmgate prices per kg. Source: $kPriceSource. '
                'These are monthly averages, not live prices.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (_data?.savedCopyFrom != null) _buildOfflineNote(),
              const SizedBox(height: AppSizes.small),
              for (final crop in crops) _buildRow(crop, records),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when there was no internet and we use the saved copy.
  Widget _buildOfflineNote() {
    return Card(
      color: AppColors.dangerLight,
      margin: const EdgeInsets.only(top: AppSizes.small),
      child: ListTile(
        leading: const Icon(Icons.cloud_off, color: AppColors.danger),
        title: Text(
          'Offline: showing prices saved on ${formatDate(_data!.savedCopyFrom!)}.',
        ),
        trailing: TextButton(onPressed: _load, child: const Text('Retry')),
      ),
    );
  }

  Widget _buildRow(String crop, List<PriceRecord> records) {
    final history = PriceService.historyFor(crop, records);
    final latest = history.last;
    // Compare with the month before, if we have it.
    final previous = history.length > 1 ? history[history.length - 2] : null;
    final change = previous == null ? 0.0 : latest.price - previous.price;
    final changeText = previous == null
        ? 'New'
        : change == 0
        ? 'No change'
        : '${change > 0 ? '▲' : '▼'} ${formatPeso(change.abs())}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.small),
      child: ListTile(
        title: Text(crop, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(formatMonthKey(latest.month)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${formatPeso(latest.price)}/kg',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            Text(changeText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PriceDetailScreen(crop: crop, history: history),
          ),
        ),
      ),
    );
  }
}
