# Topic Coverage Matrix

Where each course topic appears in our code. Each feature owner checks their rows and can explain them.

| Topic | File | Class / widget | Short description |
|---|---|---|---|
| Value widgets | `lib/widgets/listing_card.dart` | `ListingCard`, `ListingGridCard`, `PriceText` (`Text.rich`, `Icon`) | A listing as a list row or a Market grid card, price in green with "/kg" |
| Value widgets | `lib/widgets/status_badge.dart` | `StatusBadge` | Open / Closed pill with text, not color alone |
| Value widgets | `lib/widgets/brand_app_bar.dart` | `AppLogo` (`Image.asset`) | The AgosUgnayan logo in the top bar and on Login |
| Value widgets | `lib/screens/price_detail_screen.dart` | `PriceDetailScreen` (`LineChart`) | 12-month price chart with fl_chart |
| Layout | `lib/widgets/responsive_body.dart` | `ResponsiveBody` (`Align` + `ConstrainedBox`) | Keeps pages a readable width on laptops; full width on phones |
| Layout | `lib/widgets/tab_page.dart` | `TabPage` (`Column`, `Expanded`) | Page heading on top, list below, for every main tab |
| Layout | `lib/screens/marketplace_screen.dart` | `_buildGrid` (`LayoutBuilder`, `SliverGrid`) | 2 to 4 crop cards per row depending on the screen width |
| Layout | `lib/screens/crop_form_screen.dart` | `CropFormScreen` (`ListView`, `Row`, `Expanded`) | Form fields stacked, quantity and unit side by side |
| Layout | `lib/widgets/async_state_view.dart` | `AsyncStateView`, `_Message` | `Column`, `Padding`, `SizedBox` for loading, error and empty states |
| Interaction | `lib/screens/following_screen.dart` | `FollowingScreen` (`SegmentedButton`) | Switch between followed Crop Listings and Farmers |
| Interaction | `lib/screens/marketplace_screen.dart` | `MarketplaceScreen` (`ChoiceChip`, `DropdownButton`, `TextField`) | Crop and town filters, debounced search |
| Interaction | `lib/widgets/confirm_dialog.dart` | `showConfirmDialog` (`showModalBottomSheet`) | Confirmation sheet before delete, log out and discarding a form |
| Interaction | `lib/screens/register_screen.dart` | `_RoleCard` (`InkWell`) | Tappable Farmer / Buyer cards |
| Interaction | `lib/utils/snackbars.dart` | `showMessage`, `showUndoMessage` | Feedback after every action, with Undo for deletes |
| Navigation | `lib/screens/home_screen.dart` | `HomeScreen` (`NavigationBar`, `NavigationRail`, `AppSidebar`, `IndexedStack`) | Role-based tabs: bottom bar on phones, icon rail on tablets, full sidebar with counts and user card on laptops |
| Navigation | `lib/widgets/home_nav.dart` | `HomeNav` (`InheritedWidget`) | Lets a dashboard's "See all" switch to another tab |
| Layout | `lib/screens/farmer_home_screen.dart`, `buyer_home_screen.dart` | `FarmerHomeScreen`, `BuyerHomeScreen` (`LayoutBuilder`, `StatGrid`, `SectionCard`) | Home dashboards: stats, buyer demand, prices, newest crops; two columns on wide screens |
| Navigation | `lib/screens/my_crops_screen.dart` | `_openForm` (`Navigator.push` with a result) | Opens the form and reloads when it returns `true` |
| Navigation | `lib/screens/profile_screen.dart` | `_logOut` (`pushAndRemoveUntil`) | Clears every screen after log out |
| Forms / validation | `lib/screens/register_screen.dart` | `RegisterScreen` | Name, email, password, confirm password, role, town, privacy consent |
| Forms / validation | `lib/screens/crop_form_screen.dart` | `CropFormScreen` (`PopScope`, `_quantityValidator`, `_priceValidator`) | Website-style listing form: required and optional fields, limits, PSA reference hint, "Discard changes?" on Back and Cancel |
| Forms / validation | `lib/widgets/labeled_field.dart` | `LabeledField`, `RequiredNote` | Label above the field with a red star or an "Optional" tag |
| Forms / validation | `lib/utils/validators.dart` | `Validators` | Reusable validators with friendly messages, unit-tested |
| Async / API | `lib/utils/app_exception.dart` | `runSafely` | One try/catch with timeout around every Firebase call |
| Async / API | `lib/screens/marketplace_screen.dart` | `_loadFirstPage`, `_loadMore` | Pagination: 20 per page with `startAfterDocument` |
| Async / API | `lib/services/psa_service.dart` | `PsaService.fetchFarmgate` (`http` GET + POST, 30 s timeout) | Downloads Iloilo farmgate prices from the PSA OpenSTAT API and turns them into price records |
| Async / API | `lib/services/price_service.dart` | `PriceService.saveMany` (Firestore batch) | Saves the PSA prices; the same crop and month is updated, not duplicated |
| Async / API | `lib/services/crop_photo_service.dart` | `CropPhotoService.loadAll` (`http`, `shared_preferences`) | Sample crop photos from the Wikipedia API, saved for a week, offline fallback |
| Value widgets | `lib/widgets/crop_image.dart` | `CropImage`, `CropHero`, `CropAbout` (`Image.network`, `FutureBuilder`, `Stack`) | Photo over the placeholder, "Sample photo" label, credit and "About" text |
| Async / API | `lib/screens/chat_screen.dart` | `ChatScreen` (`StreamBuilder`) | Live messages from a Firestore stream |
| Async / API | `lib/widgets/async_state_view.dart` | `AsyncStateView` | Shared loading, empty, error (Try again) and data states |
| Persistence | `lib/services/listing_service.dart` | `ListingService` | Firestore create, read, update, delete and restore (Undo) |
| Persistence | `lib/services/price_service.dart` | `PriceService` | Firestore plus an offline copy in `shared_preferences` |
| AI | `lib/services/ai_service.dart` | `AiService.suggestListing` | Gemini via Firebase AI Logic, 20 s timeout, fallback message |
| AI | `lib/models/ai_listing_suggestion.dart` | `AiListingSuggestion.fromJsonText` | Keeps only valid AI values, drops the rest |
| AI | `lib/widgets/ai_assistant_box.dart` | `AiAssistantBox`, `AiGeneratedChip` | Note input, loading state, "AI-generated" label |
| Privacy | `lib/utils/privacy_filter.dart` | `removeContactDetails` | Removes phone numbers and emails before calling the AI |
