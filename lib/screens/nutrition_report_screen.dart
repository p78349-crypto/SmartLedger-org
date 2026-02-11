import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/app_routes.dart';
import '../services/recipe_knowledge_service.dart';
import '../services/user_pref_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/number_formats.dart';
import '../utils/nutrition_food_knowledge.dart';
import '../utils/nutrition_report_utils.dart';

part 'nutrition_report_screen.build.dart';
part 'nutrition_report_screen.food_search_result.dart';
part 'nutrition_report_screen.small_widgets.dart';
part 'nutrition_report_screen.cooking_guide.dart';
part 'nutrition_report_screen.pairing_suggestions.dart';
part 'nutrition_report_screen.extra_recommendations.dart';

class NutritionReportScreen extends StatefulWidget {
  const NutritionReportScreen({
    super.key,
    required this.rawText,
    this.onAddIngredient,
  });

  final String rawText;
  final ValueChanged<String>? onAddIngredient;

  @override
  State<NutritionReportScreen> createState() => _NutritionReportScreenState();
}

class _NutritionReportScreenState extends State<NutritionReportScreen> {
  final TextEditingController _foodSearchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 220),
  );
  String _foodQuery = '';
  List<String> _searchHistory = [];

  late final NutritionReport _report;

  @override
  void initState() {
    super.initState();
    _report = NutritionReportUtils.buildFromRawText(widget.rawText);

    if (_report.items.isNotEmpty) {
      final seed = _report.items.first.name;
      _foodQuery = seed;
      _foodSearchController.text = seed;
      _foodSearchController.selection = TextSelection.fromPosition(
        TextPosition(offset: seed.length),
      );
    } else {
      _loadLastQuery();
    }
    _loadHistory();
  }

  Future<void> _loadLastQuery() async {
    final last = await UserPrefService.getLastRecipeSearchQuery();
    if (last.isNotEmpty && mounted) {
      setState(() {
        _foodQuery = last;
        _foodSearchController.text = last;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await UserPrefService.getRecipeSearchHistory();
    if (mounted) setState(() => _searchHistory = history);
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    await UserPrefService.addToRecipeSearchHistory(query);
    await _loadHistory();
  }

  void _resetSearchForm() {
    setState(() {
      _foodQuery = '';
      _foodSearchController.clear();
    });
    UserPrefService.setLastRecipeSearchQuery('');
  }

  @override
  void dispose() {
    UserPrefService.setLastRecipeSearchQuery(_foodQuery);
    _foodSearchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}

/// Reusable card wrapper with title.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
