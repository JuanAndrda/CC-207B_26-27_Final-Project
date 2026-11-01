# AgosUgnayan

A mobile and web app that helps smallholder farmers in Iloilo Province (starting with Leon) sell crops directly to local buyers, and shows both sides a fair reference price before they talk.

CC 207B Final Project (Applications Development and Emerging Technologies), WVSU, section B.

- **Client:** smallholder farmers in Leon, Iloilo
- **Users:** Farmer, Buyer (household or business), Admin (enters monthly reference prices)
- **Not included:** payments, cart, delivery and ratings. The app connects people, and the deal happens in their own chat.

## Tech stack

| Tool | Version |
|---|---|
| Flutter | 3.47.7 (stable) |
| Dart | 3.13.5 |
| Firebase | Auth (email/password), Cloud Firestore, AI Logic (Gemini), App Check |
| Targets | Web and Android |

## Packages

| Package | Why we use it |
|---|---|
| `firebase_core` | Connects the app to our Firebase project; every other Firebase package needs it. |
| `firebase_auth` | Email and password login and registration. |
| `cloud_firestore` | Our online database for users, listings, requests, chats and prices. |
| `firebase_ai` | Calls Gemini for the AI Listing Assistant without putting an API key in the app. |
| `firebase_app_check` | Proves requests come from our real app, so others can't abuse our AI and database. |
| `go_router` | Moves between screens using simple paths like `/marketplace`. |
| `provider` | Shares the logged-in user and services with every screen. |
| `intl` | Formats pesos, dates and months, e.g. "₱45.00" and "Aug 2026". |
| `shared_preferences` | Saves the last loaded reference prices on the phone for offline use. |
| `fl_chart` | Draws the 12-month reference price chart. |

Ask the team before adding any other package.

## Setup (each member, once)

1. Install Flutter stable and check it with `flutter doctor`.
2. Clone the team fork and open this folder (`B/AgosUgnayan`).
3. Get the packages:
   ```
   flutter pub get
   ```
4. Connect your laptop to our Firebase project. Ask the team leader to add your Google account to the Firebase project first.
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,web
   ```
   Pick our AgosUgnayan Firebase project when asked. This creates `lib/firebase_options.dart` and `android/app/google-services.json`. Both are in `.gitignore` because they hold our Firebase keys. **Never commit them.**
5. Run the app:
   ```
   flutter run -d chrome
   ```
   The first screen says **Firebase connected** when step 4 worked. If it says **Firebase not set up yet**, repeat step 4.

No Firebase yet? Copy the placeholder so the code compiles: `cp tool/firebase_options_example.dart lib/firebase_options.dart`.

## How we work

- One feature at a time, each on its own branch: `feature/<short-name>`.
- Commit under your own GitHub account, in small commits that say what and why.
- Before every commit:
  ```
  dart format .
  flutter analyze
  flutter test
  ```
  Also check that the diff has no keys or passwords.
- Every pull request is reviewed and approved by another member before merging.
- Add one line to `docs/ai-usage-log.md` for every AI-assisted change, and your rows to `docs/topic-coverage-matrix.md` after your feature.

GitHub Actions runs format, analyze and test on every push and pull request (`.github/workflows/ci.yml` at the repo root).

## Folders

```
lib/
  main.dart        App start, error catching, Firebase connection
  app_router.dart  All screen paths (go_router)
  screens/         One file per full page
  widgets/         Reusable pieces (AsyncStateView, confirm dialog)
  models/          Data classes with fromJson/toJson
  services/        The only code that talks to Firebase and the AI
  utils/           Theme, strings, validators, logger, SnackBar helpers
assets/fonts/      Inter and Barlow Condensed from the Figma design (Open Font License)
test/              Unit and widget tests
docs/              Checklist, AI Usage Log, Topic Coverage Matrix
tool/              Placeholder Firebase settings used by CI
```

## Design

Screens follow the v3 row of our Figma file: https://www.figma.com/design/6iDTiJCeqccRiDczkkpmsF/AgosUgnayan-Prototype. Colors, sizes and fonts are in `lib/utils/theme.dart`, and all text is in `lib/utils/strings.dart`.
