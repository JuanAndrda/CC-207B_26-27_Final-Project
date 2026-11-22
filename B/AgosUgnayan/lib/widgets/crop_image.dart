// A crop's picture box, like the website's CropImage. It starts as the green
// placeholder with a leaf; when the crop's sample photo from Wikipedia loads,
// the photo covers it. Cards and big photos say "Sample photo" so nobody
// takes it for the farmer's own harvest. Offline or on error, the
// placeholder simply stays.

import 'package:flutter/material.dart';

import '../services/crop_photo_service.dart';
import '../utils/theme.dart';

/// How big the picture is shown.
enum CropImageSize {
  /// Small square in a list row (no label, it would not fit).
  thumb,

  /// Marketplace card.
  card,

  /// The big photo at the top of a page, with the photo credit under it.
  hero,
}

/// The picture for [crop]. The box's size comes from its parent.
class CropImage extends StatelessWidget {
  const CropImage({super.key, required this.crop, required this.size});

  final String crop;
  final CropImageSize size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CropPhoto?>(
      future: CropPhotoService.instance.photoFor(crop),
      builder: (context, snapshot) {
        final photo = snapshot.data;
        final source = photo == null
            ? null
            : size == CropImageSize.hero
            ? photo.largeImage
            : photo.image;
        return Stack(
          fit: StackFit.expand,
          children: [
            // The placeholder is always underneath.
            Container(
              color: AppColors.primaryLight,
              child: Icon(
                Icons.eco_outlined,
                color: AppColors.link,
                size: size == CropImageSize.thumb ? 24 : 40,
              ),
            ),
            if (source != null)
              Image.network(
                source,
                fit: BoxFit.cover,
                // Decorative: the crop name is always written next to it.
                excludeFromSemantics: true,
                // On error show nothing, so the placeholder stays visible.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                frameBuilder: (context, child, frame, _) => AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              ),
            if (source != null && size != CropImageSize.thumb)
              const Positioned(left: 8, bottom: 8, child: _SampleTag()),
          ],
        );
      },
    );
  }
}

/// The dark "Sample photo" label in the corner of a photo.
class _SampleTag extends StatelessWidget {
  const _SampleTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Sample photo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A big rounded crop photo with the photo credit under it, for the top of
/// Listing details and Price details.
class CropHero extends StatelessWidget {
  const CropHero({super.key, required this.crop, this.note});

  final String crop;

  /// Optional line above the credit, e.g. that this is not the farmer's photo.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CropImage(crop: crop, size: CropImageSize.hero),
          ),
        ),
        FutureBuilder<CropPhoto?>(
          future: CropPhotoService.instance.photoFor(crop),
          builder: (context, snapshot) {
            final photo = snapshot.data;
            if (photo == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [?note, photo.creditText].join(' '),
                style: AppTextStyles.meta,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "About tomato": the first sentences of the crop's Wikipedia article.
/// Hidden until it loads (and when there is none).
class CropAbout extends StatelessWidget {
  const CropAbout({super.key, required this.crop});

  final String crop;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CropPhoto?>(
      future: CropPhotoService.instance.photoFor(crop),
      builder: (context, snapshot) {
        final extract = snapshot.data?.extract;
        if (extract == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About ${crop.toLowerCase()}',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                Text(extract, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                const Text('Source: Wikipedia', style: AppTextStyles.meta),
              ],
            ),
          ),
        );
      },
    );
  }
}
