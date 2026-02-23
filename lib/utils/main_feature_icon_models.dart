import 'package:flutter/material.dart';

/// App feature icon catalog (data-only) with optional voice UI exposure.
@immutable
class MainFeatureIcon {
  final String id;
  final String label;
  final String? labelEn;
  final IconData icon;
  final String? routeName;

  const MainFeatureIcon({
    required this.id,
    required this.label,
    this.labelEn,
    required this.icon,
    this.routeName,
  });

  /// Returns a locale-aware label. Shows bilingual labels for Korean locale
  /// when [bilingualInKorean] is true and an English label exists.
  String labelFor(BuildContext context, {bool bilingualInKorean = true}) {
    final locale = Localizations.localeOf(context);
    final en = labelEn?.trim();
    final hasEn = en != null && en.isNotEmpty;

    if (locale.languageCode == 'en' && hasEn) return en;
    if (locale.languageCode == 'ko' && bilingualInKorean && hasEn) {
      return '$label ($en)';
    }
    return label;
  }
}

@immutable
class MainFeaturePage {
  final int index;
  final List<MainFeatureIcon> items;

  const MainFeaturePage({required this.index, required this.items});
}
