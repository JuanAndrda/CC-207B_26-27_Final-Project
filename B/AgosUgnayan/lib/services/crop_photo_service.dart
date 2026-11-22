// Sample crop photos from Wikipedia, like the website (app/src/lib/
// cropPhotos.ts). Free, no account or key. They show where a crop has no
// photo of its own and are always labeled "Sample photo", so nobody takes
// them for a farmer's real harvest. Each photo keeps its author and license.
//
// Calls: one page summary per crop (photo + description), then one call for
// the photo credits. The result is saved on the phone for a week, so
// Wikipedia is asked about once a week; the saved copy is used offline. If
// Wikipedia can't be reached, crops keep the green leaf placeholder.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Our crop name -> its English Wikipedia article, picked to match the kind
/// sold in Iloilo (same list as the website).
const Map<String, String> kCropArticles = {
  'Tomato': 'Tomato',
  'Cabbage': 'Cabbage',
  'Carrots': 'Carrot',
  'Eggplant': 'Eggplant',
  'Ampalaya': 'Momordica charantia', // bitter melon
  'Pechay': 'Bok choy',
  'Onion': 'Red onion', // PSA: red creole onion
  'Squash': 'Calabaza', // kalabasa
  'Okra': 'Okra',
  'Kangkong': 'Ipomoea aquatica', // water spinach
};

/// One crop's sample photo and where it comes from.
class CropPhoto {
  const CropPhoto({
    required this.image,
    required this.largeImage,
    required this.description,
    required this.extract,
    required this.author,
    required this.license,
  });

  /// About 330 px wide: enough for lists and cards.
  final String image;

  /// A sharper copy for the big photo at the top of a page.
  final String largeImage;

  /// Short description, e.g. "Edible berry".
  final String? description;

  /// The first sentences of the Wikipedia article.
  final String? extract;

  /// Who took the photo and its license, e.g. "Jane Doe" and "CC BY-SA 4.0".
  final String? author;
  final String? license;

  /// e.g. "Sample photo: Jane Doe, CC BY-SA 4.0, via Wikipedia".
  String get creditText {
    final parts = [?author, ?license];
    return parts.isEmpty
        ? 'Sample photo from Wikipedia'
        : 'Sample photo: ${parts.join(', ')}, via Wikipedia';
  }

  factory CropPhoto.fromMap(Map<String, dynamic> map) => CropPhoto(
    image: map['image'] as String,
    largeImage: map['largeImage'] as String? ?? map['image'] as String,
    description: map['description'] as String?,
    extract: map['extract'] as String?,
    author: map['author'] as String?,
    license: map['license'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'image': image,
    'largeImage': largeImage,
    'description': description,
    'extract': extract,
    'author': author,
    'license': license,
  };
}

/// Loads and remembers the sample photos. Use [CropPhotoService.instance] so
/// every screen shares one copy.
class CropPhotoService {
  CropPhotoService({http.Client? client}) : _client = client ?? http.Client();

  /// The one shared copy the app uses.
  static final CropPhotoService instance = CropPhotoService();

  final http.Client _client;

  static const _api = 'https://en.wikipedia.org';
  static const _storeKey = 'crop_photos_v1';
  static const _fresh = Duration(days: 7);
  static const _retryAfter = Duration(minutes: 1);
  static const _timeout = Duration(seconds: 10);

  Map<String, CropPhoto>? _photos; // by article title
  DateTime? _savedAt;
  DateTime? _failedAt;
  Future<Map<String, CropPhoto>>? _pending;

  /// The sample photo for [crop] (our crop name), or null if there is none.
  /// Never throws.
  Future<CropPhoto?> photoFor(String crop) async {
    final article = kCropArticles[crop];
    if (article == null) return null;
    return (await loadAll())[article];
  }

  /// Every crop's photo: the copy saved on the phone while it is less than a
  /// week old, otherwise from Wikipedia (and saved again). When Wikipedia
  /// can't be reached, an older saved copy, or nothing. Never throws.
  Future<Map<String, CropPhoto>> loadAll() async {
    if (_photos == null) await _readSaved();
    final now = DateTime.now();
    if (_photos != null && now.difference(_savedAt!) < _fresh) return _photos!;
    if (_failedAt != null && now.difference(_failedAt!) < _retryAfter) {
      return _photos ?? {};
    }
    // If several cards ask at the same time, they all wait for one download.
    return _pending ??= _download().whenComplete(() => _pending = null);
  }

  Future<Map<String, CropPhoto>> _download() async {
    try {
      final photos = await fetchFromWikipedia();
      _photos = photos;
      _savedAt = DateTime.now();
      await _writeSaved();
      return photos;
    } catch (e) {
      AppLogger.error('Loading crop photos from Wikipedia failed', e);
      _failedAt = DateTime.now();
      return _photos ?? {};
    }
  }

  /// Loads every crop's photo from Wikipedia now (no saved copy). Crops
  /// without a photo are left out.
  Future<Map<String, CropPhoto>> fetchFromWikipedia() async {
    final titles = kCropArticles.values.toSet();
    final summaries = <String, Map<String, dynamic>>{};
    await Future.wait([
      for (final title in titles)
        _getJson(
          '$_api/api/rest_v1/page/summary/'
          '${Uri.encodeComponent(title.replaceAll(' ', '_'))}?redirect=true',
        ).then((summary) {
          if ((summary['thumbnail'] as Map?)?['source'] != null) {
            summaries[title] = summary;
          }
        }, onError: (_) {}), // one missing crop is fine
    ]);
    if (summaries.isEmpty) throw Exception('No crop photos from Wikipedia');

    // The photo's file name, to ask for its author and license.
    final files = <String, String>{};
    summaries.forEach((title, summary) {
      final original = (summary['originalimage'] as Map?)?['source'] as String?;
      final thumb = (summary['thumbnail'] as Map)['source'] as String;
      final file = fileNameOf(original ?? thumb);
      if (file != null) files[title] = file;
    });
    final credits = await _loadCredits(files.values.toSet());

    return {
      for (final entry in summaries.entries)
        entry.key: _toPhoto(entry.value, credits[files[entry.key]]),
    };
  }

