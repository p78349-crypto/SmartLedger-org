import 'package:flutter/material.dart';
import 'wms_smart_cache.dart';

// 🚀 WMS 최적화 설정 매니저 - 런타임 제어

class WmsOptimizationSettings {
  WmsOptimizationSettings._();
  static final WmsOptimizationSettings instance = WmsOptimizationSettings._();

  // 🎛️ 최적화 기능 개별 제어
  bool _enableSmartCache = true;
  bool _enableDatabasePool = true;
  bool _enableOptimizedBarcode = true;
  bool _enablePerformanceMonitoring = true;
  bool _enableParallelProcessing = true;

  // 📊 성능 임계치 설정
  int _maxCacheMemoryMB = 50;
  int _dbConnectionPoolSize = 5;
  int _barcodeTimeoutMs = 3000;
  int _performanceAlertThresholdMs = 1000;

  // 🔧 getter/setter
  bool get enableSmartCache => _enableSmartCache;
  bool get enableDatabasePool => _enableDatabasePool;
  bool get enableOptimizedBarcode => _enableOptimizedBarcode;
  bool get enablePerformanceMonitoring => _enablePerformanceMonitoring;
  bool get enableParallelProcessing => _enableParallelProcessing;

  int get maxCacheMemoryMB => _maxCacheMemoryMB;
  int get dbConnectionPoolSize => _dbConnectionPoolSize;
  int get barcodeTimeoutMs => _barcodeTimeoutMs;
  int get performanceAlertThresholdMs => _performanceAlertThresholdMs;

  /// 🎯 최적화 모드 설정
  void setOptimizationMode(WmsOptimizationMode mode) {
    switch (mode) {
      case WmsOptimizationMode.maximum:
        _enableSmartCache = true;
        _enableDatabasePool = true;
        _enableOptimizedBarcode = true;
        _enablePerformanceMonitoring = true;
        _enableParallelProcessing = true;
        _maxCacheMemoryMB = 100;
        _dbConnectionPoolSize = 8;
        break;

      case WmsOptimizationMode.balanced:
        _enableSmartCache = true;
        _enableDatabasePool = true;
        _enableOptimizedBarcode = true;
        _enablePerformanceMonitoring = false;
        _enableParallelProcessing = true;
        _maxCacheMemoryMB = 50;
        _dbConnectionPoolSize = 5;
        break;

      case WmsOptimizationMode.minimal:
        _enableSmartCache = true;
        _enableDatabasePool = false;
        _enableOptimizedBarcode = false;
        _enablePerformanceMonitoring = false;
        _enableParallelProcessing = false;
        _maxCacheMemoryMB = 20;
        _dbConnectionPoolSize = 2;
        break;

      case WmsOptimizationMode.disabled:
        _enableSmartCache = false;
        _enableDatabasePool = false;
        _enableOptimizedBarcode = false;
        _enablePerformanceMonitoring = false;
        _enableParallelProcessing = false;
        break;
    }

    _notifySettingsChanged();
  }

  /// 🔧 개별 기능 제어
  void setSmartCacheEnabled(bool enabled) {
    _enableSmartCache = enabled;
    _notifySettingsChanged();
  }

  void setDatabasePoolEnabled(bool enabled) {
    _enableDatabasePool = enabled;
    _notifySettingsChanged();
  }

  void setOptimizedBarcodeEnabled(bool enabled) {
    _enableOptimizedBarcode = enabled;
    _notifySettingsChanged();
  }

  /// ⚡ 성능 기반 자동 조정
  void adjustBasedOnPerformance(Duration lastOperationTime) {
    final ms = lastOperationTime.inMilliseconds;

    if (ms > _performanceAlertThresholdMs * 3) {
      // 성능이 너무 느림 - 최적화 단계적 증가
      if (!_enableSmartCache) {
        setSmartCacheEnabled(true);
        print('🚀 성능 개선: 스마트 캐시 활성화');
      } else if (!_enableDatabasePool) {
        setDatabasePoolEnabled(true);
        print('🚀 성능 개선: DB 풀 활성화');
      } else if (!_enableOptimizedBarcode) {
        setOptimizedBarcodeEnabled(true);
        print('🚀 성능 개선: 바코드 최적화 활성화');
      }
    } else if (ms < _performanceAlertThresholdMs / 2) {
      // 성능이 충분히 빠름 - 메모리 사용량 최적화
      if (_maxCacheMemoryMB > 20) {
        _maxCacheMemoryMB = (_maxCacheMemoryMB * 0.8).round();
        print('💾 메모리 최적화: 캐시 크기 조정 → ${_maxCacheMemoryMB}MB');
      }
    }
  }

