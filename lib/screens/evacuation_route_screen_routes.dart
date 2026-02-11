part of 'evacuation_route_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension EvacuationRoutes on _EvacuationRouteScreenState {
  Widget buildRecommendedActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.playlist_add_check, size: 20),
                SizedBox(width: 8),
                Text(
                  '즉시 실행 체크리스트',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activePlan.recommendedActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(action, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCheckpoints() {
    if (_activePlan.checkpoints.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, size: 20),
                SizedBox(width: 8),
                Text(
                  '중간 점검 사항',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activePlan.checkpoints.map(
              (checkpoint) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '✔ $checkpoint',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRoutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route, size: 20),
            const SizedBox(width: 8),
            Text(
              '추천 대피 경로 (${_activePlan.routes.length}개)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._activePlan.routes.map(_buildRouteCard),
      ],
    );
  }

  Widget _buildRouteCard(EvacuationRoute route) {
    final color = _safetyLevelColor(route.safetyLevel);
    final distanceFromUser = _currentLocation == null
        ? null
        : _haversineDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            route.shelterLat,
            route.shelterLon,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _safetyChip(route.safetyLevel),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${route.routeType} • ${route.distanceKm.toStringAsFixed(1)}km • '
                  '약 ${route.estimatedMinutes}분',
                ),
              ],
            ),
            if (distanceFromUser != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.social_distance,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '현재 위치에서 약 ${_formatDistance(distanceFromUser)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '대피소: ${route.shelterName}\n주소: ${route.shelterAddress}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '비상 편의시설: ${route.amenities.join(', ')}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              '이동 단계',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...route.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(step, style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => openRouteOnMap(route),
                icon: const Icon(Icons.map),
                label: const Text('지도에서 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _safetyChip(EvacuationSafetyLevel level) {
    final color = _safetyLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _safetyLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _safetyLevelColor(EvacuationSafetyLevel level) {
    switch (level) {
      case EvacuationSafetyLevel.primary:
        return Colors.green;
      case EvacuationSafetyLevel.alternate:
        return Colors.blue;
      case EvacuationSafetyLevel.lastResort:
        return Colors.orange;
    }
  }

  String _safetyLevelLabel(EvacuationSafetyLevel level) {
    switch (level) {
      case EvacuationSafetyLevel.primary:
        return '1순위 경로';
      case EvacuationSafetyLevel.alternate:
        return '우회 경로';
      case EvacuationSafetyLevel.lastResort:
        return '최후 수단';
    }
  }
}
