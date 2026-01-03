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
    '포도': foodGrocery,
    '딸기': foodGrocery,
    '수박': foodGrocery,
    '참외': foodGrocery,
    '귤': foodGrocery,
    '오렌지': foodGrocery,
    '토마토': foodGrocery,
    '방울토마토': foodGrocery,
    '키위': foodGrocery,
    '블루베리': foodGrocery,
    '망고': foodGrocery,
    '파인애플': foodGrocery,
    '복숭아': foodGrocery,
    '자두': foodGrocery,
    '체리': foodGrocery,
    '감': foodGrocery,
    '배추': foodGrocery,
    '무': foodGrocery,
    '양파': foodGrocery,
    '파': foodGrocery,
    '마늘': foodGrocery,
    '고추': foodGrocery,
    '오이': foodGrocery,
    '당근': foodGrocery,
    '감자': foodGrocery,
    '고구마': foodGrocery,
    '상추': foodGrocery,
    '깻잎': foodGrocery,
    '시금치': foodGrocery,
    '콩나물': foodGrocery,
    '숙주': foodGrocery,
    '버섯': foodGrocery,
    '팽이': foodGrocery,
    '새송이': foodGrocery,
    '표고': foodGrocery,
    '브로콜리': foodGrocery,
    '양배추': foodGrocery,
    '파프리카': foodGrocery,
    '피망': foodGrocery,
    '애호박': foodGrocery,
    '호박': foodGrocery,
    '가지': foodGrocery,
    '우유': foodGrocery,
    '치즈': foodGrocery,
    '요거': foodGrocery,
    '요구르트': foodGrocery,
    '버터': foodGrocery,
    '생크림': foodGrocery,
    '계란': foodGrocery,
    '달걀': foodGrocery,
    '빵': foodGrocery,
    '식빵': foodGrocery,
    '베이글': foodGrocery,
    '라면': foodGrocery,
    '컵라면': foodGrocery,
    '쌀': foodGrocery,
    '잡곡': foodGrocery,
    '현미': foodGrocery,
    '콩': foodGrocery,
    '두부': foodGrocery,
    '김치': foodGrocery,
    '단무지': foodGrocery,
    '김': foodGrocery,
    '미역': foodGrocery,
    '다시마': foodGrocery,
    '멸치': foodGrocery,
    '식용유': foodGrocery,
    '참기름': foodGrocery,
    '들기름': foodGrocery,
    '간장': foodGrocery,
    '고추장': foodGrocery,
    '된장': foodGrocery,
    '쌈장': foodGrocery,
    '설탕': foodGrocery,
    '소금': foodGrocery,
    '식초': foodGrocery,
    '밀가루': foodGrocery,
    '부침가루': foodGrocery,
    '튀김가루': foodGrocery,
    '카레': foodGrocery,
    '짜장': foodGrocery,
  };

  /// 간식
  static const Map<String, ShoppingCategoryPair> snackKeywords = {
    '과자': foodSnack,
    '스낵': foodSnack,
    '쿠키': foodSnack,
    '비스킷': foodSnack,
    '초콜릿': foodSnack,
    '캔디': foodSnack,
    '사탕': foodSnack,
    '젤리': foodSnack,
    '껌': foodSnack,
    '아이스': foodSnack,
    '하드': foodSnack,
    '콘': foodSnack,
    '떡': foodSnack,
    '한과': foodSnack,
    '견과': foodSnack,
    '아몬드': foodSnack,
    '땅콩': foodSnack,
    '간식': foodSnack,
  };

  /// 가공식품
  static const Map<String, ShoppingCategoryPair> processedKeywords = {
    '햄': foodProcessed,
    '소시지': foodProcessed,
    '베이컨': foodProcessed,
    '어묵': foodProcessed,
    '맛살': foodProcessed,
    '만두': foodProcessed,
    '물만두': foodProcessed,
    '군만두': foodProcessed,
    '돈가스': foodProcessed,
    '너겟': foodProcessed,
    '피자': foodProcessed,
    '치킨': foodProcessed,
    '냉동': foodProcessed,
    '즉석': foodProcessed,
    '레토르트': foodProcessed,
    '참치캔': foodProcessed,
    '참치': foodProcessed,
    '스팸': foodProcessed,
    '통조림': foodProcessed,
    '골뱅이': foodProcessed,
    '훈제': foodProcessed,
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
    '항정': foodMeat,
    '갈비': foodMeat,
    '등심': foodMeat,
    '안심': foodMeat,
    // 소
    '소고기': foodMeat,
    '한우': foodMeat,
    '불고기': foodMeat,
    '국거리': foodMeat,
    '구이': foodMeat,
    '스테이크': foodMeat,
    '차돌': foodMeat,
    '양지': foodMeat,
    // 닭/오리
    '닭고기': foodMeat,
    '닭': foodMeat,
    '생닭': foodMeat,
    '닭가슴살': foodMeat,
    '닭다리': foodMeat,
    '닭날개': foodMeat,
    '오리': foodMeat,
    '훈제오리': foodMeat,
    // Generic
    '고기': foodMeat,
    '육류': foodMeat,
    '정육': foodMeat,
  };

  /// 음료
  static const Map<String, ShoppingCategoryPair> drinkKeywords = {
    '커피': foodDrink,
    '원두': foodDrink,
    '믹스커피': foodDrink,
    '음료': foodDrink,
    '탄산': foodDrink,
    '콜라': foodDrink,
    '사이다': foodDrink,
    '주스': foodDrink,
    '생수': foodDrink,
    '물': foodDrink,
    '차': foodDrink,
    '녹차': foodDrink,
    '홍차': foodDrink,
    '두유': foodDrink,
    '에너지드링크': foodDrink,
    '이온음료': foodDrink,
  };

  /// 위생용품
  static const Map<String, ShoppingCategoryPair> hygieneKeywords = {
    '샴푸': suppliesHygiene,
    '린스': suppliesHygiene,
    '트리트먼트': suppliesHygiene,
    '비누': suppliesHygiene,
    '핸드워시': suppliesHygiene,
    '바디워시': suppliesHygiene,
    '치약': suppliesHygiene,
    '칫솔': suppliesHygiene,
    '가글': suppliesHygiene,
    '면도기': suppliesHygiene,
    '면도날': suppliesHygiene,
    '생리대': suppliesHygiene,
    '팬티라이너': suppliesHygiene,
  };

  /// 종이용품
  static const Map<String, ShoppingCategoryPair> paperKeywords = {
    '휴지': suppliesPaper,
    '화장지': suppliesPaper,
    '물티슈': suppliesPaper,
    '키친타월': suppliesPaper,
    '냅킨': suppliesPaper,
    '종이컵': suppliesPaper,
  };

  /// 생활소모품
  static const Map<String, ShoppingCategoryPair> consumableKeywords = {
    '세제': suppliesConsumable,
    '세탁세제': suppliesConsumable,
    '주방세제': suppliesConsumable,
    '섬유유연제': suppliesConsumable,
    '락스': suppliesConsumable,
    '탈취제': suppliesConsumable,
    '방향제': suppliesConsumable,
    '수세미': suppliesConsumable,
    '고무장갑': suppliesConsumable,
    '비닐봉투': suppliesConsumable,
    '지퍼백': suppliesConsumable,
    '위생백': suppliesConsumable,
    '랩': suppliesConsumable,
    '호일': suppliesConsumable,
    '건전지': suppliesConsumable,
  };

  static const ShoppingCategoryPair suppliesKitchen = (
    mainCategory: '생활용품비',
    subCategory: '주방용품',
  );

  static const ShoppingCategoryPair suppliesStationery = (
    mainCategory: '생활용품비',
    subCategory: '문구/사무용품',
  );

  static const ShoppingCategoryPair suppliesPet = (
    mainCategory: '생활용품비',
    subCategory: '반려동물용품',
  );

  /// 유아용품
  static const Map<String, ShoppingCategoryPair> babyKeywords = {
    '기저귀': suppliesBaby,
    '분유': suppliesBaby,
    '젖병': suppliesBaby,
    '이유식': suppliesBaby,
    '아기': suppliesBaby,
    '유아': suppliesBaby,
  };

  /// 주방용품
  static const Map<String, ShoppingCategoryPair> kitchenKeywords = {
    '냄비': suppliesKitchen,
    '프라이팬': suppliesKitchen,
    '칼': suppliesKitchen,
    '도마': suppliesKitchen,
    '그릇': suppliesKitchen,
    '접시': suppliesKitchen,
    '컵': suppliesKitchen,
    '수저': suppliesKitchen,
    '젓가락': suppliesKitchen,
    '포크': suppliesKitchen,
    '텀블러': suppliesKitchen,
    '밀폐용기': suppliesKitchen,
  };

  /// 문구/사무용품
  static const Map<String, ShoppingCategoryPair> stationeryKeywords = {
    '볼펜': suppliesStationery,
    '연필': suppliesStationery,
    '노트': suppliesStationery,
    '공책': suppliesStationery,
    '가위': suppliesStationery,
    '풀': suppliesStationery,
    '테이프': suppliesStationery,
    '파일': suppliesStationery,
    'A4': suppliesStationery,
    '복사용지': suppliesStationery,
  };

  /// 반려동물용품
  static const Map<String, ShoppingCategoryPair> petKeywords = {
    '사료': suppliesPet,
    '간식(반려)': suppliesPet,
    '배변패드': suppliesPet,
    '고양이모래': suppliesPet,
    '강아지': suppliesPet,
    '고양이': suppliesPet,
    '애견': suppliesPet,
    '애묘': suppliesPet,
  };

  /// 의료(약국)
  static const Map<String, ShoppingCategoryPair> medicalPharmacyKeywords = {
    '타이레놀': medicalPharmacy,
    '감기약': medicalPharmacy,
    '소화제': medicalPharmacy,
    '진통제': medicalPharmacy,
    '밴드': medicalPharmacy,
    '반창고': medicalPharmacy,
    '연고': medicalPharmacy,
    '파스': medicalPharmacy,
    '마스크': medicalPharmacy,
    '비타민': medicalPharmacy,
    '영양제': medicalPharmacy,
  };

  /// 의료(병원)
  static const Map<String, ShoppingCategoryPair> medicalHospitalKeywords = {
    '진료': medicalHospital,
    '검사': medicalHospital,
    '치과': medicalHospital,
    '내과': medicalHospital,
    '외과': medicalHospital,
    '한의원': medicalHospital,
  };

  /// 교통(대중교통)
  static const Map<String, ShoppingCategoryPair> transportPublicKeywords = {
    '버스': transportPublic,
    '지하철': transportPublic,
    '택시': transportPublic,
    '철도': transportPublic,
    '기차': transportPublic,
    'KTX': transportPublic,
    'SRT': transportPublic,
  };

  /// 교통(주차)
  static const Map<String, ShoppingCategoryPair> transportParkingKeywords = {
    '주차': transportParking,
    '주차비': transportParking,
    '발렛': transportParking,
  };

  /// 주거(공과금/관리비 등)
  static const Map<String, ShoppingCategoryPair> housingKeywords = {
    '관리비': housingUtilities,
    '전기요금': (mainCategory: '주거비', subCategory: '전기요금'),
    '가스요금': (mainCategory: '주거비', subCategory: '가스요금'),
    '수도요금': (mainCategory: '주거비', subCategory: '수도요금'),
    '월세': (mainCategory: '주거비', subCategory: '월세'),
  };

  /// 의류/잡화
  static const Map<String, ShoppingCategoryPair> clothingKeywords = {
    '셔츠': clothing,
    '티셔츠': clothing,
    '바지': clothing,
    '청바지': clothing,
    '치마': clothing,
    '원피스': clothing,
    '코트': clothing,
    '패딩': clothing,
    '양말': (mainCategory: '의류/잡화', subCategory: '속옷'),
    '속옷': (mainCategory: '의류/잡화', subCategory: '속옷'),
    '신발': (mainCategory: '의류/잡화', subCategory: '신발'),
    '운동화': (mainCategory: '의류/잡화', subCategory: '신발'),
    '가방': (mainCategory: '의류/잡화', subCategory: '가방'),
    '모자': (mainCategory: '의류/잡화', subCategory: '기타잡화'),
  };

  /// 주류
  static const Map<String, ShoppingCategoryPair> alcoholKeywords = {
    '막걸리': alcohol,
    '소주': alcohol,
    '맥주': alcohol,
    '와인': alcohol,
    '위스키': alcohol,
    '보드카': alcohol,
    '고량주': alcohol,
    '사케': alcohol,
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
    kitchenKeywords,
    stationeryKeywords,
    petKeywords,
    medicalPharmacyKeywords,
    medicalHospitalKeywords,
    transportPublicKeywords,
    transportParkingKeywords,
    housingKeywords,
    clothingKeywords,
  ];
}
