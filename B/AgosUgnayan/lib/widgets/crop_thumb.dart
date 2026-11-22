// The light green square with a leaf that stands in for a crop photo, like
// the website's photo placeholder. Used in crop lists and cards.

import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// A rounded light green box with a plant icon in the middle.
class CropThumb extends StatelessWidget {
  const CropThumb({super.key, this.size = 48, this.icon = Icons.eco_outlined});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.link, size: size * 0.5),
    );
  }
}
