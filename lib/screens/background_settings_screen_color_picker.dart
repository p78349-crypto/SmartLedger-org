part of background_settings_screen;

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hsv = HSVColor.fromColor(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('색상 선택'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _hsv = _hsv.withSaturation(
                      (details.localPosition.dx / 300).clamp(0, 1),
                    );
                    _hsv = _hsv.withValue(
                      1 - (details.localPosition.dy / 250).clamp(0, 1),
                    );
                    _selectedColor = _hsv.toColor();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSVColor.fromAHSV(1, _hsv.hue, 0, 1).toColor(),
                        HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, _hsv.hue, 1, 0).toColor(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _hsv.hue,
                    max: 360,
                    onChanged: (value) {
                      setState(() {
                        _hsv = _hsv.withHue(value);
                        _selectedColor = _hsv.toColor();
                      });
                    },
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('적용'),
        ),
      ],
    );
  }
}
