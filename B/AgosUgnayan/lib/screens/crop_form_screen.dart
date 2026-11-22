// F1 Crop Listings: the Add / Edit crop form. It has validation on every
// field, a reference price hint, a "Discard changes?" warning, and the
// F3 AI Listing Assistant box at the top.

import 'package:flutter/material.dart';

import '../models/ai_listing_suggestion.dart';
import '../models/listing.dart';
import '../models/price_record.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/price_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/snackbars.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/ai_assistant_box.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/date_field.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_body.dart';

/// Form to add a new crop listing, or edit [listing] when it is given.
/// Closes with `true` when something was saved.
class CropFormScreen extends StatefulWidget {
  const CropFormScreen({super.key, this.listing});

  final Listing? listing; // null = add a new crop

  @override
  State<CropFormScreen> createState() => _CropFormScreenState();
}

class _CropFormScreenState extends State<CropFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _crop;
  String? _unit = 'kg';
  DateTime? _harvestDate;
  bool _isSaving = false;
  bool _hasChanges = false; // for the "Discard changes?" warning
  bool _aiUsed = false; // true once the AI filled in the form
  List<PriceRecord> _prices = []; // for the reference price hint

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    if (listing != null) {
      _crop = listing.crop;
      _unit = listing.unit;
      _quantityController.text = formatQuantity(listing.quantity);
      _priceController.text = listing.price.toStringAsFixed(2);
      _descriptionController.text = listing.description;
      _harvestDate = listing.harvestDate;
      _aiUsed = listing.aiAssisted;
    }
    _loadPrices();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Loads reference prices for the hint. If it fails we just show no hint.
  Future<void> _loadPrices() async {
    try {
      final data = await PriceService().fetchRecent();
      if (mounted) setState(() => _prices = data.records);
    } catch (_) {}
  }

  /// Puts the AI's suggestion into the form. Fields the AI left empty keep
  /// what the farmer already typed. Everything stays editable.
  void _applySuggestion(AiListingSuggestion suggestion) {
    setState(() {
      _crop = suggestion.crop ?? _crop;
      _unit = suggestion.unit ?? _unit;
      if (suggestion.quantity != null) {
        _quantityController.text = formatQuantity(suggestion.quantity!);
      }
      if (suggestion.price != null) {
        _priceController.text = suggestion.price!.toStringAsFixed(2);
      }
      if (suggestion.description != null) {
        _descriptionController.text = suggestion.description!;
      }
      _aiUsed = true;
      _hasChanges = true;
    });
    showMessage(
      context,
      'AI filled in the form. Check every field before saving.',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final farmer = AuthService.currentUser!;
    final listing = Listing(
      id: widget.listing?.id ?? '',
      farmerId: farmer.id,
      farmerName: farmer.name,
      crop: _crop!,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unit!,
      price: double.parse(_priceController.text.trim()),
      town: farmer.town,
      harvestDate: _harvestDate,
      description: _descriptionController.text.trim(),
      aiAssisted: _aiUsed,
      createdAt: widget.listing?.createdAt ?? DateTime.now(),
    );
    try {
      await ListingService().save(listing);
      if (!mounted) return;
      showMessage(context, _isEditing ? 'Crop updated.' : 'Crop listed.');
      // Navigator.pop closes the screen even when PopScope says canPop:
      // false. PopScope only stops the back button and back gesture.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showError(context, friendlyMessage(e));
    }
  }

  /// "Reference: ₱45.00/kg (PSA farmgate, Iloilo Province, Aug 2026)"
  String? _priceHint() {
    if (_crop == null) return null;
    final latest = PriceService.latestFor(_crop!, _prices);
    if (latest == null) return null;
    return 'Reference: ${formatPeso(latest.price)}/kg '
        '($kPriceSource, ${formatMonthKey(latest.month)})';
  }

  @override
  Widget build(BuildContext context) {
    // PopScope asks "Discard changes?" before leaving with unsaved edits.
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDiscardChangesDialog(context);
        if (discard && context.mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit crop' : 'Add crop')),
        body: Form(
          key: _formKey,
          // setState so PopScope knows there are unsaved changes now.
          onChanged: () {
            if (!_hasChanges) setState(() => _hasChanges = true);
          },
          child: ResponsiveBody(
            maxWidth: AppSizes.maxFormWidth,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              children: [
                PageHeader(
                  eyebrow: _isEditing ? 'Edit listing' : 'New listing',
                  title: _isEditing ? 'Edit your crop' : 'Sell a crop',
                  lead:
                      'Buyers see this in the Market. Fields marked '
                      '"optional" can be left empty.',
                ),
                const SizedBox(height: AppSizes.sectionGap),
                if (!_isEditing) AiAssistantBox(onSuggestion: _applySuggestion),
                if (_aiUsed) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AiGeneratedChip(),
                  ),
                ],
                const SizedBox(height: AppSizes.sectionGap),
                DropdownField(
                  label: 'Crop',
                  items: kCrops,
                  value: _crop,
                  onChanged: (value) => setState(() => _crop = value),
                ),
                const SizedBox(height: AppSizes.fieldGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.positiveNumber,
                      ),
                    ),
                    const SizedBox(width: AppSizes.small),
                    Expanded(
                      child: DropdownField(
                        label: 'Unit',
                        items: kUnits,
                        value: _unit,
                        onChanged: (value) => setState(() => _unit = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.fieldGap),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Asking price per ${_unit ?? 'unit'} (₱)',
                    helperText: _priceHint(),
                    helperMaxLines: 2,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.price,
                ),
                const SizedBox(height: AppSizes.fieldGap),
                DateField(
                  label: 'Harvest date (optional)',
                  value: _harvestDate,
                  isRequired: false,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  onChanged: (date) => setState(() {
                    _harvestDate = date;
                    _hasChanges = true;
                  }),
                ),
                const SizedBox(height: AppSizes.fieldGap),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. Freshly picked, no pesticide',
                  ),
                  maxLines: 3,
                  maxLength: 300,
                  validator: Validators.maxLength(300),
                ),
                const SizedBox(height: AppSizes.sectionGap),
                LoadingButton(
                  label: _isEditing ? 'Save changes' : 'List this crop',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
