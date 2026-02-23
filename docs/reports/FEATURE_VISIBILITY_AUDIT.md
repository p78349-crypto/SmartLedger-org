# 🔍 앱 출시 전 기능 가시성 정밀 점검

## 📋 라우트 vs 페이지 매핑 분석

### 전체 라우트: ~100개

#### Page 0: Page Zero
- [ ] buildPageZeroItems() 상세 확인

#### Page 1: Purchase (거래/쇼핑)
- transactionAdd ✅
- quickSimpleExpenseInput ✅
- transactionAddDetailed ✅
- healthAnalyzer ✅
- nutritionReport ✅
- ingredientSearch ✅
- shoppingCart ✅
- shoppingPrep ✅
- shoppingGuide ✅
- shoppingPointsInput ✅
- shoppingCheapestMonth ✅
- householdConsumables ✅
- householdQuickPick ✅
- householdItems ✅
- quickStockUse ✅
- recipeManagement ✅
- recipeEdit ✅
- recipeToCart ✅
- weatherManualInput ✅

#### Page 2: Income (수입)
- transactionAddIncome ✅
- transactionDetailIncome ✅
- incomeSplit ✅
- incomeSplitStatus ❌ (exclude_routes에만)
- refundTransactions ✅ (Page 1 또는 2)
- dailyTransactions ✅ (Page 1 또는 2)

#### Page 3: Statistics (통계)
- accountStats ✅
- fixedCostStats ✅
- periodStatsWeek ✅
- periodStatsMonth ✅
- periodStatsQuarter ✅
- periodStatsHalfYear ✅
- periodStatsYear ✅
- periodStatsDecade ✅
- spendingAnalysis ✅
- weatherPricePrediction ✅
- cardDiscountStats ✅

#### Page 4: Asset (자산)
- assetDashboard ✅
- assetAllocation ✅
- assetManagement ✅
- assetSimpleInput ✅
- assetProject100m ✅

#### Page 5: Root (ROOT 관리) - 새로 정리됨
- rootSummary ✅
- rootAccountSummary ✅
- rootExpenseAnalysis ✅
- rootTransactions ✅
- rootSearch ✅
- rootAccountManage ✅
- rootMonthEnd ✅
- rootScreenSaverSettings ⚠️ (exclude_routes에 있는데 페이지 5에 노출됨)
- iconManagementRoot ✅

#### Page 6: Settings (설정)
- [ ] settings 관련 아이콘 상세 확인

#### Pages 7-14: 빈 페이지 (할당 가능)

---

## 🔴 발견 사항

### 1. 모순: rootScreenSaverSettings
```
위치 1: exclude_routes.txt (의도적 미노출)
위치 2: Page 5 "보호기 설정" 아이콘 (노출됨)
```
**결정 필요:** 노출 또는 숨김?

### 2. 미할당 라우트 확인 필요

#### CEO 어시스턴트 (5개 라우트)
```
- ceoAssistant
- ceoExceptionDetails
- ceoRecoveryPlan
- ceoRoiDetail
- ceoMonthlyDefenseReport
```
**상태:** 어디서도 아이콘 찾을 수 없음  
**확인 필요:** ROOT 페이지 5 또는 다른 곳에 있나?

#### 음성 기능
```
- voiceShortcuts, voiceDashboard, voiceAssistantSettings
- geminiVoiceInput, smartVoiceCommand
- (gemmaApiTest는 개발/테스트용)
```
**상태:** Settings인가? 아니면 따로?

#### 미노출 기능
```
- emergencyFund (미완성)
- savingsPlanList (아직 미노출)
- calendar (아직 미노출)
- foodExpiry (아직 미노출)
- foodCookingStart (?)
```
**상태:** 준비 상태? 페이지 7로 할당?

### 3. 페이지별 아이콘 개수
- Page 0: ? (확인 필요)
- Page 1: 19개 ✅
- Page 2: 6개 ✅
- Page 3: 11개 ✅
- Page 4: 5개 ✅
- Page 5: 9개 ✅ (새로 정리됨)
- Page 6: ? (설정 아이콘)
- Page 7-14: 0개 (빈 페이지)

---

## ✅ 점검 체크리스트

### 라우트 가시성
- [ ] CEO 어시스턴트 5개 기능 위치 확인
- [ ] foodCookingStart 라우트 확인  
- [ ] voiceShortcuts 등 음성 기능 위치 확인
- [ ] pointsMotivationStats 어느 페이지?
- [ ] incomeSplitStatus 노출 vs 비노출?

### 의도성 검증
- [ ] rootScreenSaverSettings 의도적 숨김 vs 실수? → **결정 필요**
- [ ] exclude_routes.txt와 실제 페이지 일치성
- [ ] 미완성 기능(emergencyFund, savingsPlanList) 확인

### 새 기능 준비
- [ ] Page 7 이상 빈 페이지 활용 계획?
- [ ] 새로운 라우트 추가 계획?

---

## 🎯 최종 결론
**출시 전 조치:**
1. CEO 어시스턴트 기능 위치 확인
2. rootScreenSaverSettings 모순 해결
3. 모든 라우트가 페이지에 노출되거나 exclude_routes에 있는지 확인
4. 의도적 미노출 vs 실수 구분
