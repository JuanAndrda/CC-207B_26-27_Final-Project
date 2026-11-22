# AI Feature Spec: AI Listing Assistant (F3)

## What it does
On the Add Crop screen, a farmer types a quick note in their own words, for example "50 kilos kamatis, 45 pesos per kilo, bag-o lang ginpupo". Tapping **Fill in for me** sends the note to Gemini, which returns the crop, quantity, unit, price and a short description. The app fills the form, shows an **AI-generated** label, and the farmer checks and edits every field before saving.

## Why AI and not plain rules
Farmers write in English, Hiligaynon, Filipino or a mix, with spelling variations ("kilos", "kls", "kamatis", "tomato"). Fixed rules (regular expressions) would need a rule for every way of writing the same thing and still miss many. A language model understands the note as a whole. We still check its answer against our own lists (see Validation), so it can't add a crop or unit we don't support.

## Service and model
- `firebase_ai` package (Firebase AI Logic) with the Gemini Developer API.
- Model: `gemini-3.5-flash` (one constant in `lib/services/ai_service.dart`, `AiService.modelName`).
- No API key in the app: Firebase AI Logic holds it on Google's side.
- `temperature: 0` and `responseMimeType: application/json` so the answer is steady and machine-readable.

## Prompt
See `_buildPrompt` in `lib/services/ai_service.dart`. It lists our crops (with local names), our units, asks for JSON, and says: "use null for anything the note does not say. Never invent a price."

## Validation (`lib/models/ai_listing_suggestion.dart`)
- crop must be one of our 10 crops; local names like "kamatis" are converted to "Tomato"
- unit must be one of kg, sack, bundle, piece
- quantity and price must be numbers above 0 (and at most 100,000)
- description is cut to 300 characters
- Any field that fails is dropped; the other fields are still used. If nothing is usable, the farmer is told to add details or type manually.

## Failure handling and fallback
| Problem | What the farmer sees |
|---|---|
| No internet, AI not enabled, server error | "The AI assistant is not available right now. You can fill in the form yourself." |
| No answer within 20 seconds | Same message (timeout) |
| Answer is not JSON or has nothing usable | "The AI could not find crop details in your note…" |
The form is always visible and works without the AI, so the farmer is never stuck.

## Sample outputs
| Note | Result |
|---|---|
| `50 kilos kamatis, 45 pesos per kilo` | crop Tomato, quantity 50, unit kg, price 45 |
| `3 sako sibuyas` | crop Onion, quantity 3, unit sack, price empty |
| `durian 10 kg` | crop dropped (not in our list), quantity 10, unit kg |
(Fill in real outputs from your own tests before the presentation.)

## Known failure cases
- Notes with two crops ("tomato and eggplant") give only one crop.
- Prices written as words ("kwarenta y singko") may be missed.
- It does not work in the local emulator (no Firebase AI there).

## Privacy (RA 10173)
Before sending, `removeContactDetails` replaces phone numbers and emails with "[removed]". Only the note is sent: no name, user id or town. Tested in `test/privacy_filter_test.dart`.
