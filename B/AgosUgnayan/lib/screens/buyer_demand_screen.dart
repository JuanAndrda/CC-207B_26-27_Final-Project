// F5 Buyer Requests, farmer side: "Buyer Demand" lists what buyers need,
// soonest first, with a crop filter.

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../services/request_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/chip_filter_row.dart';
import '../widgets/page_header.dart';
import '../widgets/request_card.dart';
import '../widgets/tab_page.dart';
import 'request_detail_screen.dart';

/// Open buyer requests for farmers.
class BuyerDemandScreen extends StatefulWidget {
  const BuyerDemandScreen({super.key});

  @override
  State<BuyerDemandScreen> createState() => _BuyerDemandScreenState();
}

class _BuyerDemandScreenState extends State<BuyerDemandScreen> {
  List<BuyerRequest> _requests = [];
  String? _crop; // null = all crops
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
      final requests = await RequestService().fetchOpen();
      if (mounted) setState(() => _requests = requests);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _crop == null
        ? _requests
        : _requests.where((r) => r.crop == _crop).toList();
    return TabPage(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'Buyers in Iloilo',
            title: 'Buyer demand',
            lead: _isLoading
                ? 'What local buyers are looking for.'
                : '${_requests.length} open request'
                      '${_requests.length == 1 ? '' : 's'}, soonest first.',
          ),
          const SizedBox(height: 14),
          ChipFilterRow(
            options: kCrops,
            selected: _crop,
            onSelected: (crop) => setState(() => _crop = crop),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: AsyncStateView(
                isLoading: _isLoading,
                errorMessage: _error,
                onRetry: _load,
                isEmpty: visible.isEmpty,
                emptyMessage: _crop == null
                    ? 'No buyer requests right now. Pull down to refresh.'
                    : 'No buyers need $_crop right now.',
                builder: (context) => ListView.builder(
                  padding: TabPage.listPadding,
                  itemCount: visible.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.small),
                    child: RequestCard(
                      request: visible[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestDetailScreen(request: visible[index]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