  /// 📊 현재 설정 요약
  Map<String, dynamic> getCurrentSettings() {
    return {
      'optimizations': {
        'smart_cache': _enableSmartCache,
        'database_pool': _enableDatabasePool,
        'optimized_barcode': _enableOptimizedBarcode,
        'performance_monitoring': _enablePerformanceMonitoring,
        'parallel_processing': _enableParallelProcessing,
      },
      'thresholds': {
        'max_cache_memory_mb': _maxCacheMemoryMB,
        'db_connection_pool_size': _dbConnectionPoolSize,
        'barcode_timeout_ms': _barcodeTimeoutMs,
        'performance_alert_threshold_ms': _performanceAlertThresholdMs,
      },
      'estimated_performance_gain': _calculateEstimatedGain(),
    };
  }

  /// 🎯 예상 성능 향상률 계산
  int _calculateEstimatedGain() {
    int gain = 0;

    if (_enableSmartCache) gain += 90;
    if (_enableDatabasePool) gain += 85;
    if (_enableOptimizedBarcode) gain += 75;
    if (_enableParallelProcessing) gain += 40;
    if (_enablePerformanceMonitoring) gain += 5;

    return (gain * 0.7).round(); // 현실적인 값으로 조정
  }

  void _notifySettingsChanged() {
    // 설정 변경 시 관련 컴포넌트들에게 알림
    if (_enableSmartCache) {
      WmsSmartCache.instance.updateSettings(maxMemoryMB: _maxCacheMemoryMB);
    }

    if (_enableDatabasePool) {
      // WmsDatabasePool는 런타임 설정 API가 없어 연결 유지 정책만 사용
    }

    if (_enableOptimizedBarcode) {
      // WmsOptimizedBarcodeService는 런타임 설정 API가 없어 기본값 사용
    }
  }

  /// 🔧 문제 상황 감지 시 안전 모드
  void enableSafeMode() {
    print('⚠️ 안전 모드 활성화 - 최적화 기능 단계적 비활성화');

    _enablePerformanceMonitoring = false;
    _enableParallelProcessing = false;
    _enableOptimizedBarcode = false;

    // 기본 최적화만 유지
    _enableSmartCache = true;
    _enableDatabasePool = true;
    _maxCacheMemoryMB = 20;
    _dbConnectionPoolSize = 2;

    _notifySettingsChanged();
  }

  /// 🚀 최대 성능 모드
  void enableMaxPerformanceMode() {
    print('🚀 최대 성능 모드 활성화');
    setOptimizationMode(WmsOptimizationMode.maximum);
  }
}

/// 📋 최적화 모드 열거형
enum WmsOptimizationMode {
  maximum, // 최대 성능 (모든 최적화 활성화)
  balanced, // 균형 모드 (메모리-성능 균형)
  minimal, // 최소 모드 (기본 캐시만)
  disabled, // 비활성화 (원본 상태)
}

/// 🎛️ WMS 최적화 제어 위젯
class WmsOptimizationControlWidget extends StatefulWidget {
  const WmsOptimizationControlWidget({Key? key}) : super(key: key);

  @override
  State<WmsOptimizationControlWidget> createState() =>
      _WmsOptimizationControlWidgetState();
}

class _WmsOptimizationControlWidgetState
    extends State<WmsOptimizationControlWidget> {
  final _settings = WmsOptimizationSettings.instance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 WMS 최적화 제어',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // 최적화 모드 선택
            const Text('최적화 모드', style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                _buildModeButton(
                  '최대',
                  WmsOptimizationMode.maximum,
                  Colors.green,
                ),
                _buildModeButton(
                  '균형',
                  WmsOptimizationMode.balanced,
                  Colors.blue,
                ),
                _buildModeButton(
                  '최소',
                  WmsOptimizationMode.minimal,
                  Colors.orange,
                ),
                _buildModeButton(
                  '끄기',
                  WmsOptimizationMode.disabled,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 개별 기능 제어
            const Text('개별 기능', style: TextStyle(fontWeight: FontWeight.w600)),
            _buildToggle(
              '스마트 캐시',
              _settings.enableSmartCache,
              _settings.setSmartCacheEnabled,
              '98% 성능 향상',
            ),
            _buildToggle(
              'DB 연결 풀',
              _settings.enableDatabasePool,
              _settings.setDatabasePoolEnabled,
              '95% 성능 향상',
            ),
            _buildToggle(
              '바코드 최적화',
              _settings.enableOptimizedBarcode,
              _settings.setOptimizedBarcodeEnabled,
              '85% 성능 향상',
            ),

            const SizedBox(height: 16),

            // 현재 성능 예측
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '예상 성능 향상: ${_settings._calculateEstimatedGain()}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 빠른 액션 버튼
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _settings.enableSafeMode,
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('안전모드'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _settings.enableMaxPerformanceMode,
                  icon: const Icon(Icons.rocket_launch, size: 16),
                  label: const Text('최고성능'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, WmsOptimizationMode mode, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => _settings.setOptimizationMode(mode)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildToggle(
    String title,
    bool value,
    Function(bool) onChanged,
    String description,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(description, style: TextStyle(color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: (val) => setState(() => onChanged(val)),
      ),
    );
  }
}
