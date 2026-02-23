part of 'application_settings_screen.dart';
// ignore_for_file: invalid_use_of_protected_member, avoid_redundant_argument_values

extension ApplicationSettingsBuild on _ApplicationSettingsScreenState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('애플리케이션 설정')),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: const Text('건강 가드레일'),
                  subtitle: const Text('태그 기반 과소비 경고(주/월 한도)'),
                  onTap: _showHealthGuardrailDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('교체 주기 알림'),
                  subtitle: const Text('소모품/교체형 품목의 예상 교체 시점 알림'),
                  onTap: _showReplacementCycleNotificationDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('연간 리포트(베타)'),
                  subtitle: const Text('최근 365일 차감 데이터를 요약'),
                  onTap: _showAnnualReportDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('활동 가족 수(실질 인원) 추정'),
                  subtitle: const Text('식재료 소진 데이터를 기반으로 추정'),
                  onTap: _showActiveHouseholdEstimatorDialog,
                ),
                const SizedBox(height: 8),
                if (!_hasPermissions) _buildPermissionsBanner(theme, scheme),

                _buildSectionHeader(context, '테마'),
                AbsorbPointer(
                  absorbing: !_hasPermissions,
                  child: Opacity(
                    opacity: _hasPermissions ? 1.0 : 0.5,
                    child: Card(
                      elevation: 0,
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const ThemeSettingsSection(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '대시보드 & 배경'),
                _buildSettingsCard(
                  context,
                  icon: Icons.wallpaper_outlined,
                  title: '배경 설정',
                  subtitle: '월페이퍼, 이미지, 블러 효과를 변경합니다.',
                  enabled: _hasPermissions,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BackgroundSettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '권한 및 시스템'),
                _buildSettingsCard(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: '기기 앱 설정 열기',
                  subtitle: '추가 권한(카메라/위치/마이크)은 기기 설정에서 변경할 수 있습니다.',
                  onTap: () async {
                    await openAppSettings();
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '지출 입력'),
                _buildTxInputSection(theme, scheme),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '식료품/생활용품'),
                _buildStockSection(scheme),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '피드백'),
                _buildFeedbackSection(theme, scheme),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildPermissionsBanner(ThemeData theme, ColorScheme scheme) {
    // More compact permissions banner so buttons and settings remain visible.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: scheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '기본 기능 사용을 위해 저장소 및 알림 권한이 필요합니다. 기타 권한은 필요 시 요청됩니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.security, size: 16),
                label: const Text('허용'),
                    style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () async => await openAppSettings(),
                child: Text(
                  '앱 설정',
                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconCatalog.chevronRight,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
