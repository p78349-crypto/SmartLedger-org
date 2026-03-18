// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

class _UsageInput extends StatefulWidget {
  final double? initialValue;
  final double max;
  final String unit;
  final ValueChanged<double?> onChanged;

  const _UsageInput({
    required this.max,
    required this.unit,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<_UsageInput> createState() => _UsageInputState();
}

class _UsageInputState extends State<_UsageInput> {
  double? _value;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(
      text: _formatValue(widget.initialValue),
    );
  }

  @override
  void didUpdateWidget(covariant _UsageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
      _controller.value = TextEditingValue(
        text: _formatValue(widget.initialValue),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double? val) {
    if (val == null) return '';
    final isInt = (val % 1).abs() < 0.000001;
    return isInt ? val.toStringAsFixed(0) : val.toStringAsFixed(2);
  }

  void _bump(double delta) {
    final base = _value ?? 0;
    _setValue(base + delta);
  }

  void _setValue(double? next) {
    if (next != null) {
      final max = widget.max > 0 ? widget.max : 0;
      next = next.clamp(0, max).toDouble();
    }
    setState(() {
      _value = next;
      _controller.value = TextEditingValue(text: _formatValue(next));
    });
    widget.onChanged(next);
  }

  void _handleTextChanged(String raw) {
    final parsed = double.tryParse(raw.trim());
    setState(() => _value = parsed);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: iconColor),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: () => _bump(-1),
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              suffixText: widget.unit,
            ),
            onChanged: _handleTextChanged,
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: iconColor),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: () => _bump(1),
        ),
      ],
    );
  }
}
