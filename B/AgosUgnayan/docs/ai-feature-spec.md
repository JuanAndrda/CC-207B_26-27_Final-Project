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
- crop must be one of our 71 crops (`lib/utils/crop_catalog.dart`); local names like "kamatis" or "sitaw" are converted to "Tomato" or "Sitao"
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
| `50 kilos kamatis, 45 pesos per kilo` (live app, Nov 22) | crop Tomato, quantity 50, unit kg, price 45.00, with the AI-generated label |
| `strawberry 10 kg` | crop dropped (not in our list), quantity 10, unit kg |

## Known failure cases
- Notes with two crops ("tomato and eggplant") give only one crop.
- Prices written as words ("kwarenta y singko") may be missed.
- It does not work in the local emulator (no Firebase AI there).

## Second AI feature: Generate crop description

**What it does.** In Add crop and Edit crop, under the Description field, the farmer can tap **Generate crop description**. Gemini writes 2 to 4 short sentences for buyers: what the crop is, how it looks, how it is used in the Philippines, and one storage tip. The text goes into the Description field with an **AI-generated** label, and the farmer can change or delete it. It is optional; the button only works after a crop is chosen.

**Why AI.** Writing a good description for 71 different crops by hand is slow for farmers, and a fixed template per crop would read the same on every listing. The AI gives a helpful starting point the farmer can edit.

**Input.** Only the crop name and its category (e.g. "Lettuce", "Leafy vegetables"). No name, town, note or other personal data is sent.

**Prompt rules** (`_describePrompt` in `lib/services/ai_service.dart`): plain text only, no title or lists, no prices, no health or medical claims, and nothing about this farmer's farm, harvest or quality (the AI cannot know those). `temperature: 0.4` so it reads naturally.

**Cleaning** (`cleanCropDescription` in `lib/utils/ai_text.dart`, tested in `test/ai_text_test.dart`): removes markdown, bullets and surrounding quotes, joins it into one paragraph, and cuts it to at most 300 characters at the end of a sentence.

**Safety for the farmer's own text.** If the Description already has text, the app asks "Replace your description?" with **Replace** / **Keep mine** before changing anything.

**Failure and fallback.** Loading spinner on the button ("Writing a description…"), 20-second timeout. If it fails: "The AI could not write a description right now. You can write your own, or try again later." The form still works.

**Real sample outputs** (`gemini-3.5-flash`, Nov 23, 2026):

| Crop | Output |
|---|---|
| Lettuce | Lettuce is a leafy vegetable with tender, crisp green or reddish leaves. In the Philippines, it is commonly used fresh for samgyeopsal wraps, salads, and sandwich toppings. For longer freshness, wrap unwashed leaves in a paper towel and store them in the refrigerator. |
| Sitao | Sitao, or yardlong beans, are long, slender green pods used across the Philippines. They are commonly cooked in favorite local dishes like adobong sitao, sinigang, and kare-kare. To keep them crisp, store unwashed beans in a plastic bag inside the refrigerator. |

**Known limits.** The AI writes about the crop in general, not about this farmer's harvest; farmers should add their own details (size, freshness). It does not work in the local emulator.

## Privacy (RA 10173)
Before sending, `removeContactDetails` replaces phone numbers and emails with "[removed]". Only the note is sent: no name, user id or town. Tested in `test/privacy_filter_test.dart`.
