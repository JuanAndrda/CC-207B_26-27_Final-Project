# Known limitations and planned features

## Known limitations
- **Search** in the Marketplace only searches listings already loaded (Firestore has no full-text search). Crop and town filters do query the database.
- **Chat** loads the newest 50 messages of a conversation; older ones are not shown.
- **Buyer Demand** shows the 50 soonest open requests.
- **Following a listing** saves its title and price at that moment; if the farmer edits the price later, the Following list shows the old text until the buyer opens it.
- **Reference prices** come from PSA OpenSTAT when the admin taps "Get latest PSA prices"; they do not update by themselves. PSA publishes a few months late (in Nov 2026 the newest month was June 2026), so the app always shows the month next to each price.
- **Admin** can only add prices. Managing users and removing posts is done in the Firebase console.
- The **AI assistant** needs the real Firebase project with AI Logic turned on; it falls back to the manual form in the emulator.
- **App Check** is set to "Unenforced (monitoring only)" for Firebase AI Logic, because the app does not use App Check yet. Google will turn enforcement on automatically on January 21, 2027; after that the AI only works if we add App Check (reCAPTCHA for web) or unenforce it again.
- The **Gemini model** can be busy or retired by Google. When it does not answer within 20 seconds the farmer fills in the form by hand. To switch models, change `AiService.modelName` (we moved from `gemini-2.5-flash`, retired for new projects, to `gemini-3.5-flash`).
- **Crop photos** are not supported yet; cards show a green placeholder with a leaf icon.

## Removed from the web version on purpose
- Map view of sellers, and every map package and component.
- Language settings (Hiligaynon / Filipino); the app is English for now.
- Settings screen: replaced by the Profile page (the account button at the top right).
- Separate "Follow seller" and "Saved listings": replaced by one Following tab with Crop Listings and Farmers.

## Planned features
- Price alerts and notifications when a followed farmer posts a crop.
- Crop photos (Firebase Storage).
- Hiligaynon and Filipino translations.
- Importing PSA prices automatically every month (now the admin taps a button).
- Reporting and moderation tools for the admin.
