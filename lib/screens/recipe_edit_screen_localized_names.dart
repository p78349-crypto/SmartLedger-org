import 'package:flutter/material.dart';

/// Widget for inputting recipe names in multiple locales
class RecipeLocalizedNamesInput extends StatelessWidget {
  const RecipeLocalizedNamesInput({
    super.key,
    required this.localeControllers,
    required this.supportedLocales,
  });

  final Map<String, TextEditingController> localeControllers;
  final List<String> supportedLocales;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '레시피 이름 *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Create input for each supported locale
        ...localeControllers.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: e.value,
              decoration: InputDecoration(
                labelText: '언어: ${e.key}',
                border: const OutlineInputBorder(),
              ),
            ),
          );
        }),
        Builder(builder: (ctx) {
          return TextButton(
            onPressed: () {
              // validation: at least one non-empty name
              final has = localeControllers.values
                  .any((c) => c.text.trim().isNotEmpty);
              if (!has) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '레시피 이름을 하나 이상 입력해주세요',
                    ),
                  ),
                );
              }
            },
            child: const Text('이름 입력 확인'),
          );
        }),
      ],
    );
  }
}
