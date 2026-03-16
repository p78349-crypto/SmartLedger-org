import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_formatter.dart';
import '../utils/pref_keys.dart';

/// 1억 모으기 프로젝트 화면 (새 디자인)
class OneHundredMillionProjectScreen extends StatefulWidget {
  final String accountName;
  const OneHundredMillionProjectScreen({super.key, required this.accountName});

  @override
  State<OneHundredMillionProjectScreen> createState() =>
      _OneHundredMillionProjectScreenState();
}

class _OneHundredMillionProjectScreenState
    extends State<OneHundredMillionProjectScreen> {
  // 입력 컨트롤러
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _martController = TextEditingController();
  final TextEditingController _shoppingController = TextEditingController();
  final TextEditingController _etcController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController(text: '3');
  final TextEditingController _yearsController = TextEditingController(text: '10');
  final TextEditingController _projectNameController = TextEditingController();
  final FocusNode _cardFocusNode = FocusNode();
  final FocusNode _martFocusNode = FocusNode();
  final FocusNode _shoppingFocusNode = FocusNode();
  final FocusNode _etcFocusNode = FocusNode();
  final FocusNode _yearsFocusNode = FocusNode();
  final FocusNode _interestRateFocusNode = FocusNode();
  final FocusNode _projectNameFocusNode = FocusNode();

  // 프로젝트 설정
  int _selectedYears = 10;
  String _projectName = '';
  final double _targetAmount = 100000000; // 1억 고정

  // 계산된 값
  double _totalAmount = 0;
  double _progressPercentage = 0;
  bool _isSettingsDirty = false;
  bool _isRestoringData = false;
  bool _showSavedState = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 입력 변경 감지
    _cardController.addListener(_calculateTotal);
    _cardController.addListener(_markSettingsDirty);
    _martController.addListener(_calculateTotal);
    _martController.addListener(_markSettingsDirty);
    _shoppingController.addListener(_calculateTotal);
    _shoppingController.addListener(_markSettingsDirty);
    _etcController.addListener(_calculateTotal);
    _etcController.addListener(_markSettingsDirty);
    _interestRateController.addListener(_calculateTotal);
    _interestRateController.addListener(_markSettingsDirty);
    _yearsController.addListener(_markSettingsDirty);
    _projectNameController.addListener(_markSettingsDirty);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _martController.dispose();
    _shoppingController.dispose();
    _etcController.dispose();
    _interestRateController.dispose();
    _yearsController.dispose();
    _projectNameController.dispose();
    _cardFocusNode.dispose();
    _martFocusNode.dispose();
    _shoppingFocusNode.dispose();
    _etcFocusNode.dispose();
    _yearsFocusNode.dispose();
    _interestRateFocusNode.dispose();
    _projectNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _isRestoringData = true;
    final prefs = await SharedPreferences.getInstance();
    final years = prefs.getInt(PrefKeys.project100mYearsV1) ?? 10;
    final savedProjectName = prefs.getString(PrefKeys.project100mNameV1);
    _selectedYears = _normalizeYears(years);
    _yearsController.text = _selectedYears.toString();
    _projectName = (savedProjectName ?? '').trim().isEmpty
        ? _defaultProjectName()
        : savedProjectName!.trim();
    _projectNameController.text = _projectName;
    
    // 저장된 금액 불러오기
    final cardAmount = prefs.getDouble('project_card_amount') ?? 0;
    final martAmount = prefs.getDouble('project_mart_amount') ?? 0;
    final shoppingAmount = prefs.getDouble('project_shopping_amount') ?? 0;
    final etcAmount = prefs.getDouble('project_etc_amount') ?? 0;
    final interestRate = prefs.getDouble('project_interest_rate') ?? 3.0;

    if (cardAmount > 0) _cardController.text = cardAmount.toInt().toString();
    if (martAmount > 0) _martController.text = martAmount.toInt().toString();
    if (shoppingAmount > 0) _shoppingController.text = shoppingAmount.toInt().toString();
    if (etcAmount > 0) _etcController.text = etcAmount.toInt().toString();
    _interestRateController.text = interestRate.toString();

    if (!mounted) {
      _isRestoringData = false;
      return;
    }
    setState(() {
      _isSettingsDirty = false;
    });
    _isRestoringData = false;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.project100mYearsV1, _selectedYears);
    await prefs.setString(PrefKeys.project100mNameV1, _projectName);
    await prefs.setDouble('project_card_amount', _parseAmount(_cardController.text));
    await prefs.setDouble('project_mart_amount', _parseAmount(_martController.text));
    await prefs.setDouble('project_shopping_amount', _parseAmount(_shoppingController.text));
    await prefs.setDouble('project_etc_amount', _parseAmount(_etcController.text));
    await prefs.setDouble('project_interest_rate', _parseAmount(_interestRateController.text));
  }

  int _normalizeYears(int years) {
    if (years < 1) return 1;
    if (years > 100) return 100;
    return years;
  }

  String _defaultProjectName() {
    final accountName = widget.accountName.trim();
    if (accountName.isEmpty) {
      return '1억 모으기 프로젝트';
    }
    return '$accountName 1억 프로젝트';
  }

  Future<void> _saveProjectSettings() async {
    final inputName = _projectNameController.text.trim();
    if (inputName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로젝트 이름을 입력하세요')),
      );
      return;
    }

    final parsedYears = int.tryParse(_yearsController.text.trim());
    final years = _normalizeYears(parsedYears ?? _selectedYears);

    setState(() {
      _projectName = inputName;
      _selectedYears = years;
      _yearsController.text = years.toString();
      _isSettingsDirty = false;
      _showSavedState = true;
    });

    await _saveData();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정이 저장되었습니다')),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showSavedState = false;
      });
    });
  }

  void _markSettingsDirty() {
    if (_isRestoringData) return;
    if (_isSettingsDirty) return;
    if (!mounted) return;
    setState(() {
      _isSettingsDirty = true;
    });
  }

  double _parseAmount(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  void _calculateTotal() {
    final card = _parseAmount(_cardController.text);
    final mart = _parseAmount(_martController.text);
    final shopping = _parseAmount(_shoppingController.text);
    final etc = _parseAmount(_etcController.text);

    final total = card + mart + shopping + etc;
    final percentage = total > 0 ? (total / _targetAmount * 100).toDouble() : 0.0;

    setState(() {
      _totalAmount = total;
      _progressPercentage = percentage;
    });

    _saveData();
  }

  // 복리 계산
  double _calculateFutureValue() {
    if (_totalAmount <= 0) return 0;
    final rate = _parseAmount(_interestRateController.text) / 100;
    if (rate <= 0) return _totalAmount;
    return _totalAmount * math.pow(1 + rate, _selectedYears);
  }

  @override
  Widget build(BuildContext context) {
    final futureValue = _calculateFutureValue();
    final shortage = _targetAmount - futureValue;

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // 하늘색 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            Text(
              _projectName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // 설명
            const Text(
              '포인트모아서 1억만들기,\n포인트 사용하지말고 고이게 해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // 할인금액 입력 버튼들
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    '카드 할인금액',
                    _cardController,
                    focusNode: _cardFocusNode,
                    nextFocusNode: _martFocusNode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    '마트할인금액',
                    _martController,
                    focusNode: _martFocusNode,
                    nextFocusNode: _shoppingFocusNode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    '소핑몰 할인금액',
                    _shoppingController,
                    focusNode: _shoppingFocusNode,
                    nextFocusNode: _etcFocusNode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    '기타',
                    _etcController,
                    focusNode: _etcFocusNode,
                    nextFocusNode: _yearsFocusNode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 기간 입력
            _buildPeriodInput(),
            const SizedBox(height: 12),

            // 연 이율 입력
            _buildInterestRateInput(),
            const SizedBox(height: 12),

            // 합계금액 표시
            Container(
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
                    '카드,마트 소핑몰,기타 금액 합계금액',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(_totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 비율 계산
            Container(
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
                    '1억 모으기 프로젝트 /합계금액 차지하는 비율%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_progressPercentage.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 결과 표시 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🏆 ',
                        style: TextStyle(fontSize: 32),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_selectedYears년 후 미래 전망',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '목표: ${CurrencyFormatter.format(_targetAmount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildResultRow('현재 자산', CurrencyFormatter.format(_totalAmount)),
                  const SizedBox(height: 8),
                  _buildResultRow(
                    '예상 $_selectedYears년 후',
                    futureValue > 0 ? CurrencyFormatter.format(futureValue) : '0원',
                  ),
                  const SizedBox(height: 8),
                  _buildResultRow(
                    '목표까지',
                    shortage > 0
                        ? '부족: ${CurrencyFormatter.format(shortage)}'
                        : '달성!',
                    valueColor: shortage > 0 ? Colors.red : Colors.green,
                  ),
                  const Divider(height: 24, thickness: 1),
                  
                  // 제안
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              '💡 ',
                              style: TextStyle(fontSize: 20),
                            ),
                            Text(
                              '제안',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getSuggestion(shortage),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 하단 안내
            const Text(
              '모든 품은 입력가능/계산 도 되어야함',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            _buildSettingsForm(),
          ],
        ),
      ),
    );
  }

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
            textInputAction:
                nextFocusNode == null ? TextInputAction.done : TextInputAction.next,
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _interestRateController,
            focusNode: _interestRateFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
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

  String _getSuggestion(double shortage) {
    if (shortage <= 0) {
      return '축하합니다! $_selectedYears년 후 목표를 달성할 수 있습니다!';
    }

    final monthlyNeeded = shortage / (_selectedYears * 12);
    final dailyNeeded = shortage / (_selectedYears * 365);

    return '매달 ${CurrencyFormatter.format(monthlyNeeded)}씩 추가로 저축하거나 '
        '투자하면 $_selectedYears년 후 목표 금액에 도달할 수 있습니다.\n\n'
        '하루 ${CurrencyFormatter.format(dailyNeeded)}씩만 절약해도 '
        '목표를 이룰 수 있어요!';
  }

}
