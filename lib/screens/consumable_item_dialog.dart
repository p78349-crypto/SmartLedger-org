import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/consumable_inventory_item.dart';
import '../models/global_product.dart';
import '../services/consumable_inventory_service.dart';
import '../services/global_product_service.dart';
import '../services/openfoodfacts_service.dart';
import '../utils/wms_data_gateway.dart';

/// 아이템 추가/수정 다이얼로그 표시
Future<void> showConsumableItemDialog({
  required BuildContext context,
  ConsumableInventoryItem? item,
  String? initialLocation,
}) async {
  // Database & Services for barcode lookup
  GlobalProductService? globalProductService;
  final offService = OpenFoodFactsService();

  try {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'global_products.db');
    final db = await openDatabase(path);
    globalProductService = GlobalProductService(db: db);
  } catch (_) {}

  if (!context.mounted) return;

  final nameController = TextEditingController(text: item?.name ?? '');
  String? lastScannedBarcode = item?.barcode;
  bool isSearchingBarcode = false;

  final stockController = TextEditingController(
    text: item?.currentStock.toString() ?? '0',
  );
  final thresholdController = TextEditingController(
    text: item?.threshold.toString() ?? '1',
  );
  final bundleSizeController = TextEditingController(
    text: item?.bundleSize.toString() ?? '1',
  );
  final unitController = TextEditingController(text: item?.unit ?? '개');
  final locationController = TextEditingController(
    text: item?.location ?? initialLocation ?? '주방',
  );
  String selectedDropdownLocation =
      (item != null &&
          ConsumableInventoryItem.locationOptions.contains(item.location))
      ? item.location
      : (initialLocation != null &&
            ConsumableInventoryItem.locationOptions.contains(initialLocation))
      ? initialLocation
      : (item == null && initialLocation == null)
      ? '주방'
      : '직접 입력';

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isCustomLocation = selectedDropdownLocation == '직접 입력';

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(item == null ? '재고 추가' : '재고 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 품목명
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '품목명 (예: 휴지)',
                      suffixIcon: isSearchingBarcode
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () async {
                                final barcode = nameController.text.trim();
                                if (barcode.isEmpty) return;

                                setDialogState(() {
                                  isSearchingBarcode = true;
                                  lastScannedBarcode = barcode;
                                });

                                try {
                                  GlobalProduct? product =
                                      await globalProductService
                                          ?.searchByBarcode(barcode);
                                  product ??= await offService.searchByBarcode(
                                    barcode,
                                  );

                                  if (product != null) {
                                    final p = product;
                                    setDialogState(() {
                                      nameController.text = p.getDisplayName();
                                      unitController.text =
                                          p.packagingUnit ?? '개';
                                      bundleSizeController.text = p
                                          .defaultQuantity
                                          .toString();
                                    });
                                  }
                                } finally {
                                  setDialogState(() {
                                    isSearchingBarcode = false;
                                  });
                                }
                              },
                            ),
                    ),
                    onSubmitted: (value) async {
                      // 바코드 형식(숫자로만 구성된 긴 문자열)이면 자동 검색 지원
                      if (RegExp(r'^\d{8,14}$').hasMatch(value.trim())) {
                        final barcode = value.trim();
                        setDialogState(() {
                          isSearchingBarcode = true;
                          lastScannedBarcode = barcode;
                        });
                        try {
                          GlobalProduct? product = await globalProductService
                              ?.searchByBarcode(barcode);
                          product ??= await offService.searchByBarcode(barcode);
                          if (product != null) {
                            final p = product;
                            setDialogState(() {
                              nameController.text = p.getDisplayName();
                              unitController.text = p.packagingUnit ?? '개';
                              bundleSizeController.text = p.defaultQuantity
                                  .toString();
                            });
                          }
                        } finally {
                          setDialogState(() {
                            isSearchingBarcode = false;
                          });
                        }
                      }
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(labelText: '현재고'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: '단위 (예: 롤, 개)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDropdownLocation,
                    decoration: const InputDecoration(
                      labelText: '보관 위치 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...ConsumableInventoryItem.locationOptions.map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
                      ),
                      const DropdownMenuItem(
                        value: '직접 입력',
                        child: Text('직접 입력...'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedDropdownLocation = val;
                          if (val != '직접 입력') {
                            locationController.text = val;
                          }
                        });
                      }
                    },
                  ),
                  if (isCustomLocation) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: '상세 위치 입력 (예: 베란다, 다락)',
                        hintText: '위치 이름을 직접 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: thresholdController,
                    decoration: const InputDecoration(
                      labelText: '알림 기준 (이하일 때 알림)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextField(
                    controller: bundleSizeController,
                    decoration: const InputDecoration(
                      labelText: '묶음 단위 (예: 30롤 묶음이면 30)',
                      hintText: '휴지 대형 묶음은 보통 30입니다.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (item != null)
                TextButton(
                  onPressed: () {
                    ConsumableInventoryService.instance.deleteItem(item.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => _handleConsumableItemSave(
                  context: context,
                  dialogContext: ctx,
                  item: item,
                  nameController: nameController,
                  barcode: lastScannedBarcode,
                  stockController: stockController,
                  thresholdController: thresholdController,
                  bundleSizeController: bundleSizeController,
                  unitController: unitController,
                  location: locationController.text,
                ),
                child: const Text('저장'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _handleConsumableItemSave({
  required BuildContext context,
  required BuildContext dialogContext,
  required ConsumableInventoryItem? item,
  required TextEditingController nameController,
  String? barcode,
  required TextEditingController stockController,
  required TextEditingController thresholdController,
  required TextEditingController bundleSizeController,
  required TextEditingController unitController,
  required String location,
}) async {
  final name = nameController.text.trim();
  if (name.isEmpty) return;

  final stock = double.tryParse(stockController.text) ?? 0.0;
  final threshold = double.tryParse(thresholdController.text) ?? 1.0;
  final bundleSize = double.tryParse(bundleSizeController.text) ?? 1.0;
  final unit = unitController.text.trim();

  if (item == null) {
    final input = WmsInventoryInput.full(
      name: name,
      barcode: barcode,
      currentStock: stock,
      unit: unit,
      threshold: threshold,
      bundleSize: bundleSize,
      location: location,
    );

    final result = await WmsInventoryGateway.instance.addItem(input: input);

    if (!context.mounted) return;

    if (result.success) {
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${result.data?.name} 추가 완료')));
    } else if (result.type == WmsOperationType.duplicate) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이미 존재하는 품목'),
          content: Text(
            '${result.data?.name}이(가) 이미 등록되어 있습니다.\n'
            '현재 재고: ${result.data?.currentStock}'
            '${result.data?.unit}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추가 실패: ${result.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
    final updated = item.copyWith(
      name: name,
      barcode: barcode,
      currentStock: stock,
      threshold: threshold,
      bundleSize: bundleSize,
      unit: unit,
      location: location,
    );

    final result = await WmsInventoryGateway.instance.updateItem(item: updated);

    if (!context.mounted) return;

    if (result.success) {
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${updated.name} 수정 완료')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정 실패: ${result.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
