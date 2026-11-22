// F1 Crop Listings: the farmer's own listings, with Add, Edit and Delete.
// Delete asks first and offers Undo.

import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../utils/app_exception.dart';
import '../utils/format.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/listing_card.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_page.dart';
import 'crop_form_screen.dart';
import 'listing_detail_screen.dart';

/// The logged-in farmer's crop listings.
class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  final _service = ListingService();
  List<Listing> _listings = [];
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
      final listings = await _service.fetchByFarmer(
        AuthService.currentUser!.id,
      );
      if (!mounted) return;
      setState(() => _listings = listings);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(e));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Opens the form (empty for a new crop) and reloads if something was saved.
  Future<void> _openForm([Listing? listing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CropFormScreen(listing: listing)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Listing listing) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this crop?',
      message:
          '${listing.crop}, ${formatQuantity(listing.quantity)} ${listing.unit} will be '
          'removed from the marketplace.',
      confirmLabel: AppStrings.delete,
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.delete(listing.id);
      if (!mounted) return;
      setState(() => _listings.remove(listing));
      showUndoMessage(
        context,
        '${listing.crop} deleted.',
        onUndo: () async {
          await _service.restore(listing);
          _load();
        },
      );
    } catch (e) {
      if (mounted) showError(context, friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    return TabPage(
      header: PageHeader(
        eyebrow: '${user.town}, Iloilo',
        title: 'My crops',
        lead: 'What you are selling. Buyers see these in the Market.',
        trailing: FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add crop'),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: AsyncStateView(
          isLoading: _isLoading,
          errorMessage: _error,
          onRetry: _load,
          isEmpty: _listings.isEmpty,
          emptyMessage: 'No crops listed yet.\nTap "Add crop" to sell one.',
          builder: (context) => ListView.separated(
            padding: TabPage.listPadding,
            itemCount: _listings.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.small),
            itemBuilder: (context, index) {
              final listing = _listings[index];
              return ListingCard(
                listing: listing,
                showFarmer: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingDetailScreen(listing: listing),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'More actions',
                  onSelected: (action) =>
                      action == 'edit' ? _openForm(listing) : _delete(listing),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
