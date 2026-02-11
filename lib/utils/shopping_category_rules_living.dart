part of 'shopping_category_rules.dart';

/// 위생용품
const Map<String, ShoppingCategoryPair> _hygieneKeywords = {
  '샴푸': ShoppingCategoryRules.suppliesHygiene,
  '린스': ShoppingCategoryRules.suppliesHygiene,
  '트리트먼트': ShoppingCategoryRules.suppliesHygiene,
  '비누': ShoppingCategoryRules.suppliesHygiene,
  '핸드워시': ShoppingCategoryRules.suppliesHygiene,
  '바디워시': ShoppingCategoryRules.suppliesHygiene,
  '치약': ShoppingCategoryRules.suppliesHygiene,
  '칫솔': ShoppingCategoryRules.suppliesHygiene,
  '가글': ShoppingCategoryRules.suppliesHygiene,
  '면도기': ShoppingCategoryRules.suppliesHygiene,
  '면도날': ShoppingCategoryRules.suppliesHygiene,
  '생리대': ShoppingCategoryRules.suppliesHygiene,
  '팬티라이너': ShoppingCategoryRules.suppliesHygiene,
};

/// 종이용품
const Map<String, ShoppingCategoryPair> _paperKeywords = {
  '휴지': ShoppingCategoryRules.suppliesPaper,
  '화장지': ShoppingCategoryRules.suppliesPaper,
  '물티슈': ShoppingCategoryRules.suppliesPaper,
  '키친타월': ShoppingCategoryRules.suppliesPaper,
  '냅킨': ShoppingCategoryRules.suppliesPaper,
  '종이컵': ShoppingCategoryRules.suppliesPaper,
};

/// 생활소모품
const Map<String, ShoppingCategoryPair> _consumableKeywords = {
  '세제': ShoppingCategoryRules.suppliesConsumable,
  '세탁세제': ShoppingCategoryRules.suppliesConsumable,
  '주방세제': ShoppingCategoryRules.suppliesConsumable,
  '섬유유연제': ShoppingCategoryRules.suppliesConsumable,
  '락스': ShoppingCategoryRules.suppliesConsumable,
  '탈취제': ShoppingCategoryRules.suppliesConsumable,
  '방향제': ShoppingCategoryRules.suppliesConsumable,
  '수세미': ShoppingCategoryRules.suppliesConsumable,
  '고무장갑': ShoppingCategoryRules.suppliesConsumable,
  '비닐봉투': ShoppingCategoryRules.suppliesConsumable,
  '지퍼백': ShoppingCategoryRules.suppliesConsumable,
  '위생백': ShoppingCategoryRules.suppliesConsumable,
  '랩': ShoppingCategoryRules.suppliesConsumable,
  '호일': ShoppingCategoryRules.suppliesConsumable,
  '건전지': ShoppingCategoryRules.suppliesConsumable,
};

/// 유아용품
const Map<String, ShoppingCategoryPair> _babyKeywords = {
  '기저귀': ShoppingCategoryRules.suppliesBaby,
  '분유': ShoppingCategoryRules.suppliesBaby,
  '젖병': ShoppingCategoryRules.suppliesBaby,
  '이유식': ShoppingCategoryRules.suppliesBaby,
  '아기': ShoppingCategoryRules.suppliesBaby,
  '유아': ShoppingCategoryRules.suppliesBaby,
};

/// 주방용품
const Map<String, ShoppingCategoryPair> _kitchenKeywords = {
  '냄비': ShoppingCategoryRules.suppliesKitchen,
  '프라이팬': ShoppingCategoryRules.suppliesKitchen,
  '칼': ShoppingCategoryRules.suppliesKitchen,
  '도마': ShoppingCategoryRules.suppliesKitchen,
  '그릇': ShoppingCategoryRules.suppliesKitchen,
  '접시': ShoppingCategoryRules.suppliesKitchen,
  '컵': ShoppingCategoryRules.suppliesKitchen,
  '수저': ShoppingCategoryRules.suppliesKitchen,
  '젓가락': ShoppingCategoryRules.suppliesKitchen,
  '포크': ShoppingCategoryRules.suppliesKitchen,
  '텀블러': ShoppingCategoryRules.suppliesKitchen,
  '밀폐용기': ShoppingCategoryRules.suppliesKitchen,
};

/// 문구/사무용품
const Map<String, ShoppingCategoryPair> _stationeryKeywords = {
  '볼펜': ShoppingCategoryRules.suppliesStationery,
  '연필': ShoppingCategoryRules.suppliesStationery,
  '노트': ShoppingCategoryRules.suppliesStationery,
  '공책': ShoppingCategoryRules.suppliesStationery,
  '가위': ShoppingCategoryRules.suppliesStationery,
  '풀': ShoppingCategoryRules.suppliesStationery,
  '테이프': ShoppingCategoryRules.suppliesStationery,
  '파일': ShoppingCategoryRules.suppliesStationery,
  'A4': ShoppingCategoryRules.suppliesStationery,
  '복사용지': ShoppingCategoryRules.suppliesStationery,
};

