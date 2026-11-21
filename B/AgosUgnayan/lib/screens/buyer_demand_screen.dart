// F5 Buyer Requests, farmer side: "Buyer Demand" lists what buyers need,
// soonest first, with a crop filter.

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../services/request_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/request_card.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('BUYER DEMAND')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final crop in [null, ...kCrops])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(crop ?? 'All crops'),
                      selected: _crop == crop,
                      onSelected: (_) => setState(() => _crop = crop),
                    ),
                  ),
              ],
            ),
          ),
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
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
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
