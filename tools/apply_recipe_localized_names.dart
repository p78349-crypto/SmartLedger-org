// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Enhanced migration utility for recipe localizedNames conversion
///
/// Features:
/// - Converts legacy 'name' field to 'localizedNames' Map
/// - Automatic backup of input file (optional)
/// - Dry-run mode to preview changes
/// - Direct file modification (in-place) or separate output
///
/// Usage:
///   # Basic migration:
///   dart run tools/apply_recipe_localized_names.dart \
///     --input=recipes.json \
///     --template=lib/migrations/recipe_localized_names_template.json \
///     --output=recipes_migrated.json
///
///   # In-place with backup:
///   dart run tools/apply_recipe_localized_names.dart \
///     --input=recipes.json \
///     --template=template.json \
///     --backup
///
///   # Dry run to preview:
///   dart run tools/apply_recipe_localized_names.dart \
///     --input=recipes.json \
///     --template=template.json \
///     --dry-run

void main(List<String> args) async {
  final argMap = <String, String>{};
  final flags = <String>{};

  for (final a in args) {
    if (a.startsWith('--')) {
      if (a.contains('=')) {
        final split = a.split('=');
        argMap[split[0].replaceAll('--', '')] = split[1];
      } else {
        flags.add(a.replaceAll('--', ''));
      }
    }
  }

  final inputPath = argMap['input'] ?? 'recipes.json';
  final templatePath =
      argMap['template'] ??
      'lib/migrations/recipe_localized_names_template.json';
  final outputPath = argMap['output'] ?? inputPath; // in-place by default
  final dryRun = flags.contains('dry-run') || flags.contains('dryrun');
  final createBackup = flags.contains('backup');

  // Validate input file
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('❌ Input file not found: $inputPath');
    exit(2);
  }

  // Validate template file
  final templateFile = File(templatePath);
  if (!templateFile.existsSync()) {
    stderr.writeln('❌ Template file not found: $templatePath');
    exit(2);
  }

  // Create backup if requested
  if (createBackup && !dryRun) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '$inputPath.backup_$timestamp';
    await inputFile.copy(backupPath);
    print('✅ Backup created: $backupPath');
  }

  // Load JSON files
  print('📖 Reading input: $inputPath');
  final inputContent = await inputFile.readAsString();
  final inputJson = jsonDecode(inputContent) as List<dynamic>;

  print('📖 Reading template: $templatePath');
  final templateContent = await templateFile.readAsString();
  final templateJson = jsonDecode(templateContent) as List<dynamic>;

  // Build template lookup map
  final Map<String, Map<String, String>> templateById = {};
  for (final e in templateJson) {
    final id = e['id']?.toString();
    final localized = e['localizedNames'] as Map<String, dynamic>?;
    if (id != null && localized != null) {
      templateById[id] = localized.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
  }

  print('🔍 Found ${templateById.length} templates');

  // Perform migration
  final migrated = <dynamic>[];
  var convertedCount = 0;
  var skippedCount = 0;

  for (final r in inputJson) {
    final id = r['id']?.toString();
    if (id != null && templateById.containsKey(id)) {
      r['localizedNames'] = templateById[id];
      if (r.containsKey('name')) {
        r.remove('name');
      }
      convertedCount++;
    } else {
      skippedCount++;
    }
    migrated.add(r);
  }

  print('✅ Converted: $convertedCount recipes');
  if (skippedCount > 0) {
    print('⚠️  Skipped: $skippedCount recipes (no template match)');
  }

  // Output results
  if (dryRun) {
    print('\n🔍 DRY RUN MODE - No files modified\n');
    print('Sample of migrated recipes (first 2):');
    final sample = migrated.take(2);
    for (final r in sample) {
      print(const JsonEncoder.withIndent('  ').convert(r));
    }
    print('\n... (${migrated.length - 2} more recipes)');
  } else {
    final outFile = File(outputPath);
    final migratedJson = const JsonEncoder.withIndent('  ').convert(migrated);
    await outFile.writeAsString(migratedJson);
    print('✅ Wrote migrated recipes to: $outputPath');
    print('📊 Total recipes: ${migrated.length}');
  }
}
