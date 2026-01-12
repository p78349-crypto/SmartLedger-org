part of deep_link_handler;

mixin _DeepLinkHandlerOpenRouteFoodExpiry on _DeepLinkHandlerBase {
  @override
  bool _handleOpenRouteFoodExpiry({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
  }) {
    if (action.routeName != AppRoutes.foodExpiry) return false;

    if (action.intent == 'upsert') {
      return _handleFoodExpiryUpsert(
        navigator: navigator,
        action: action,
        spec: spec,
        filteredParams: filteredParams,
      );
    }

    final intent = (action.intent ?? '').trim().toLowerCase();
    if (intent == 'recipe_recommendation' || intent == 'recipe_recommend') {
      navigator.pushNamed(
        spec.routeName,
        arguments: const FoodExpiryArgs(
          scrollToDailyRecipeRecommendationOnStart: true,
        ),
      );
      return true;
    }

    if (intent == 'cookable_recipe_picker' || intent == 'cookable_recipes') {
      navigator.pushNamed(
        spec.routeName,
        arguments: const FoodExpiryArgs(openCookableRecipePickerOnStart: true),
      );
      return true;
    }

    if (intent == 'usage_mode' || intent == 'auto_usage') {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: action.routeName,
        intent: intent,
        success: true,
      );

      navigator.pushNamed(
        spec.routeName,
        arguments: const FoodExpiryArgs(autoUsageMode: true),
      );
      return true;
    }

    return false;
  }

  bool _handleFoodExpiryUpsert({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
  }) {
    final p = filteredParams;

    String? name = p['name'] ?? p['item'] ?? p['product'];
    name = name?.trim();

    final quantity = double.tryParse((p['quantity'] ?? p['qty'] ?? '').trim());
    final unit = (p['unit'] ?? '').trim();
    final location = (p['location'] ?? '').trim();
    final category = (p['category'] ?? '').trim();
    final supplier =
        (p['supplier'] ?? p['purchasePlace'] ?? p['place'] ?? p['store'] ?? '')
            .trim();
    final memo = (p['memo'] ?? p['note'] ?? p['desc'] ?? '').trim();
    final price = double.tryParse((p['price'] ?? '').trim());

    final healthTagsRaw = (p['healthTags'] ?? p['tags'] ?? '').trim();
    final allowedTags = HealthGuardrailService.defaultTags.toSet();
    final healthTags = <String>{};
    if (healthTagsRaw.isNotEmpty) {
      final normalized = healthTagsRaw.replaceAll('|', ',');
      final parts = normalized
          .split(',')
          .expand((s) => s.split(RegExp(r'\s+')))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (parts.isNotEmpty) {
        for (final part in parts) {
          if (allowedTags.contains(part)) {
            healthTags.add(part);
          }
        }
      }

      for (final t in allowedTags) {
        if (healthTagsRaw.contains(t)) {
          healthTags.add(t);
        }
      }
    }

    DateTime? purchaseDate;
    final purchaseDateRaw =
        (p['purchaseDate'] ?? p['purchasedAt'] ?? p['buyDate'] ?? '').trim();
    if (purchaseDateRaw.isNotEmpty) {
      purchaseDate = DateTime.tryParse(purchaseDateRaw);
      purchaseDate ??= DateParser.parse(purchaseDateRaw);
    }

    DateTime? expiryDate;
    final expiryDateRaw = (p['expiryDate'] ?? p['expiry'] ?? '').trim();
    if (expiryDateRaw.isNotEmpty) {
      expiryDate = DateTime.tryParse(expiryDateRaw);
      expiryDate ??= DateParser.parse(expiryDateRaw);
    }
    if (expiryDate == null) {
      final days = int.tryParse((p['expiryDays'] ?? p['days'] ?? '').trim());
      if (days != null && days >= 0) {
        expiryDate = DateTime.now().add(Duration(days: days));
      }
    }

    final prefill = FoodExpiryUpsertPrefill(
      name: name,
      quantity: quantity,
      unit: unit.isEmpty ? null : unit,
      location: location.isEmpty ? null : location,
      category: category.isEmpty ? null : category,
      supplier: supplier.isEmpty ? null : supplier,
      memo: memo.isEmpty ? null : memo,
      purchaseDate: purchaseDate,
      healthTags: healthTags.isEmpty ? null : healthTags.toList(),
      expiryDate: expiryDate,
      price: price,
    );

    void openDialog({required bool autoSubmit}) {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: action.routeName,
        intent: action.intent ?? 'upsert',
        success: true,
      );

      navigator.pushNamed(
        spec.routeName,
        arguments: FoodExpiryArgs(
          openUpsertOnStart: true,
          upsertPrefill: prefill,
          upsertAutoSubmit: autoSubmit,
        ),
      );
    }

    if (action.autoSubmit) {
      final missingForAuto = name == null || name.isEmpty || expiryDate == null;
      if (missingForAuto) {
        _showSimpleInfoDialog(
          navigator,
          title: '자동 등록 불가',
          message:
              '자동 등록을 위해서는 품목명과 유통기한 정보가 필요합니다.\n'
              '화면을 열어 입력을 계속 진행하세요.',
        );
        openDialog(autoSubmit: false);
        return true;
      }

      if (!action.confirmed) {
        final qtyText = quantity == null
            ? '미입력'
            : (quantity == quantity.roundToDouble()
                  ? quantity.toStringAsFixed(0)
                  : quantity.toString());
        final unitText = unit.isEmpty ? '' : unit;
        final locText = location.isEmpty ? '미지정' : location;
        final catText = category.isEmpty ? '미지정' : category;

        final priceText = price == null
            ? null
            : (price == price.roundToDouble()
                  ? price.toStringAsFixed(0)
                  : price.toString());

        final supplierText = supplier.isEmpty ? null : supplier;
        final memoText = memo.isEmpty ? null : memo;
        final tagsText = healthTags.isEmpty ? null : healthTags.join(', ');

        showDialog<bool>(
          context: navigator.context,
          builder: (dialogContext) {
            final purchaseDateText = purchaseDate
                ?.toLocal()
                .toString()
                .split(' ')
                .first;
            final expiryDateText = expiryDate
                ?.toLocal()
                .toString()
                .split(' ')
                .first;

            return AlertDialog(
              title: const Text('등록 전에 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('품목: $name'),
                  Text('수량: $qtyText$unitText'),
                  Text('보관: $locText'),
                  if (category.isNotEmpty) Text('분류: $catText'),
                  if (priceText != null) Text('가격: $priceText'),
                  if (supplierText != null) Text('구매처: $supplierText'),
                  if (memoText != null) Text('메모: $memoText'),
                  if (tagsText != null) Text('태그: $tagsText'),
                  if (purchaseDateText != null) Text('구매일: $purchaseDateText'),
                  if (expiryDateText != null) Text('유통기한: $expiryDateText'),
                  const SizedBox(height: 8),
                  const Text('이대로 등록할까요?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('등록'),
                ),
              ],
            );
          },
        ).then((confirmed) {
          if (confirmed == true) {
            openDialog(autoSubmit: true);
          }
        });
        return true;
      }

      openDialog(autoSubmit: true);
      return true;
    }

    openDialog(autoSubmit: false);
    return true;
  }
}
