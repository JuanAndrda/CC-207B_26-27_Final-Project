// F5 Buyer Requests: the buyer's own requests in two tabs, Open and Closed,
// with search, sorting and page numbers. A buyer can post, edit, close
// (found a farmer), reopen and delete requests. Closing is undoable from
// the message; deleting asks first and can be undone too.

import 'package:flutter/material.dart';

import '../models/buyer_request.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../utils/app_exception.dart';
import '../utils/paging.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/list_page.dart';
import '../widgets/list_tools.dart';
import '../widgets/page_header.dart';
import '../widgets/request_card.dart';
import 'request_detail_screen.dart';
import 'request_form_screen.dart';

enum _Tab { open, closed }

enum _Sort { soonest, newest }

/// The logged-in buyer's crop requests.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _service = RequestService();
  final _scroll = ScrollController();
  List<BuyerRequest> _requests = [];
  bool _isLoading = true;
  String? _error;

  _Tab _tab = _Tab.open;
  String _search = '';
  _Sort _sort = _Sort.soonest;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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

  void _update(VoidCallback change) {
    setState(() {
      change();
      _page = 1;
    });
  }

  Future<void> _openForm([BuyerRequest? request]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RequestFormScreen(request: request)),
    );
    if (saved == true) _load();
  }

  /// Closes or reopens a request. No question first, because the message
  /// has Undo and the Closed tab has Reopen.
  Future<void> _setClosed(BuyerRequest request, bool closed) async {
    try {
      await _service.setClosed(request.id, closed);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      showUndoMessage(
        context,
        closed
            ? '${request.crop} request closed. Farmers no longer see it.'
            : '${request.crop} request is open again.',
        onUndo: () async {
          await _service.setClosed(request.id, !closed);
          _load();
        },
      );
    } catch (e) {
      if (mounted) showError(context, friendlyMessage(e));
    }
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

  List<BuyerRequest> get _visible {
    final list = _requests.where((r) {
      if ((_tab == _Tab.closed) != r.isClosed) return false;
      return matchesSearch(_search, [r.crop, r.town, r.notes]);
    }).toList();
    if (_sort == _Sort.soonest) {
      list.sort((a, b) => a.neededBy.compareTo(b.neededBy));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final slice = pageOf(visible, _page, pageSize: 10);
    final openCount = _requests.where((r) => !r.isClosed).length;
    return ListPage(
      controller: _scroll,
      onRefresh: _load,
      header: PageHeader(
        eyebrow: 'What you need',
        title: 'My requests',
        help: const [
          'Post a request to tell farmers what you need. They can message you.',
          'When you found a farmer, use "Close request" so farmers stop offering.',
          'Requests also close by themselves after their "needed by" date.',
        ],
        lead: 'Farmers see open requests in Buyer Demand and can message you.',
        trailing: FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Post request'),
        ),
      ),
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusTabs<_Tab>(
            value: _tab,
            labels: const {_Tab.open: 'Open', _Tab.closed: 'Closed'},
            counts: {
              _Tab.open: openCount,
              _Tab.closed: _requests.length - openCount,
            },
            onChanged: (tab) => _update(() => _tab = tab),
          ),
          const SizedBox(height: 10),
          ListToolbar(
            search: SearchBox(
              hint: 'Search crop, town, notes…',
              onChanged: (text) => _update(() => _search = text),
            ),
            sort: SortMenu<_Sort>(
              value: _sort,
              options: const {
                _Sort.soonest: 'Needed soonest',
                _Sort.newest: 'Newest',
              },
              onChanged: (sort) => _update(() => _sort = sort),
            ),
          ),
        ],
      ),
      isLoading: _isLoading,
      errorMessage: _error,
      onRetry: _load,
      isEmpty: visible.isEmpty,
      emptyMessage: _search.isNotEmpty
          ? 'No requests match "$_search".'
          : _tab == _Tab.open
          ? 'No open requests.\nTap "Post request" to tell farmers what you '
                'need.'
          : 'No closed requests yet. Requests close when you close them or '
                'their date passes.',
      sliverBuilder: (context, width) => sliverCardGrid(
        contentWidth: width,
        count: slice.items.length,
        minTileWidth: 420,
        maxColumns: 2,
        tileHeight: 112,
        itemBuilder: (context, index) => _card(slice.items[index]),
      ),
      pagination: PaginationBar(slice: slice, onPage: _goToPage),
    );
  }

  Widget _card(BuyerRequest request) {
    return RequestCard(
      request: request,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(request: request),
        ),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'More actions',
        onSelected: (action) => switch (action) {
          'edit' => _openForm(request),
          'close' => _setClosed(request, true),
          'reopen' => _setClosed(request, false),
          _ => _delete(request),
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          if (!request.isClosed)
            const PopupMenuItem(
              value: 'close',
              child: Text('Close request (found a farmer)'),
            ),
          // An expired request can't be reopened; edit its date instead.
          if (request.closedByBuyer && !request.isExpired)
            const PopupMenuItem(value: 'reopen', child: Text('Reopen')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}
