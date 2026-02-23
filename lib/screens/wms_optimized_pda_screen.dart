import 'dart:async';
import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../utils/wms_optimized_barcode_service.dart';
import '../utils/wms_smart_cache.dart';
import '../utils/wms_performance_monitor.dart';  // 🚀 성능 모니터링 추가

/// 📱 WMS 성능 최적화 PDA 화면
class WmsOptimizedPdaScreen extends StatefulWidget {
  final String accountName;
  final bool isInbound;

  const WmsOptimizedPdaScreen({
    super.key,
    required this.accountName,
    this.isInbound = true,
  });

  @override
  State<WmsOptimizedPdaScreen> createState() => _WmsOptimizedPdaScreenState();
}

class _WmsOptimizedPdaScreenState extends State<WmsOptimizedPdaScreen>
    with TickerProviderStateMixin {
  
  // 🎯 성능 최적화된 서비스들
  final _barcodeService = WmsOptimizedBarcodeService.instance;
  final _cache = WmsSmartCache.instance;
  final _performanceMonitor = WmsPerformanceMonitor.instance;  // 🚀 성능 모니터링
  
  // 📱 UI 상태 관리
  final ValueNotifier<WmsAppState> _appState = ValueNotifier(WmsAppState.idle);
  final ValueNotifier<List<WmsQuickItem>> _scannedItems = ValueNotifier([]);
  final ValueNotifier<String?> _statusMessage = ValueNotifier(null);
  
  // 🎮 입력 컨트롤러
  late TextEditingController _barcodeController;
  late TextEditingController _quantityController;
  late FocusNode _barcodeFocus;
  late FocusNode _quantityFocus;
  
  // ⚡ 성능 최적화 변수
  late AnimationController _scanAnimationController;
  Timer? _debounceTimer;
  String _lastBarcode = '';
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _preloadServices();
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeAnimations();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 🎛️ 컨트롤러 초기화
  void _initializeControllers() {
    _barcodeController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _barcodeFocus = FocusNode();
    _quantityFocus = FocusNode();
    
    // 바코드 입력 시 디바운싱 적용
    _barcodeController.addListener(_onBarcodeChanged);
  }

  /// 🎨 애니메이션 초기화
  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  /// 🚀 서비스 프리로드 (백그라운드)
  void _preloadServices() {
    // 서비스 초기화를 백그라운드에서 수행
    Future.microtask(() async {
      try {
        await _barcodeService.initialize();
        // 캐시 워밍업 (자주 사용되는 데이터 미리 로딩)
        _cache.getAllItems();
      } catch (e) {
        _updateStatus('서비스 초기화 오류: $e', isError: true);
      }
    });
  }

  /// 📝 바코드 입력 변경 감지 (디바운싱)
  void _onBarcodeChanged() {
    final barcode = _barcodeController.text.trim();
    
    // 중복 처리 방지
    if (barcode == _lastBarcode) return;
    _lastBarcode = barcode;
    
    // 디바운싱: 500ms 후에 검색 실행
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (barcode.isNotEmpty && barcode.length >= 8) {
        _handleBarcodeScanned(barcode);
      }
    });
  }

  /// 🔍 바코드 스캔 처리 (최적화됨)
  Future<void> _handleBarcodeScanned(String barcode) async {
    if (_appState.value == WmsAppState.processing) return;

    // 🎯 성능 최적화: UI 업데이트 최소화
    _setAppState(WmsAppState.processing);
    _scanAnimationController.repeat();

    try {
      final result = await _barcodeService.searchBarcode(
        barcode,
        timeout: const Duration(seconds: 2),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final product = result.product!;
        _addScannedItem(product, barcode);
        _updateStatus(
          '${product.getDisplayName()} (${result.searchTimeMs}ms, ${result.source})',
          isError: false,
        );
        _moveToQuantityInput();
      } else {
        _updateStatus(
          result.error ?? '바코드를 찾을 수 없습니다',
          isError: true,
        );
      }
    } catch (e) {
      _updateStatus('검색 오류: $e', isError: true);
    } finally {
      _setAppState(WmsAppState.idle);
      _scanAnimationController.stop();
    }
  }

  /// ➕ 스캔된 아이템 추가 (메모리 효율적)
  void _addScannedItem(dynamic product, String barcode) {
    final newItem = WmsQuickItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      barcode: barcode,
      name: product.name,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      timestamp: DateTime.now(),
    );

    // 📊 메모리 관리: 최대 100개 항목만 유지
    final currentItems = List<WmsQuickItem>.from(_scannedItems.value);
    if (currentItems.length >= 100) {
      currentItems.removeAt(0); // 오래된 항목 제거
    }
    
    currentItems.add(newItem);
    _scannedItems.value = currentItems;
  }

  /// 🎯 수량 입력으로 포커스 이동
  void _moveToQuantityInput() {
    _quantityFocus.requestFocus();
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
  }

  /// 🔄 앱 상태 변경 (효율적 setState)
  void _setAppState(WmsAppState newState) {
    if (_appState.value != newState) {
      _appState.value = newState;
    }
  }

  /// 💬 상태 메시지 업데이트
  void _updateStatus(String message, {required bool isError}) {
    _statusMessage.value = message;
    
    // 3초 후 메시지 자동 제거
    Timer(const Duration(seconds: 3), () {
      if (_statusMessage.value == message) {
        _statusMessage.value = null;
      }
    });
  }

  /// 🧹 리소스 정리
  void _disposeControllers() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _barcodeFocus.dispose();
    _quantityFocus.dispose();
    _appState.dispose();
    _scannedItems.dispose();
    _statusMessage.dispose();
  }

  void _disposeAnimations() {
    _scanAnimationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📱 PDA ${widget.isInbound ? "입고" : "출고"}'),
        actions: [
          // 🧹 전체 클리어 버튼
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllItems,
            tooltip: '전체 클리어',
          ),
          // 📊 성능 정보 버튼 (디버그용)
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showPerformanceStats,
            tooltip: '성능 정보',
          ),
        ],
      ),
      body: Column(
        children: [
          // 🎯 입력 영역 (최적화된 레이아웃)
          _buildOptimizedInputSection(),
          
          // 📊 상태 표시 영역
          _buildStatusSection(),
          
          // 📝 스캔된 아이템 목록 (가상화된 리스트)
          Expanded(
            child: _buildOptimizedItemList(),
          ),
        ],
      ),
      
      // ⚡ 빠른 저장 플로팅 버튼
      floatingActionButton: ValueListenableBuilder<List<WmsQuickItem>>(
        valueListenable: _scannedItems,
        builder: (context, items, _) {
          return items.isEmpty 
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: _processBatchSave,
                icon: const Icon(Icons.save),
                label: Text('저장 (${items.length})'),
              );
        },
      ),
    );
  }

  /// 🎯 최적화된 입력 섹션
  Widget _buildOptimizedInputSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 바코드 입력 필드
            Expanded(
              flex: 2,
              child: TextField(
                controller: _barcodeController,
                focusNode: _barcodeFocus,
                decoration: const InputDecoration(
                  labelText: '바코드',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _quantityFocus.requestFocus(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 수량 입력 필드
            Expanded(
              child: TextField(
                controller: _quantityController,
                focusNode: _quantityFocus,
                decoration: const InputDecoration(
                  labelText: '수량',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onEditingComplete: _confirmCurrentItem,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 상태 섹션
  Widget _buildStatusSection() {
    return ValueListenableBuilder<String?>(
      valueListenable: _statusMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  /// 📝 최적화된 아이템 리스트 (ListView.builder 사용)
  Widget _buildOptimizedItemList() {
    return ValueListenableBuilder<List<WmsQuickItem>>(
      valueListenable: _scannedItems,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('바코드를 스캔해주세요', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // 🚀 성능 최적화: ListView.builder 사용
        return ListView.builder(
          itemCount: items.length,
          // 📱 메모리 최적화: 아이템 높이 고정
          itemExtent: 72,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildOptimizedItemTile(item, index);
          },
        );
      },
    );
  }

  /// 🎯 최적화된 아이템 타일
  Widget _buildOptimizedItemTile(WmsQuickItem item, int index) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${index + 1}'),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('수량: ${item.quantity} | ${item.barcode}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _removeItem(index),
      ),
    );
  }

  /// ❌ 아이템 제거
  void _removeItem(int index) {
    final items = List<WmsQuickItem>.from(_scannedItems.value);
    items.removeAt(index);
    _scannedItems.value = items;
  }

  /// 🧹 전체 아이템 클리어
  void _clearAllItems() {
    _scannedItems.value = [];
    _barcodeController.clear();
    _quantityController.text = '1';
    _barcodeFocus.requestFocus();
  }

  /// ✅ 현재 아이템 확인
  void _confirmCurrentItem() {
    _barcodeController.clear();
    _quantityController.text = '1';
    _barcodeFocus.requestFocus();
  }

  /// 💾 배치 저장 처리
  Future<void> _processBatchSave() async {
    // TODO: 실제 저장 로직 구현
    _updateStatus('${_scannedItems.value.length}개 아이템 저장 완료', isError: false);
    _clearAllItems();
  }

  /// 📊 성능 통계 표시 (디버그용)
  void _showPerformanceStats() {
    final cacheStats = _cache.getCacheStats();
    final barcodeStats = _barcodeService.getPerformanceStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('성능 통계'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('캐시 상태: $cacheStats'),
              const SizedBox(height: 8),
              Text('바코드 서비스: $barcodeStats'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 앱 상태 열거형
enum WmsAppState {
  idle,       // 대기 중
  processing, // 처리 중
  error,      // 오류
}

/// 빠른 입력 아이템 모델
class WmsQuickItem {
  final String id;
  final String barcode;
  final String name;
  final int quantity;
  final DateTime timestamp;

  WmsQuickItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.quantity,
    required this.timestamp,
  });
}