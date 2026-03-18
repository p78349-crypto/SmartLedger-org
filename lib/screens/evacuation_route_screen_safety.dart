part of 'evacuation_route_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension EvacuationSafetyHealthCards on _EvacuationRouteScreenState {
  Widget buildSafetyCard() {
    final color = _adviceColor(_activePlan.adviceLevel);

    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: color),
                const SizedBox(width: 8),
                Text(
                  _adviceLabel(_activePlan.adviceLevel),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _activePlan.safetyMessage,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            () {
              final locationStr = _activePlan.location;
              final cond = _activePlan.condition;
              final weatherStr = weatherConditionNames[cond] ?? '극한 날씨';
              final details =
                  '대상 지역: $locationStr\n'
                  '예상 날씨: $weatherStr\n'
                  '가족 인원: ${_activePlan.familySize}명\n'
                  '생성 시각: ${_activePlan.generatedAt.toLocal()}';
              return Text(
                details,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              );
            }(),
            if (_isUserInSafeArea) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '현재 위치는 권장 대피소 반경 안쪽입니다. '
                        '즉시 대피 대신 물자/연락망 점검만 진행하세요.',
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _adviceColor(EvacuationAdviceLevel level) {
    switch (level) {
      case EvacuationAdviceLevel.evacuate:
        return Colors.red;
      case EvacuationAdviceLevel.prepare:
        return Colors.orange;
      case EvacuationAdviceLevel.monitor:
        return Colors.blue;
    }
  }

  String _adviceLabel(EvacuationAdviceLevel level) {
    switch (level) {
      case EvacuationAdviceLevel.evacuate:
        return '즉시 대피 권고';
      case EvacuationAdviceLevel.prepare:
        return '대피 준비 단계';
      case EvacuationAdviceLevel.monitor:
        return '상황 모니터링';
    }
  }

  Widget buildWorkflowHealthCard() {
    final snapshot = _healthSnapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final entries = <MapEntry<String, bool>>[
      MapEntry('데이터 연결', snapshot.hasConnectivity),
      MapEntry('위치 서비스', snapshot.locationServiceEnabled),
      MapEntry('GPS 권한', snapshot.locationPermissionGranted),
    ];
    final issues = entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
    final cardColor = snapshot.isOperational ? Colors.green : Colors.red;

    return Card(
      color: cardColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: cardColor),
                const SizedBox(width: 8),
                const Text(
                  '워크플로우 헬스 체크',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _runHealthCheck,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('헬스체크 재실행'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map((entry) => _statusChip(entry.key, entry.value))
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.isOperational
                  ? '네트워크 · GPS 체인이 정상입니다. '
                        '지도/경로 데이터가 실시간으로 유지됩니다.'
                  : '문제 감지: ${issues.join(', ')}. '
                        '복구 즉시 위치/지도 레이어가 재계산됩니다.',
              style: TextStyle(
                color: snapshot.isOperational ? Colors.green : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '마지막 점검: ${snapshot.checkedAt.toLocal()}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, bool ok) {
    final color = ok ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.error, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
