typedef ShoppingCategoryPair = ({String mainCategory, String? subCategory});

/// SSOT keyword rules for shopping item → category suggestion.
///
/// Add more keywords by editing these maps.
class ShoppingCategoryRules {
  const ShoppingCategoryRules._();

  static const ShoppingCategoryPair foodGrocery = (
    mainCategory: '식품·음료비',
    subCategory: '장보기',
  );

  static const ShoppingCategoryPair foodSnack = (
    mainCategory: '식품·음료비',
    subCategory: '간식',
  );

  static const ShoppingCategoryPair foodProcessed = (
    mainCategory: '식품·음료비',
    subCategory: '가공식품',
  );

  static const ShoppingCategoryPair foodMeat = (
    mainCategory: '식품·음료비',
    subCategory: '육류',
  );

  static const ShoppingCategoryPair foodDrink = (
    mainCategory: '식품·음료비',
    subCategory: '음료',
  );

  static const ShoppingCategoryPair suppliesHygiene = (
    mainCategory: '생활용품비',
    subCategory: '위생용품',
  );

  static const ShoppingCategoryPair suppliesPaper = (
    mainCategory: '생활용품비',
    subCategory: '종이용품',
  );

  static const ShoppingCategoryPair suppliesConsumable = (
    mainCategory: '생활용품비',
    subCategory: '생활소모품',
  );

  static const ShoppingCategoryPair suppliesBaby = (
    mainCategory: '생활용품비',
    subCategory: '유아용품',
  );

  // --- Templates (expand by filling keywords) ---
  // Tip: 키워드는 짧게(부분일치) 넣는 게 유지보수에 유리합니다.
  // 예) '타이레놀', '감기약', '주차', '버스', '셔츠'

  static const ShoppingCategoryPair medicalPharmacy = (
    mainCategory: '의료비',
    subCategory: '약국 의약품',
  );

  static const ShoppingCategoryPair medicalHospital = (
    mainCategory: '의료비',
    subCategory: '병원 진료비',
  );

  static const ShoppingCategoryPair transportPublic = (
    mainCategory: '교통비',
    subCategory: '대중교통',
  );

  static const ShoppingCategoryPair transportParking = (
    mainCategory: '교통비',
    subCategory: '주차',
  );

  static const ShoppingCategoryPair housingUtilities = (
    mainCategory: '주거비',
    subCategory: '관리비',
  );

  static const ShoppingCategoryPair clothing = (
    mainCategory: '의류/잡화',
    subCategory: '의류',
  );

  // 주류: recommended to live under "식품·음료비" as an optional subcategory.
  static const ShoppingCategoryPair alcohol = (
    mainCategory: '식품·음료비',
    subCategory: '주류',
  );

  /// 식자재 구매 (과일/유제품/계란/주식류)
  static const Map<String, ShoppingCategoryPair> groceryKeywords = {
    '사과': foodGrocery,
    '배': foodGrocery,
    '바나나': foodGrocery,
    '우유': foodGrocery,
    '치즈': foodGrocery,
    '요거': foodGrocery,
    '계란': foodGrocery,
    '달걀': foodGrocery,
    '빵': foodGrocery,
    '라면': foodGrocery,
    '김치': foodGrocery,
  };

  /// 간식
  static const Map<String, ShoppingCategoryPair> snackKeywords = {
    '과자': foodSnack,
    '초콜릿': foodSnack,
    '아이스': foodSnack,
    '간식': foodSnack,
  };

  /// 가공식품
  static const Map<String, ShoppingCategoryPair> processedKeywords = {
    '햄': foodProcessed,
    '소시지': foodProcessed,
    '어묵': foodProcessed,
    '만두': foodProcessed,
    '냉동': foodProcessed,
    '즉석': foodProcessed,
    '레토르트': foodProcessed,
  };

