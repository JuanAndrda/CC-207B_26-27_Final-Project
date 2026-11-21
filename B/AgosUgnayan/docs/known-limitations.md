# Known limitations and planned features

## Known limitations
- **Search** in the Marketplace only searches listings already loaded (Firestore has no full-text search). Crop and town filters do query the database.
- **Chat** loads the newest 50 messages of a conversation; older ones are not shown.
- **Buyer Demand** shows the 50 soonest open requests.
- **Following a listing** saves its title and price at that moment; if the farmer edits the price later, the Following list shows the old text until the buyer opens it.
- **Reference prices** are typed in by the admin from PSA OpenSTAT each month; they are not imported automatically.
- **Admin** can only add prices. Managing users and removing posts is done in the Firebase console.
- The **AI assistant** needs the real Firebase project with AI Logic turned on; it falls back to the manual form in the emulator.

## Removed from the web version on purpose
- Map view of sellers, and every map package and component.
- Language settings (Hiligaynon / Filipino); the app is English for now.
- Settings screen: replaced by the Profile tab.
- Separate "Follow seller" and "Saved listings": replaced by one Following tab with Crop Listings and Farmers.

## Planned features
- Price alerts and notifications when a followed farmer posts a crop.
- Crop photos (Firebase Storage).
- Hiligaynon and Filipino translations.
- Automatic monthly PSA price import.
- Reporting and moderation tools for the admin.
