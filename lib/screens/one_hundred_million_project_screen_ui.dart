part of 'one_hundred_million_project_screen.dart';

extension OneHundredMillionProjectUI on _OneHundredMillionProjectScreenState {
  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            textInputAction: nextFocusNode == null
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: (_) {
              _calculateTotal();
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: '0',
              suffixText: '원',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기간 입력 (년)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yearsController,
            focusNode: _yearsFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '예: 7',
              suffixText: '년',
            ),
            onChanged: (value) {
              final parsedYears = int.tryParse(value);
              if (parsedYears == null || parsedYears < 1) return;
              final years = _normalizeYears(parsedYears);
              if (_selectedYears == years) return;
              setState(() {
                _selectedYears = years;
              });
              _saveData();
            },
            onSubmitted: (value) {
              final parsedYears = int.tryParse(value.trim());
              final years = _normalizeYears(parsedYears ?? _selectedYears);
              setState(() {
                _selectedYears = years;
                _yearsController.text = years.toString();
              });
              _saveData();
              FocusScope.of(context).requestFocus(_interestRateFocusNode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '설정',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectNameController,
            focusNode: _projectNameFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveProjectSettings(),
            decoration: const InputDecoration(
              labelText: '이름변경',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveProjectSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSettingsDirty ? Colors.blue : Colors.white,
              foregroundColor: _isSettingsDirty ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(width: 2),
              ),
            ),
            child: _showSavedState
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 6),
                      Text('저장됨'),
                    ],
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestRateInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '연 이율 입력 기본값 3%',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _interestRateController,
            focusNode: _interestRateFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              _calculateTotal();
              FocusScope.of(context).requestFocus(_projectNameFocusNode);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '3.0',
              suffixText: '%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
