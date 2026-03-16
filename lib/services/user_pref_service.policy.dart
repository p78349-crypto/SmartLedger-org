part of 'user_pref_service.dart';

// --- Reset policies & recipe search history ---

const String _recipeSearchLastQueryKey = 'recipe_search_last_query';
const String _recipeSearchHistoryKey = 'recipe_search_history';

/// Resets all auth/security policies and optionally resets
/// main-page configuration for every known account.
Future<void> _resetAllPolicies({bool clearAccountPages = true}) async {
  final prefs = await SharedPreferences.getInstance();

  final keysToRemove = [
    PrefKeys.rootAuthMode,
    PrefKeys.rootAuthEnabled,
    PrefKeys.rootPinEnabled,
    PrefKeys.userPinEnabled,
    PrefKeys.userPasswordEnabled,
    PrefKeys.userBiometricEnabled,
    PrefKeys.assetAuthEnabled,
    PrefKeys.assetSecurityMode,
    PrefKeys.assetSecurityLevel,
    PrefKeys.assetPinEnabled,
    PrefKeys.assetPasswordEnabled,
    PrefKeys.assetBiometricEnabled,
    PrefKeys.rootPinSaltB64,
    PrefKeys.userPinSaltB64,
    PrefKeys.userPasswordSaltB64,
    PrefKeys.assetPinSaltB64,
    PrefKeys.assetPasswordSaltB64,
    PrefKeys.rootPinHashB64,
    PrefKeys.userPinHashB64,
    PrefKeys.userPasswordHashB64,
    PrefKeys.assetPinHashB64,
    PrefKeys.assetPasswordHashB64,
    PrefKeys.rootPinIterations,
    PrefKeys.userPinIterations,
    PrefKeys.userPasswordIterations,
    PrefKeys.assetPinIterations,
    PrefKeys.assetPasswordIterations,
    PrefKeys.userPinFailedAttempts,
    PrefKeys.userPasswordFailedAttempts,
    PrefKeys.assetPinFailedAttempts,
    PrefKeys.assetPasswordFailedAttempts,
    PrefKeys.userPinLockedUntilMs,
    PrefKeys.userPasswordLockedUntilMs,
    PrefKeys.assetPinLockedUntilMs,
    PrefKeys.assetPasswordLockedUntilMs,
    PrefKeys.rootPinFailedAttempts,
    PrefKeys.rootPinLockedUntilMs,
    PrefKeys.rootAuthSessionUntilMs,
    PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked,
    PrefKeys.biometricAuthEnabled,
    PrefKeys.assetAuthSessionUntilMs,
  ];

  for (final k in keysToRemove) {
    await prefs.remove(k);
  }

  if (clearAccountPages) {
    try {
      final accounts = AccountService().accounts;
      for (final a in accounts) {
        await UserPrefService.resetAccountMainPages(accountName: a.name);
        final trimmed = a.name.trim();
        if (trimmed.isNotEmpty && trimmed != a.name) {
          await UserPrefService.resetAccountMainPages(accountName: trimmed);
        }
      }
    } catch (_) {
      // Best-effort: ignore if AccountService isn't initialized.
    }
  }
}

Future<String> _getLastRecipeSearchQuery() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_recipeSearchLastQueryKey) ?? '';
}

Future<void> _setLastRecipeSearchQuery(String query) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_recipeSearchLastQueryKey, query);
}

Future<List<String>> _getRecipeSearchHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_recipeSearchHistoryKey);
  if (raw == null || raw.isEmpty) return const [];
  try {
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => e.toString()).toList();
  } catch (_) {
    return const [];
  }
}

Future<void> _addToRecipeSearchHistory(String query) async {
  if (query.trim().isEmpty) return;
  final history = await _getRecipeSearchHistory();
  final Set<String> unique = {query.trim(), ...history};
  final List<String> newHistory = unique.take(20).toList();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_recipeSearchHistoryKey, jsonEncode(newHistory));
}

Future<void> _clearRecipeSearchHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_recipeSearchHistoryKey);
}
