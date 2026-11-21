# AI Usage Log

One line for every change where an AI tool helped. The member who asked writes the line in their own PR.

| Member | Date | Tool | What was asked | What was generated | What the member should change/verify |
|---|---|---|---|---|---|
| Juan Andrada | 2026-11-01 | Claude Code | Set up the Flutter project: theme from Figma v3, strings, validators, logger, shared widgets, routing, README and CI | `lib/utils/*`, `lib/widgets/async_state_view.dart`, `lib/widgets/confirm_dialog.dart`, `lib/app_router.dart`, `lib/main.dart`, `lib/screens/setup_check_screen.dart`, 3 test files, README, CI workflow | Compare theme colors and sizes with Figma; run `flutterfire configure` and confirm the setup screen says "Firebase connected"; read each file so you can explain it |
| Juan Andrada | 2026-11-21 | Claude Code | Convert the AgosUgnayan web app into this Flutter app: 6 core features, Following tab (listings and farmers), Profile instead of Settings, no maps, no language settings | All of `lib/models`, `lib/services`, `lib/screens`, most of `lib/widgets`; `firestore.rules`, `firestore.indexes.json`, `firebase.emulator.json`, `tool/seed_emulator.mjs`; 5 new test files; README and docs updates | Each feature owner reads their files line by line and can explain them; run the app in the emulator and try every flow; create the real Firebase project and test the AI assistant with real notes; fill in real AI sample outputs in `docs/ai-feature-spec.md` |
