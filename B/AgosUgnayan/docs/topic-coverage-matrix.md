# Topic Coverage Matrix

Where each course topic appears in our code. Each feature owner adds their rows in their own PR.

| Topic | File | Class / widget | Short description |
|---|---|---|---|
| Layout | `lib/main.dart` | `AgosUgnayanApp` (`Center` + `ConstrainedBox`) | Keeps the phone layout centered on wide web screens |
| Layout | `lib/widgets/async_state_view.dart` | `AsyncStateView`, `_Message` | `Column`, `Padding`, `SizedBox` for loading, error and empty states |
| Navigation | `lib/app_router.dart` | `AppRoutes`, `buildRouter` | go_router setup with one path constant per screen |
| Forms / validation | `lib/utils/validators.dart` | `Validators` | Reusable validators with friendly messages, unit-tested |
| Async / API | `lib/main.dart` | `connectFirebase` | Connects to Firebase with try/catch and a safe fallback |
| Async / API | `lib/widgets/async_state_view.dart` | `AsyncStateView` | Shared loading, empty, error (Try again) and data states |
| Interaction | `lib/widgets/confirm_dialog.dart` | `showConfirmDialog` | Confirmation before destructive actions |
| Interaction | `lib/utils/snackbars.dart` | `showMessage`, `showUndoMessage` | Feedback after every action, with Undo for deletes |
| Persistence | (F1, F6) | | Added with Firestore and the price cache |
| AI | (F3) | | Added with the AI Listing Assistant |
