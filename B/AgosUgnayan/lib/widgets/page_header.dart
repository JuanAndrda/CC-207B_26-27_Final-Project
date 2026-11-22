// The heading at the top of every main page, like the website: a small green
// line (eyebrow), a big uppercase title, and an optional grey sentence.

import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// e.g. "LEON, ILOILO" / "MY CROPS" / "What you are selling right now."
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.lead,
    this.trailing,
  });

  /// Big title. It is shown in capitals, so write it normally.
  final String title;

  /// Small green text above the title.
  final String? eyebrow;

  /// Grey sentence under the title.
  final String? lead;

  /// Optional widget on the right, e.g. an "Add crop" button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(), style: AppTextStyles.eyebrow),
          const SizedBox(height: 4),
        ],
        Text(title.toUpperCase(), style: AppTextStyles.pageTitle),
        if (lead != null) ...[
          const SizedBox(height: 6),
          Text(lead!, style: AppTextStyles.lead),
        ],
      ],
    );
    if (trailing == null) return texts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: texts),
        const SizedBox(width: AppSizes.small),
        trailing!,
      ],
    );
  }
}

/// A section heading inside a page, with an optional link on the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: AppTextStyles.sectionTitle)),
        ?action,
      ],
    );
  }
}
