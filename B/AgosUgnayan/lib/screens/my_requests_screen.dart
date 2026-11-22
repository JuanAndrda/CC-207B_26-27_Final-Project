// F5 Buyer Requests: the buyer's own requests, with Add, Edit and Delete.

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../utils/app_exception.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/request_card.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_page.dart';
import 'request_detail_screen.dart';
import 'request_form_screen.dart';

/// The logged-in buyer's crop requests.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _service = RequestService();
  List<BuyerRequest> _requests = [];
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
      final requests = await _service.fetchByBuyer(AuthService.currentUser!.id);
      if (mounted) setState(() => _requests = requests);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openForm([BuyerRequest? request]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RequestFormScreen(request: request)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(BuyerRequest request) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this request?',
      message: 'Farmers will no longer see your ${request.crop} request.',
      confirmLabel: AppStrings.delete,
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.delete(request.id);
      if (!mounted) return;
      setState(() => _requests.remove(request));
      showUndoMessage(
        context,
        'Request deleted.',
        onUndo: () async {
          await _service.restore(request);
          _load();
        },
      );
    } catch (e) {
      if (mounted) showError(context, friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      header: PageHeader(
        eyebrow: 'What you need',
        title: 'My requests',
        lead: 'Farmers see these in Buyer Demand and can message you.',
        trailing: FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Post request'),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: AsyncStateView(
          isLoading: _isLoading,
          errorMessage: _error,
          onRetry: _load,
          isEmpty: _requests.isEmpty,
          emptyMessage:
              'No requests yet.\nTap "Post request" to tell farmers what '
              'you need.',
          builder: (context) => ListView.builder(
            padding: TabPage.listPadding,
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final request = _requests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.small),
                child: RequestCard(
                  request: request,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: request),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'More actions',
                    onSelected: (action) => action == 'edit'
                        ? _openForm(request)
                        : _delete(request),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
