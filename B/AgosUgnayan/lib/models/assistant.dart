// Data for the buyer AI assistant: what page the buyer is on, what kind of
// question it is, and what the assistant answers. See
// docs/buyer-ai-assistant-design.md.

import 'listing.dart';
import 'order.dart';
import 'price_record.dart';

/// Which buyer page is open (decides the suggested questions).
enum AssistantScreen {
  home,
  market,
  prices,
  priceDetail,
  listing,
  requests,
  orders,
  following,
  messages,
  chat,
}

/// What is on the page right now. Screens fill in what they have; the
/// assistant never has to ask the buyer to retype it.
class AssistantPage {
  const AssistantPage(
    this.screen, {
    this.listing,
    this.crop,
    this.history = const [],
    this.order,
    this.hideButton = false,
  });

  final AssistantScreen screen;
  final Listing? listing; // the listing page's listing
  final String? crop; // the crop of a price page
  final List<PriceRecord> history; // that crop's prices (price page)
  final CropOrder? order; // the newest order in an open chat

  /// True on forms, so the round button never covers their buttons.
  final bool hideButton;

  /// The crop this page is about, if any.
  String? get pageCrop => listing?.crop ?? order?.crop ?? crop;
}

/// The kinds of questions the assistant can answer.
enum AssistantIntent {
  priceCheck,
  trend,
  search,
  offerMath,
  orderStatus,
  howTo,
  outOfScope, // answered by the app itself, never sent to the AI
}

/// A suggested question chip: its words and what kind of question it is.
class SuggestedQuestion {
  const SuggestedQuestion(this.text, this.intent);

  final String text;
  final AssistantIntent intent;
}

/// One line in the "Facts from AgosUgnayan" box, e.g. "Asking price" /
/// "₱54.40/kg".
class FactRow {
  const FactRow(this.label, this.value);

  final String label;
  final String value;
}

/// One message in the assistant chat.
class AssistantMessage {
  const AssistantMessage.fromBuyer(this.text)
    : isBuyer = true,
      isFallback = false,
      facts = const [],
      listings = const [],
      marketCrop = null;

  const AssistantMessage.answer({
    required this.text,
    this.isFallback = false,
    this.facts = const [],
    this.listings = const [],
    this.marketCrop,
  }) : isBuyer = false;

  final bool isBuyer;

  /// The AI's words (or, in a fallback, the app's own words).
  final String text;

  /// True when the AI was not used (busy, offline, limit reached).
  final bool isFallback;

  /// Numbers computed by the app, shown apart from the AI text.
  final List<FactRow> facts;

  /// Real listings to tap (search results), never made up by the AI.
  final List<Listing> listings;

  /// When set, an "Open the Market" link is shown (the crop searched).
  final String? marketCrop;
}
