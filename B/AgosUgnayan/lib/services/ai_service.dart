// The AI Listing Assistant. A farmer types a quick note like
// "50 kilos kamatis, 45 per kilo, harvest sa Biyernes" and Gemini turns it
// into form values. We call Gemini through Firebase AI Logic, so there is no
// API key in the app.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/ai_listing_suggestion.dart';
import '../utils/app_exception.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import '../utils/privacy_filter.dart';

/// Asks Gemini to read a farmer's note and suggest listing details.
class AiService {
  /// The Gemini model to use. If Google retires it, change only this line.
  static const String modelName = 'gemini-3.5-flash';

  /// How long we wait before giving up and letting the farmer type manually.
  static const Duration timeout = Duration(seconds: 20);

  /// Returns the suggestion, or throws [AppException] with a friendly message
  /// so the screen can show the manual form (our fallback).
  Future<AiListingSuggestion> suggestListing(String note) async {
    // Privacy: send only the crop details, never phone numbers or emails.
    final safeNote = removeContactDetails(note);

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: modelName,
        // Ask for JSON so we can read the answer reliably.
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0, // same note -> same answer
        ),
      );
      final response = await model
          .generateContent([Content.text(_buildPrompt(safeNote))])
          .timeout(timeout);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const AppException(_fallbackMessage);
      }
      final suggestion = AiListingSuggestion.fromJsonText(text);
      if (suggestion.isEmpty) {
        throw const AppException(
          'The AI could not find crop details in your note. '
          'Try adding the crop and amount, or fill in the form yourself.',
        );
      }
      return suggestion;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(_fallbackMessage);
    } catch (e, stack) {
      // Bad JSON, no internet, AI not enabled in Firebase, and so on.
      AppLogger.error('AI suggestion failed', e, stack);
      throw const AppException(_fallbackMessage);
    }
  }

  static const _fallbackMessage =
      'The AI assistant is not available right now. '
      'You can fill in the form yourself.';

  /// The instructions we give Gemini. The rules stop it from guessing:
  /// anything not in the note must be null.
  String _buildPrompt(String note) {
    final localNames = kLocalCropNames.entries
        .map((e) => '${e.key} = ${e.value}')
        .join(', ');
    return '''
You help farmers in Iloilo, Philippines list crops for sale.
Read the farmer's note (English, Hiligaynon or Filipino) and return JSON with:
- "crop": one of ${kCrops.join(', ')}. Local names: $localNames.
- "quantity": a number.
- "unit": one of ${kUnits.join(', ')} ("kilo" or "kilos" means kg, "sako" means sack).
- "price": the asking price per unit in pesos, a number.
- "description": one short English sentence for buyers about quality or harvest.
Rules: use null for anything the note does not say. Never invent a price.
Farmer's note: """$note"""
''';
  }
}
