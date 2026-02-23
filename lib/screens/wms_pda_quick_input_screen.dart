import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/consumable_inventory_item.dart';
import '../models/global_product.dart';
import '../services/consumable_inventory_service.dart';
import '../services/global_product_service.dart';
import '../services/openfoodfacts_service.dart';
import '../migrations/migration_global_product_db.dart';
import '../utils/app_logger.dart';
import '../utils/wms_database_pool.dart';
import '../utils/wms_optimized_barcode_service.dart';

/// PDA 모드: 바코드 스캔으로 빠른 입출고 (재고 증감만)
class WmsPdaQuickInputScreen extends StatefulWidget {
  final String accountName;
  final bool isInbound; // true: 입고, false: 출고

  const WmsPdaQuickInputScreen({
    super.key,
    required this.accountName,
    this.isInbound = true,
  });

  @override
  State<WmsPdaQuickInputScreen> createState() => _WmsPdaQuickInputScreenState();
}

class _WmsPdaQuickInputScreenState extends State<WmsPdaQuickInputScreen>
    with WidgetsBindingObserver {
  // 🚀 최적화된 서비스들
  final _barcodeService = WmsOptimizedBarcodeService.instance;
  final OpenFoodFactsService _offService = OpenFoodFactsService();
  GlobalProductService? _globalProductService;
  Database? _globalProductDb;
  bool _isProcessing = false;

  // 스캔 결과 리스트
  final List<WmsQuickItem> _scannedItems = [];

  // 포커스 노드
  late FocusNode _barcodeFocus;
  late FocusNode _quantityFocus;

  // 입력 컨트롤러
  late TextEditingController _barcodeController;
  late TextEditingController _quantityController;

  // 현재 스캔된 항목
  WmsQuickItem? _currentItem;
  GlobalProduct? _currentGlobalProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _barcodeFocus = FocusNode();
    _quantityFocus = FocusNode();
    _barcodeController = TextEditingController();
    _quantityController = TextEditingController();
    
    // Initialize GlobalProductService
    _initializeGlobalProductService();
    
    // 초기 포커스를 바코드 필드로 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
    
  }

  Future<void> _initializeGlobalProductService() async {
    try {
      // 🚀 최적화: 데이터베이스 풀 사용
      _globalProductDb = await WmsDatabasePool.instance.getGlobalProductDb();
      _globalProductService = GlobalProductService(db: _globalProductDb!);
      
      // 🚀 최적화: 바코드 서비스 초기화
      await _barcodeService.initialize();
      
      AppLogger.info('[PDA] 최적화된 서비스 초기화 완료');
    } catch (e) {
      AppLogger.error('[PDA] Error initializing optimized services', error: e);
    }
  }

  Future<void> _handleBarcodeScanned(String barcodeValue) async {
    if (_isProcessing || barcodeValue.isEmpty) return;
    
    setState(() => _isProcessing = true);

    try {
      // ===== STEP 1: Try Global Product Database =====
      final selectedProduct = _globalProductService != null
          ? await _globalProductService!.searchByBarcode(barcodeValue)
          : null;
      if (selectedProduct != null) {
        AppLogger.info('[PDA] ✓ Global product found: ${selectedProduct.getDisplayName()}');
        if (!mounted) return;
        
        // Use global product with default quantity
        setState(() {
          _currentGlobalProduct = selectedProduct;
          _quantityController.text = selectedProduct.defaultQuantity.toString();
          
          // Select text for quick overwrite
          _quantityController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _quantityController.text.length,
          );
        });
        
        // 바코드 필드 비우기
        _barcodeController.clear();
        
        // 수량 필드로 포커스 이동
        FocusScope.of(context).requestFocus(_quantityFocus);
        
        // 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${selectedProduct.getDisplayName()} '
              '(기본 수량: ${selectedProduct.defaultQuantity})',
            ),
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      // ===== STEP 2: Try OpenFoodFacts API =====
      AppLogger.info('[PDA] Global product not found, trying OpenFoodFacts API...');
      final apiProduct = await _offService.searchByBarcode(barcodeValue);
      
      if (apiProduct != null) {
        AppLogger.info('[PDA] ✓ OpenFoodFacts product found: ${apiProduct.getDisplayName()}');
        if (!mounted) return;
        setState(() {
          _currentGlobalProduct = apiProduct;
          _quantityController.text = apiProduct.defaultQuantity.toString();
          
          // Select text for quick overwrite
          _quantityController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _quantityController.text.length,
          );
        });
        
        // 바코드 필드 비우기
        _barcodeController.clear();
        
        // 수량 필드로 포커스 이동
        FocusScope.of(context).requestFocus(_quantityFocus);
        
        // 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${apiProduct.getDisplayName()} (API 조회) '
              '(기본 수량: ${apiProduct.defaultQuantity})',
            ),
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.deepOrange,
          ),
        );
        return;
      }
      
      // ===== STEP 3: Try Local Inventory =====
      AppLogger.info('[PDA] API lookup failed, searching local inventory...');
      
      await ConsumableInventoryService.instance.load();
      final items = ConsumableInventoryService.instance.items.value;
      final now = DateTime.now();
      final existingItem = items.firstWhere(
        (item) => item.name.toLowerCase() == barcodeValue.toLowerCase() ||
            item.id == barcodeValue,
        orElse: () => ConsumableInventoryItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: barcodeValue,
          unit: '개',
          createdAt: now,
          lastUpdated: now,
        ),
      );

      if (!mounted) return;
      // 수량 필드 초기화 및 포커스 이동
      _quantityController.text = '1';
      _currentItem = WmsQuickItem(
        item: existingItem,
        quantity: 1,
        timestamp: DateTime.now(),
      );
      _currentGlobalProduct = null;  // Clear global product
      
      // 바코드 필드 비우기
      _barcodeController.clear();
      
      // 수량 필드로 포커스 이동
      FocusScope.of(context).requestFocus(_quantityFocus);
      
      // 수량 필드의 텍스트 전체 선택 (빠른 덮어쓰기)
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );

      // 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${existingItem.name} (수량: 1)'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveScannedItem(int quantity) async {
    // Handle global product
    if (_currentGlobalProduct != null) {
      try {
        AppLogger.info('[PDA] Saving global product: ${_currentGlobalProduct!.getDisplayName()}');
        
        // Create a local inventory item from global product
        final localItem = ConsumableInventoryItem(
          id: 'gp_${_currentGlobalProduct!.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: _currentGlobalProduct!.getDisplayName(),
          category: _currentGlobalProduct!.category2 ?? _currentGlobalProduct!.category1 ?? '기타',
          currentStock: widget.isInbound ? quantity.toDouble() : (-quantity).toDouble(),
          unit: _currentGlobalProduct!.packagingUnit ?? '개',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        
        // Save to local inventory
        await ConsumableInventoryService.instance.addOrUpdateItem(localItem);
        
        if (mounted) {
          setState(() {
            _scannedItems.add(
              WmsQuickItem(
                item: localItem,
                quantity: quantity,
                timestamp: DateTime.now(),
              ),
            );
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_currentGlobalProduct!.getDisplayName()} '
                '${widget.isInbound ? '입고' : '출고'} 완료 (+$quantity)',
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }
    
    // Handle local inventory item
    if (_currentItem == null) return;

    final item = _currentItem!.item;

    try {
      // 수량 업데이트
      final delta = widget.isInbound ? quantity : -quantity;
      final updated = item.copyWith(
        currentStock: (item.currentStock + delta).clamp(0.0, double.infinity),
        lastUpdated: DateTime.now(),
      );

      // 저장
      await ConsumableInventoryService.instance.addOrUpdateItem(updated);

      if (mounted) {
        // 리스트에 추가
        setState(() {
          _scannedItems.add(
            WmsQuickItem(
              item: updated,
              quantity: quantity,
              timestamp: DateTime.now(),
            ),
          );
        });

        // 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name} ${widget.isInbound ? '입고' : '출고'} 완료 (+$quantity)',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearList() {
    setState(_scannedItems.clear);
  }

  Future<void> _handleQuantitySubmit() async {
    if ((_currentItem == null && _currentGlobalProduct == null) || 
        _quantityController.text.isEmpty) {
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수량은 0보다 커야 합니다')),
      );
      return;
    }

    await _saveScannedItem(quantity);

    if (mounted) {
      _quantityController.clear();
      _barcodeController.clear();
      setState(() {
        _currentItem = null;
        _currentGlobalProduct = null;
      });

      // 바코드 필드로 포커스 이동
      FocusScope.of(context).requestFocus(_barcodeFocus);
    }
  }

  Future<void> _handleBarcodeSubmit(String barcodeValue) async {
    if (barcodeValue.isEmpty) return;
    await _handleBarcodeScanned(barcodeValue);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeFocus.dispose();
    _quantityFocus.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner,
                      size: 56, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    '스캐너 입력 또는 수동 입력으로 처리합니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // 하단 입력 폼
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 바코드 입력 필드
                TextField(
                  focusNode: _barcodeFocus,
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: '📦 바코드/품목명',
                    hintText: 'Enter로 검색',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    suffixIcon: _currentItem == null
                        ? null
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  onSubmitted: _handleBarcodeSubmit,
                  onChanged: (value) {
                    // 실시간 입력 처리 (선택사항)
                  },
                  enabled: _currentItem == null,
                ),

                const SizedBox(height: 12),

                // 현재 항목 표시
                if (_currentItem != null || _currentGlobalProduct != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _currentGlobalProduct != null 
                        ? Colors.green[50] 
                        : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentGlobalProduct != null 
                          ? Colors.green 
                          : Colors.blue,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상품 정보
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentGlobalProduct?.getDisplayName() ?? 
                                    _currentItem!.item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_currentGlobalProduct != null) ...[
                                    Text(
                                      _currentGlobalProduct!.getCategoryPath(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      '현재 재고: ${_currentItem!.item.currentStock}${_currentItem!.item.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              widget.isInbound
                                  ? Icons.add_circle
                                  : Icons.remove_circle,
                              color: widget.isInbound ? Colors.green : Colors.red,
                              size: 32,
                            ),
                          ],
                        ),
                        
                        // 글로벌 제품 추가 정보
                        if (_currentGlobalProduct != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_done, 
                                  size: 14, 
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '글로벌 DB에서 자동 매칭됨',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 수량 입력 필드
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          focusNode: _quantityFocus,
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: '수량',
                            hintText: _currentGlobalProduct?.defaultQuantity.toString() ?? '1',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.add_circle),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onSubmitted: (_) => _handleQuantitySubmit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _handleQuantitySubmit,
                          icon: const Icon(Icons.check),
                          label: const Text('저장'),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    '📌 바코드를 입력하거나 카메라로 스캔하세요',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 16),

                // 스캔 결과 요약
                if (_scannedItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📋 처리됨: ${_scannedItems.length}건',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: _clearList,
                          icon: const Icon(Icons.delete_sweep, size: 20),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 스캔 결과 리스트
          Expanded(
            child: _scannedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2,
                            size: 48,
                            color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          '스캔된 항목 없음',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scannedItems.length,
                    itemBuilder: (context, index) {
                      final quickItem = _scannedItems[index];
                      return _buildScannedItemTile(quickItem, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedItemTile(WmsQuickItem item, int index) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${index + 1}'),
      ),
      title: Text(item.item.name),
      subtitle: Text(
        '${widget.isInbound ? "입고" : "출고"}: ${item.quantity}${item.item.unit}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() => _scannedItems.removeAt(index));
        },
      ),
    );
  }
}

/// PDA 스캔 결과 아이템
class WmsQuickItem {
  final ConsumableInventoryItem item;
  final int quantity;
  final DateTime timestamp;

  WmsQuickItem({
    required this.item,
    required this.quantity,
    required this.timestamp,
  });
}
