import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/consumable_inventory_item.dart';
import '../models/global_product.dart';
import '../services/consumable_inventory_service.dart';
import '../services/global_product_service.dart';
import '../services/openfoodfacts_service.dart';
import '../utils/app_logger.dart';
import '../utils/wms_database_pool.dart';
import '../utils/wms_optimized_barcode_service.dart';

/// PDA 모드: 바코드 스캔으로 빠른 입출고 (재고 증감만)
part 'wms_pda_quick_input_screen_logic.dart';

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
                  Icon(
                    Icons.qr_code_scanner,
                    size: 56,
                    color: Colors.grey[600],
                  ),
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
                              color: widget.isInbound
                                  ? Colors.green
                                  : Colors.red,
                              size: 32,
                            ),
                          ],
                        ),

                        // 글로벌 제품 추가 정보
                        if (_currentGlobalProduct != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_done,
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
                            hintText:
                                _currentGlobalProduct?.defaultQuantity
                                    .toString() ??
                                '1',
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
                        Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.grey[400],
                        ),
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
      leading: CircleAvatar(child: Text('${index + 1}')),
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
