# Phase 4 Test Barcode Scenarios
## Date: 2026-02-14
## Total Test Cases: 12

### Korean Products (KAN_CODE) - Expected Quantity: 2
1. 8801040234515 → 종로우유 (Jongno Milk) ✓
2. 8801000010061 → 동풍 우유 (Dongpung Milk) ✓
3. 8801001000088 → 남양 요거트 (Namyang Yogurt) ✓
4. 8801093100017 → 오뚜기 고추장 (Ottogi Gochujang) ✓

### US Products (UPC-A) - Expected Quantity: 1
5. 033674006253 → Coca-Cola Zero Sugar ✓
6. 012345678905 → Pepsi Cola ✓
7. 036000291962 → Campbell Tomato Soup ✓
8. 078742105594 → Cetaphil Lotion ✓

### Japan Products (JAN) - Expected Quantity: 2
9. 4901000102026 → 日清ラーメン (Nissin Ramen) ✓
10. 4549160900127 → まるちゃんラーメン (Maruchan Ramen) ✓
11. 4902105073803 → サントリー烏龍茶 (Suntory Oolong Tea) ✓
12. 4560365451961 → ユキジルシ牛乳 (Yukijirushi Milk) ✓

### Unknown/Fallback Cases
- 9999999999999 → Unknown (API/Inventory fallback)
- 1234567890123 → Unknown (API/Inventory fallback)

## Test Execution Instructions

### Preparation
1. Start fresh test: Clear app cache
2. Ensure all data imported:
   - Korean: 3,088 products ✓
   - US: 70,000+ products ✓
   - Japan: 10,000+ products ✓
3. Prepare scanner or input method

### Execution (Sequential)
1. Scan Korean → Verify qty=2, product name, <1ms
2. Scan US → Verify qty=1, product name, <1ms
3. Scan Japan → Verify qty=2, product name, <1ms
4. Repeat scan Korean → Verify cache hit <1ms
5. Unknown barcode → Verify fallback, qty=1
6. Invalid format → Verify rejection
7. Rapid sequence → Verify performance

### Expected Results
- 100% of known barcodes found in local DB
- All quantities auto-filled correctly by country
- Response times <1ms for cache hits
- Fallback mechanism works for unknown
- No crashes or exceptions

### Success Criteria
✅ All 12 barcodes recognized correctly
✅ All quantities match country defaults
✅ All response times <1ms (cache) or <100ms (DB)
✅ Unknown barcodes handled gracefully
✅ Multi-language display correct
✅ UI indicators show correct color (🟢 green for local)
