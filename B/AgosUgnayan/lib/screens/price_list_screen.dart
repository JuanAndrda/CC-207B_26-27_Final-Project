// F6 Reference Prices: the latest monthly price of every crop, with the
// change from the month before. Works offline using the saved copy.
// The admin also gets "Get latest PSA prices" (downloads real prices from
// PSA OpenSTAT) and "Add price" (type one price by hand) here.

import 'package:flutter/material.dart';

import '../models/price_record.dart';
import '../services/auth_service.dart';
import '../services/price_service.dart';
import '../services/psa_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/snackbars.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/crop_thumb.dart';
import '../widgets/listing_card.dart';
import '../widgets/notice_box.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_page.dart';
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
  bool _isImporting = false;
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

  /// Downloads the last 24 months of PSA farmgate prices and saves them.
  /// Saving the same crop and month again only updates it.
  Future<void> _importFromPsa() async {
    setState(() => _isImporting = true);
    try {
      final result = await PsaService().fetchFarmgate();
      if (result.records.isEmpty) {
        throw const AppException('PSA has no new prices for our crops yet.');
      }
      await PriceService().saveMany(
        result.records,
        AuthService.currentUser!.id,
      );
      if (!mounted) return;
      final newest = result.records
          .map((record) => record.month)
          .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      final missing = result.missingCrops.isEmpty
          ? ''
          : ' No PSA price for ${result.missingCrops.join(', ')}.';
      showMessage(
        context,
        'Saved ${result.records.length} PSA prices '
        '(newest: ${formatMonthKey(newest)}).$missing',
      );
      _load();
    } catch (e) {
      if (mounted) showError(context, friendlyMessage(e));
    }
    if (mounted) setState(() => _isImporting = false);
  }

  /// The admin's two buttons under the page heading.
  Widget _buildAdminActions() {
    return Wrap(
      spacing: AppSizes.small,
      runSpacing: AppSizes.small,
      children: [
        FilledButton.icon(
          onPressed: _isImporting ? null : _importFromPsa,
          icon: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_download_outlined),
          label: Text(
            _isImporting ? 'Getting PSA prices…' : 'Get latest PSA prices',
          ),
        ),
        OutlinedButton.icon(
          onPressed: _isImporting ? null : _openAdminForm,
          icon: const Icon(Icons.add),
          label: const Text('Add price'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _data?.records ?? [];
    // Only crops that have at least one price.
    final crops = kCrops
        .where((crop) => PriceService.latestFor(crop, records) != null)
        .toList();
    final isAdmin = AuthService.currentUser?.isAdmin ?? false;

    return TabPage(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            eyebrow: 'Farmgate prices',
            title: 'Market prices',
            lead:
                'Monthly averages per kg from $kPriceSource (PSA '
                'OpenSTAT). A guide, not live prices.',
          ),
          if (isAdmin) ...[const SizedBox(height: 12), _buildAdminActions()],
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: AsyncStateView(
          isLoading: _isLoading,
          errorMessage: _error,
          onRetry: _load,
          isEmpty: crops.isEmpty,
          emptyMessage: isAdmin
              ? 'No prices yet. Tap "Get latest PSA prices" to download them.'
              : 'No reference prices yet. Please check again later.',
          builder: (context) => ListView(
            padding: TabPage.listPadding,
            children: [
              if (_data?.savedCopyFrom != null) ...[
                _buildOfflineNote(),
                const SizedBox(height: 12),
              ],
              // One white box with a row per crop (website .list).
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < crops.length; i++) ...[
                      if (i > 0) const Divider(),
                      _buildRow(crops[i], records),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when there was no internet and we use the saved copy.
  Widget _buildOfflineNote() {
    return Row(
      children: [
        Expanded(
          child: NoticeBox(
            kind: NoticeKind.warning,
            message:
                'Offline: showing prices saved on '
                '${formatDate(_data!.savedCopyFrom!)}.',
          ),
        ),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ],
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
    // Green when the price went up, red (with ▼) when it went down.
    final changeColor = previous == null || change == 0
        ? AppColors.textMuted
        : change > 0
        ? AppColors.primaryDark
        : AppColors.danger;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PriceDetailScreen(crop: crop, history: history),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CropThumb(crop: crop),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$kPriceSource · ${formatMonthKey(latest.month)}',
                    style: AppTextStyles.meta,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(price: latest.price, unit: 'kg'),
                Text(
                  changeText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
