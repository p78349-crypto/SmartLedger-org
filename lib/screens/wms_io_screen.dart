import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/consumable_inventory_item.dart';
import '../models/global_product.dart';
import '../services/consumable_inventory_service.dart';
import '../services/global_product_service.dart';
import '../services/openfoodfacts_service.dart';
import '../migrations/migration_global_product_db.dart';
import '../utils/wms_data_gateway.dart';
import 'wms_io_screen_widgets.dart';
import 'wms_pda_quick_input_screen.dart';
import '../utils/app_logger.dart';

/// WMS 입출고 화면 (Input/Output)
class WmsIoScreen extends StatefulWidget {
  final String accountName;

  const WmsIoScreen({super.key, required this.accountName});

  @override
  State<WmsIoScreen> createState() => _WmsIoScreenState();
}

class _WmsIoScreenState extends State<WmsIoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMS 입출고'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: '🔍 빠른 입출고'),
            Tab(icon: Icon(Icons.add_box), text: '📥 입고'),
            Tab(
              icon: Icon(Icons.remove_circle_outline),
              text: '📤 출고',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PDA 빠른 입출고 탭 (바코드 스캔)
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: '입고 모드'),
                    Tab(text: '출고 모드'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      WmsPdaQuickInputScreen(
                        accountName: widget.accountName,
                      ),
                      WmsPdaQuickInputScreen(
                        accountName: widget.accountName,
                        isInbound: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _InboundTab(accountName: widget.accountName),
          WmsOutboundTab(accountName: widget.accountName),
        ],
      ),
    );
  }
}

/// 입고 탭
class _InboundTab extends StatefulWidget {
  final String accountName;

  const _InboundTab({required this.accountName});

  @override
  State<_InboundTab> createState() => _InboundTabState();
}

class _InboundTabState extends State<_InboundTab> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '1');
  final _bundleSizeController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: '개');
  final _locationController = TextEditingController(text: '주방');
  String _selectedDropdownLocation = '주방';

  GlobalProductService? _globalProductService;
  late OpenFoodFactsService _offService;
  bool _isSearchingBarcode = false;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'global_products.db');
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async => await migrationGlobalProductDatabase(db),
      );
      _globalProductService = GlobalProductService(db: db);
      _offService = OpenFoodFactsService();
    } catch (e) {
      AppLogger.error('Error initializing WMS services', error: e);
    }
  }

  Future<void> _lookupBarcode() async {
    final barcode = _nameController.text.trim();
    if (barcode.isEmpty || _isSearchingBarcode) return;

    setState(() {
      _isSearchingBarcode = true;
      _lastScannedBarcode = barcode;
    });
    try {
      GlobalProduct? product = await _globalProductService?.searchByBarcode(barcode);
      product ??= await _offService.searchByBarcode(barcode);

      final p = product;
      if (p != null && mounted) {
        setState(() {
          _nameController.text = p.getDisplayName();
          _unitController.text = p.packagingUnit ?? '개';
          _bundleSizeController.text = p.defaultQuantity.toString();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ 상품 정보 조회 성공: ${p.getDisplayName()}')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 정보를 찾을 수 없습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingBarcode = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _bundleSizeController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleInbound() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목명을 입력하세요')),
      );
      return;
    }

    final stock = double.tryParse(_stockController.text) ?? 0.0;
    final threshold = double.tryParse(
      _thresholdController.text,
    ) ?? 1.0;
    final bundleSize = double.tryParse(
      _bundleSizeController.text,
    ) ?? 1.0;
    final unit = _unitController.text.trim();

    final input = WmsInventoryInput.full(
      name: name,
      barcode: _lastScannedBarcode,
      currentStock: stock,
      unit: unit,
      threshold: threshold,
      bundleSize: bundleSize,
      location: _locationController.text,
    );

    final result = await WmsInventoryGateway.instance.addItem(
      input: input,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.data?.name} 입고 완료')),
      );
      _clearForm();
    } else if (result.type == WmsOperationType.duplicate) {
      _showDuplicateDialog(result.data!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('입고 실패: ${result.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _stockController.text = '0';
    _thresholdController.text = '1';
    _bundleSizeController.text = '1';
    _unitController.text = '개';
    setState(() {
      _selectedDropdownLocation = '주방';
      _locationController.text = '주방';
      _lastScannedBarcode = null;
    });
  }

  Future<void> _showDuplicateDialog(
    ConsumableInventoryItem existing,
  ) async {
    final addMore = await showWmsDuplicateDialog(context, existing);

    if (addMore == true) {
      final addStock = double.tryParse(_stockController.text) ?? 0.0;
      final updated = existing.copyWith(
        currentStock: existing.currentStock + addStock,
      );
      await ConsumableInventoryService.instance.updateItem(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${existing.name}에 $addStock개 추가 완료'),
        ),
      );
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '품목명 또는 바코드 스캔',
              hintText: '예: 휴지, 세제 또는 바코드 스캔',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.inventory_2),
              suffixIcon: _isSearchingBarcode
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _lookupBarcode,
                    tooltip: '바코드로 정보 찾기',
                  ),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (value) {
              // 바코드 형식(숫자로만 구성된 긴 문자열)이면 자동 검색
              if (RegExp(r'^\d{8,14}$').hasMatch(value.trim())) {
                _lookupBarcode();
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: '입고 수량',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: '단위',
                    hintText: '개, 롤',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedDropdownLocation,
            decoration: const InputDecoration(
              labelText: '보관 위치 선택',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place),
            ),
            items: [
              ...ConsumableInventoryItem.locationOptions.map(
                (loc) => DropdownMenuItem(
                  value: loc,
                  child: Text(loc),
                ),
              ),
              const DropdownMenuItem(
                value: '직접 입력',
                child: Text('직접 입력...'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDropdownLocation = val;
                  if (val != '직접 입력') {
                    _locationController.text = val;
                  }
                });
              }
            },
          ),
          if (_selectedDropdownLocation == '직접 입력') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '상세 위치 입력 (예: 베란다, 다락)',
                hintText: '위치 이름을 직접 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: '알림 기준',
              hintText: '재고가 이 수량 이하일 때 알림',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notifications),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bundleSizeController,
            decoration: const InputDecoration(
              labelText: '묶음 단위',
              hintText: '예: 30롤 묶음이면 30',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.widgets),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleInbound(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _handleInbound,
            icon: const Icon(Icons.add_box),
            label: const Text('입고 처리'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}