/// 반려동물용품
const Map<String, ShoppingCategoryPair> _petKeywords = {
  '사료': ShoppingCategoryRules.suppliesPet,
  '간식(반려)': ShoppingCategoryRules.suppliesPet,
  '배변패드': ShoppingCategoryRules.suppliesPet,
  '고양이모래': ShoppingCategoryRules.suppliesPet,
  '강아지': ShoppingCategoryRules.suppliesPet,
  '고양이': ShoppingCategoryRules.suppliesPet,
  '애견': ShoppingCategoryRules.suppliesPet,
  '애묘': ShoppingCategoryRules.suppliesPet,
};

/// 의료(약국)
const Map<String, ShoppingCategoryPair> _medicalPharmacyKeywords = {
  '타이레놀': ShoppingCategoryRules.medicalPharmacy,
  '감기약': ShoppingCategoryRules.medicalPharmacy,
  '소화제': ShoppingCategoryRules.medicalPharmacy,
  '진통제': ShoppingCategoryRules.medicalPharmacy,
  '밴드': ShoppingCategoryRules.medicalPharmacy,
  '반창고': ShoppingCategoryRules.medicalPharmacy,
  '연고': ShoppingCategoryRules.medicalPharmacy,
  '파스': ShoppingCategoryRules.medicalPharmacy,
  '마스크': ShoppingCategoryRules.medicalPharmacy,
  '비타민': ShoppingCategoryRules.medicalPharmacy,
  '영양제': ShoppingCategoryRules.medicalPharmacy,
};

/// 의료(병원)
const Map<String, ShoppingCategoryPair> _medicalHospitalKeywords = {
  '진료': ShoppingCategoryRules.medicalHospital,
  '검사': ShoppingCategoryRules.medicalHospital,
  '치과': ShoppingCategoryRules.medicalHospital,
  '내과': ShoppingCategoryRules.medicalHospital,
  '외과': ShoppingCategoryRules.medicalHospital,
  '한의원': ShoppingCategoryRules.medicalHospital,
};

/// 교통(대중교통)
const Map<String, ShoppingCategoryPair> _transportPublicKeywords = {
  '버스': ShoppingCategoryRules.transportPublic,
  '지하철': ShoppingCategoryRules.transportPublic,
  '택시': ShoppingCategoryRules.transportPublic,
  '철도': ShoppingCategoryRules.transportPublic,
  '기차': ShoppingCategoryRules.transportPublic,
  'KTX': ShoppingCategoryRules.transportPublic,
  'SRT': ShoppingCategoryRules.transportPublic,
};

/// 교통(주차)
const Map<String, ShoppingCategoryPair> _transportParkingKeywords = {
  '주차': ShoppingCategoryRules.transportParking,
  '주차비': ShoppingCategoryRules.transportParking,
  '발렛': ShoppingCategoryRules.transportParking,
};

/// 주거(공과금/관리비 등)
const Map<String, ShoppingCategoryPair> _housingKeywords = {
  '관리비': ShoppingCategoryRules.housingUtilities,
  '전기요금': (mainCategory: '주거비', subCategory: '전기요금', detailCategory: null),
  '가스요금': (mainCategory: '주거비', subCategory: '가스요금', detailCategory: null),
  '수도요금': (mainCategory: '주거비', subCategory: '수도요금', detailCategory: null),
  '월세': (mainCategory: '주거비', subCategory: '월세', detailCategory: null),
};

/// 의류/잡화
const Map<String, ShoppingCategoryPair> _clothingKeywords = {
  '셔츠': ShoppingCategoryRules.clothing,
  '티셔츠': ShoppingCategoryRules.clothing,
  '바지': ShoppingCategoryRules.clothing,
  '청바지': ShoppingCategoryRules.clothing,
  '치마': ShoppingCategoryRules.clothing,
  '원피스': ShoppingCategoryRules.clothing,
  '코트': ShoppingCategoryRules.clothing,
  '패딩': ShoppingCategoryRules.clothing,
  '양말': (mainCategory: '의류/잡화', subCategory: '속옷', detailCategory: null),
  '속옷': (mainCategory: '의류/잡화', subCategory: '속옷', detailCategory: null),
  '신발': (mainCategory: '의류/잡화', subCategory: '신발', detailCategory: null),
  '운동화': (mainCategory: '의류/잡화', subCategory: '신발', detailCategory: null),
  '가방': (mainCategory: '의류/잡화', subCategory: '가방', detailCategory: null),
  '모자': (mainCategory: '의류/잡화', subCategory: '기타잡화', detailCategory: null),
};
