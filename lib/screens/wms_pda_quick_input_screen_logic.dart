part of 'wms_pda_quick_input_screen.dart';

extension WmsPdaQuickInputScreenLogic on _WmsPdaQuickInputScreenState {
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
        AppLogger.info(
          '[PDA] ✓ Global product found: ${selectedProduct.getDisplayName()}',
        );
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
      AppLogger.info(
        '[PDA] Global product not found, trying OpenFoodFacts API...',
      );
      final apiProduct = await _offService.searchByBarcode(barcodeValue);

      if (apiProduct != null) {
        AppLogger.info(
          '[PDA] ✓ OpenFoodFacts product found: ${apiProduct.getDisplayName()}',
        );
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
        (item) =>
            item.name.toLowerCase() == barcodeValue.toLowerCase() ||
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
      _currentGlobalProduct = null; // Clear global product

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
          SnackBar(content: Text('검색 실패: $e'), backgroundColor: Colors.red),
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
        AppLogger.info(
          '[PDA] Saving global product: ${_currentGlobalProduct!.getDisplayName()}',
        );

        // Create a local inventory item from global product
        final localItem = ConsumableInventoryItem(
          id: 'gp_${_currentGlobalProduct!.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: _currentGlobalProduct!.getDisplayName(),
          category:
              _currentGlobalProduct!.category2 ??
              _currentGlobalProduct!.category1 ??
              '기타',
          currentStock: widget.isInbound
              ? quantity.toDouble()
              : (-quantity).toDouble(),
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
            SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수량은 0보다 커야 합니다')));
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
}
