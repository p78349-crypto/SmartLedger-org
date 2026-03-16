import 'package:flutter/material.dart';

/// 도움말 상세 화면 - 재사용 가능한 템플릿
class HelpDetailScreen extends StatelessWidget {
  final String title;
  final List<HelpSection> sections;

  const HelpDetailScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return _buildSection(context, section);
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, HelpSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.icon != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(section.icon, size: 28, color: section.iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ...section.content.map((item) {
          if (item is TextContent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                item.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
            );
          } else if (item is StepContent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSteps(context, item.steps),
            );
          } else if (item is TipContent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTip(context, item.text, item.icon),
            );
          } else if (item is WarningContent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildWarning(context, item.text),
            );
          } else if (item is BulletListContent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildBulletList(context, item.items),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSteps(BuildContext context, List<String> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTip(BuildContext context, String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.lightbulb, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 팁',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(color: Colors.blue[900]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ 주의',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(color: Colors.orange[900]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(BuildContext context, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Data models
class HelpSection {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final List<HelpContent> content;

  const HelpSection({
    required this.title,
    this.icon,
    this.iconColor,
    required this.content,
  });
}

abstract class HelpContent {}

class TextContent implements HelpContent {
  final String text;
  const TextContent(this.text);
}

class StepContent implements HelpContent {
  final List<String> steps;
  const StepContent(this.steps);
}

class TipContent implements HelpContent {
  final String text;
  final IconData? icon;
  const TipContent(this.text, {this.icon});
}

class WarningContent implements HelpContent {
  final String text;
  const WarningContent(this.text);
}

class BulletListContent implements HelpContent {
  final List<String> items;
  const BulletListContent(this.items);
}
