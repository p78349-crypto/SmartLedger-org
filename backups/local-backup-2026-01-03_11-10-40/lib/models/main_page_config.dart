import 'package:flutter/foundation.dart';

/// Stable main-page identity/config used to decouple persistence from page
/// index.
///
/// - `pageId`: stable identifier used for storage keys (e.g. icon slots).
/// - `moduleKey`: which feature-module this page represents
///   (affects icon catalog).
/// - `pageType`: UI type for the page (e.g. 'icons').
/// - `name`: display label (banner/page name).
@immutable
class MainPageConfig {
  final String pageId;
  final String moduleKey;
  final String pageType;
  final String name;

  const MainPageConfig({
    required this.pageId,
    required this.moduleKey,
    required this.pageType,
    required this.name,
  });

  Map<String, Object?> toJson() => {
    'pageId': pageId,
    'moduleKey': moduleKey,
    'pageType': pageType,
    'name': name,
  };

  static MainPageConfig? tryFromJson(Object? value) {
    if (value is! Map) return null;

    final pageId = value['pageId'];
    final moduleKey = value['moduleKey'];
    final pageType = value['pageType'];
    final name = value['name'];

    if (pageId is! String || pageId.isEmpty) return null;
    if (moduleKey is! String || moduleKey.isEmpty) return null;
    if (pageType is! String || pageType.isEmpty) return null;
    if (name is! String) return null;

    return MainPageConfig(
      pageId: pageId,
      moduleKey: moduleKey,
      pageType: pageType,
      name: name,
    );
  }

  MainPageConfig copyWith({
    String? pageId,
    String? moduleKey,
    String? pageType,
    String? name,
  }) {
    return MainPageConfig(
      pageId: pageId ?? this.pageId,
      moduleKey: moduleKey ?? this.moduleKey,
      pageType: pageType ?? this.pageType,
      name: name ?? this.name,
    );
  }
}