  CropPhoto _toPhoto(Map<String, dynamic> summary, _Credit? credit) {
    final thumb = (summary['thumbnail'] as Map)['source'] as String;
    final originalWidth = (summary['originalimage'] as Map?)?['width'] as int?;
    final description = (summary['description'] as String?)?.trim();
    return CropPhoto(
      image: thumb,
      largeImage: widerThumb(thumb, originalWidth, 960),
      description: description == null || description.isEmpty
          ? null
          : description,
      extract: shortExtract(summary['extract'] as String?),
      author: credit?.author,
      license: credit?.license,
    );
  }

  /// Author and license of each photo file, in one call. If it fails the
  /// photos still show, just without names.
  Future<Map<String, _Credit>> _loadCredits(Set<String> files) async {
    if (files.isEmpty) return {};
    try {
      final uri = Uri.parse('$_api/w/api.php').replace(
        queryParameters: {
          'action': 'query',
          'format': 'json',
          'formatversion': '2',
          'origin': '*',
          'prop': 'imageinfo',
          'iiprop': 'extmetadata',
          'iiextmetadatafilter': 'Artist|LicenseShortName',
          'titles': files.map((file) => 'File:$file').join('|'),
        },
      );
      final answer = await _getJson(uri.toString());
      final query = answer['query'] as Map<String, dynamic>? ?? {};
      // Wikipedia may rename the titles we asked for; map them back.
      final renamed = {
        for (final item in query['normalized'] as List? ?? [])
          (item as Map)['to'] as String: item['from'] as String,
      };
      final credits = <String, _Credit>{};
      for (final item in query['pages'] as List? ?? []) {
        final page = item as Map<String, dynamic>;
        final title = page['title'] as String?;
        final info = page['imageinfo'] as List?;
        if (title == null || info == null || info.isEmpty) continue;
        final meta = (info.first as Map)['extmetadata'] as Map? ?? {};
        final asked = (renamed[title] ?? title)
            .replaceFirst('File:', '')
            .replaceAll('_', ' ');
        credits[asked] = _Credit(
          plainText((meta['Artist'] as Map?)?['value'] as String?),
          plainText(
            (meta['LicenseShortName'] as Map?)?['value'] as String?,
            max: 40,
          ),
        );
      }
      return credits;
    } catch (e) {
      AppLogger.error('Loading photo credits failed', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await _client
        .get(Uri.parse(url), headers: {'Accept': 'application/json'})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Wikipedia answered ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> _readSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeKey);
      if (raw == null) return;
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      _savedAt = DateTime.parse(saved['savedAt'] as String);
      _photos = {
        for (final entry in (saved['photos'] as Map<String, dynamic>).entries)
          entry.key: CropPhoto.fromMap(entry.value as Map<String, dynamic>),
      };
    } catch (e) {
      AppLogger.error('Reading saved crop photos failed', e); // not fatal
    }
  }

  Future<void> _writeSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storeKey,
        jsonEncode({
          'savedAt': _savedAt!.toIso8601String(),
          'photos': {
            for (final entry in _photos!.entries)
              entry.key: entry.value.toMap(),
          },
        }),
      );
    } catch (e) {
      AppLogger.error('Saving crop photos failed', e); // loads again next time
    }
  }
}

/// A photo's author and license.
class _Credit {
  const _Credit(this.author, this.license);

  final String? author;
  final String? license;
}

/// Wikimedia thumbnail links contain `/330px-FILE`; this asks for a wider
/// copy (e.g. 960 px) when the original photo is that wide.
String widerThumb(String thumb, int? originalWidth, int width) {
  if (originalWidth == null || originalWidth <= width) return thumb;
  return thumb.replaceFirstMapped(RegExp(r'/(\d+)px-([^/?#]+)'), (match) {
    final current = int.parse(match[1]!);
    return current < width ? '/${width}px-${match[2]}' : match[0]!;
  });
}

/// "Tomato je.jpg" from a Wikimedia image link (thumbnail or original).
String? fileNameOf(String url) {
  final match = RegExp(
    r'/wikipedia/[^/]+/(?:thumb/)?[0-9a-f]/[0-9a-f]{2}/([^/?#]+)',
  ).firstMatch(url);
  if (match == null) return null;
  try {
    return Uri.decodeComponent(match[1]!).replaceAll('_', ' ');
  } catch (_) {
    return null;
  }
}

/// Author fields come as HTML (often a link); keep only the short plain text.
String? plainText(String? html, {int max = 80}) {
  if (html == null) return null;
  final text = html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) return null;
  return text.length > max
      ? '${text.substring(0, max - 1).trimRight()}…'
      : text;
}

/// At most [max] characters, cut at the end of a sentence when there is one.
String? shortExtract(String? text, {int max = 320}) {
  final s = text?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s == null || s.isEmpty) return null;
  if (s.length <= max) return s;
  final cut = s.substring(0, max);
  final end = cut.lastIndexOf('. ');
  if (end > 80) return cut.substring(0, end + 1);
  return '${cut.substring(0, cut.lastIndexOf(' ')).trimRight()}…';
}
