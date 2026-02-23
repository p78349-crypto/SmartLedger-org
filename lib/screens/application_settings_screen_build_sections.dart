part of 'application_settings_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension ApplicationSettingsBuildSections on _ApplicationSettingsScreenState {
  Widget _buildTxInputSection(ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('입력내용 기억'),
            subtitle: const Text(
              '상품명/결제수단/메모 입력내용을 저장해 다음에 불러옵니다.',
            ),
            value: _txRecentEnabled,
            onChanged: _setTxRecentEnabled,
          ),
          SwitchListTile(
            title: const Text('자동 채우기'),
            subtitle: const Text(
              '지출입력 화면에서 결제수단/메모를 최근 값으로 미리 채웁니다.',
            ),
            value: _txRecentAutofill,
            onChanged: _txRecentEnabled ? _setTxRecentAutofill : null,
          ),
          ListTile(
            title: const Text('기억 개수'),
            subtitle: const Text('최근 입력내용을 최대 몇 개까지 저장할지 선택합니다.'),
            enabled: _txRecentEnabled,
            trailing: DropdownButton<int>(
              value: _txRecentMaxCount,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10개')),
                DropdownMenuItem(value: 20, child: Text('20개')),
                DropdownMenuItem(value: 30, child: Text('30개')),
              ],
              onChanged: !_txRecentEnabled
                  ? null
                  : (v) {
                      if (v == null) return;
                      _setTxRecentMaxCount(v);
                    },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(IconCatalog.deleteOutline),
            title: const Text('저장된 입력내용 삭제'),
            subtitle: const Text('상품명/결제수단/메모 입력내용을 초기화합니다.'),
            onTap: _clearTxRecentInputs,
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection(ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('예상 소진 알림'),
            subtitle: const Text('예상 소진 임박 시 로컬 알림을 표시합니다.'),
            value: _stockDepletionNotifyEnabled,
            onChanged: _setStockDepletionNotifyEnabled,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('예상 소진 자동 추가 기준 (식료품)'),
            subtitle: const Text(
              '식료품(유통기한 설정 품목)은 예상 소진 N일 전 자동으로 장바구니에 추가합니다.',
            ),
            trailing: DropdownButton<int>(
              value: _stockAutoAddDaysFood,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1일')),
                DropdownMenuItem(value: 2, child: Text('2일')),
                DropdownMenuItem(value: 3, child: Text('3일')),
                DropdownMenuItem(value: 5, child: Text('5일')),
                DropdownMenuItem(value: 7, child: Text('7일')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _setStockAutoAddDaysFood(v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('예상 소진 자동 추가 기준 (생활용품)'),
            subtitle: const Text(
              '생활용품(유통기한 없는 품목)은 예상 소진 N일 전 자동으로 장바구니에 추가합니다.',
            ),
            trailing: DropdownButton<int>(
              value: _stockAutoAddDaysHousehold,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1일')),
                DropdownMenuItem(value: 2, child: Text('2일')),
                DropdownMenuItem(value: 3, child: Text('3일')),
                DropdownMenuItem(value: 5, child: Text('5일')),
                DropdownMenuItem(value: 7, child: Text('7일')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _setStockAutoAddDaysHousehold(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '유통기한 저장 후 메시지',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '아래 템플릿이 비어있으면 기본 문구를 사용합니다.\n'
              '치환: {item} = 품목명, {date} = 오늘/내일/모레/1월 20일',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foodExpiryFeedbackTemplateController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '{item} 저장 완료. 유통기한: {date}.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _resetFoodExpiryFeedbackTemplate,
                  child: const Text('기본값'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saveFoodExpiryFeedbackTemplate,
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