  /// 육류
  static const Map<String, ShoppingCategoryPair> meatKeywords = {
    // 돼지
    '돼지고기': foodMeat,
    '돼지': foodMeat,
    '삼겹': foodMeat,
    '목살': foodMeat,
    '앞다리': foodMeat,
    '뒷다리': foodMeat,
    // 소
    '소고기': foodMeat,
    '한우': foodMeat,
    // 닭/오리
    '닭고기': foodMeat,
    '닭': foodMeat,
    '오리': foodMeat,
    // Generic
    '고기': foodMeat,
    '육류': foodMeat,
  };

  /// 음료
  static const Map<String, ShoppingCategoryPair> drinkKeywords = {
    '커피': foodDrink,
    '음료': foodDrink,
    '콜라': foodDrink,
    '주스': foodDrink,
  };

  /// 위생용품
  static const Map<String, ShoppingCategoryPair> hygieneKeywords = {
    '샴푸': suppliesHygiene,
    '린스': suppliesHygiene,
    '비누': suppliesHygiene,
    '치약': suppliesHygiene,
    '칫솔': suppliesHygiene,
  };

  /// 종이용품
  static const Map<String, ShoppingCategoryPair> paperKeywords = {
    '휴지': suppliesPaper,
    '물티슈': suppliesPaper,
    '키친타월': suppliesPaper,
  };

  /// 생활소모품
  static const Map<String, ShoppingCategoryPair> consumableKeywords = {
    '세제': suppliesConsumable,
    '섬유유연제': suppliesConsumable,
    '락스': suppliesConsumable,
  };

  /// 유아용품
  static const Map<String, ShoppingCategoryPair> babyKeywords = {
    '기저귀': suppliesBaby,
    '분유': suppliesBaby,
    '젖병': suppliesBaby,
  };

  /// 의료(약국)
  static const Map<String, ShoppingCategoryPair> medicalPharmacyKeywords = {
    // '타이레놀': medicalPharmacy,
    // '감기약': medicalPharmacy,
    // '파스': medicalPharmacy,
  };

  /// 의료(병원)
  static const Map<String, ShoppingCategoryPair> medicalHospitalKeywords = {
    // '진료': medicalHospital,
    // '검사': medicalHospital,
  };

  /// 교통(대중교통)
  static const Map<String, ShoppingCategoryPair> transportPublicKeywords = {
    // '버스': transportPublic,
    // '지하철': transportPublic,
    // '택시': transportPublic,
  };

  /// 교통(주차)
  static const Map<String, ShoppingCategoryPair> transportParkingKeywords = {
    // '주차': transportParking,
  };

  /// 주거(공과금/관리비 등)
  static const Map<String, ShoppingCategoryPair> housingKeywords = {
    // '관리비': housingUtilities,
    // '전기': (mainCategory: '주거비', subCategory: '전기요금'),
    // '가스': (mainCategory: '주거비', subCategory: '가스요금'),
    // '수도': (mainCategory: '주거비', subCategory: '수도요금'),
  };

  /// 의류/잡화
  static const Map<String, ShoppingCategoryPair> clothingKeywords = {
    // '셔츠': clothing,
    // '바지': clothing,
    // '양말': (mainCategory: '의류/잡화', subCategory: '속옷'),
  };

  /// 주류
  static const Map<String, ShoppingCategoryPair> alcoholKeywords = {
    '막걸리': alcohol,
    '소주': alcohol,
    '맥주': alcohol,
    '와인': alcohol,
    '위스키': alcohol,
    // Broad matches (fallback)
    '주류': alcohol,
    '술': alcohol,
  };

  /// Ordered groups. First match wins.
  static const List<Map<String, ShoppingCategoryPair>> groups = [
    groceryKeywords,
    meatKeywords,
    processedKeywords,
    snackKeywords,
    drinkKeywords,
    alcoholKeywords,
    hygieneKeywords,
    paperKeywords,
    consumableKeywords,
    babyKeywords,
    medicalPharmacyKeywords,
    medicalHospitalKeywords,
    transportPublicKeywords,
    transportParkingKeywords,
    housingKeywords,
    clothingKeywords,
  ];
}

