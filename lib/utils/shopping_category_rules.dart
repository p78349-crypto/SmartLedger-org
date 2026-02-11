/// SSOT keyword rules for shopping item → category suggestion.
///
/// Add more keywords by editing these maps.
library;

part 'shopping_category_rules_food.dart';
part 'shopping_category_rules_living.dart';

typedef ShoppingCategoryPair = ({
  String mainCategory,
  String? subCategory,
  String? detailCategory,
});

class ShoppingCategoryRules {
  const ShoppingCategoryRules._();

  static const ShoppingCategoryPair foodGrocery = (
    mainCategory: '식품·음료비',
    subCategory: '장보기',
    detailCategory: null,
  );

  static const ShoppingCategoryPair foodSnack = (
    mainCategory: '식품·음료비',
    subCategory: '간식',
    detailCategory: null,
  );

  static const ShoppingCategoryPair foodProcessed = (
    mainCategory: '식품·음료비',
    subCategory: '가공식품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair foodMeat = (
    mainCategory: '식품·음료비',
    subCategory: '육류',
    detailCategory: null,
  );

  static const ShoppingCategoryPair foodDrink = (
    mainCategory: '식품·음료비',
    subCategory: '음료',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesHygiene = (
    mainCategory: '생활용품비',
    subCategory: '위생용품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesPaper = (
    mainCategory: '생활용품비',
    subCategory: '종이용품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesConsumable = (
    mainCategory: '생활용품비',
    subCategory: '생활소모품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesBaby = (
    mainCategory: '생활용품비',
    subCategory: '유아용품',
    detailCategory: null,
  );

  // --- Templates (expand by filling keywords) ---
  // Tip: 키워드는 짧게(부분일치) 넣는 게 유지보수에 유리합니다.
  // 예) '타이레놀', '감기약', '주차', '버스', '셔츠'

  static const ShoppingCategoryPair medicalPharmacy = (
    mainCategory: '의료비',
    subCategory: '약국 의약품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair medicalHospital = (
    mainCategory: '의료비',
    subCategory: '병원 진료비',
    detailCategory: null,
  );

  static const ShoppingCategoryPair transportPublic = (
    mainCategory: '교통비',
    subCategory: '대중교통',
    detailCategory: null,
  );

  static const ShoppingCategoryPair transportParking = (
    mainCategory: '교통비',
    subCategory: '주차',
    detailCategory: null,
  );

  static const ShoppingCategoryPair housingUtilities = (
    mainCategory: '주거비',
    subCategory: '관리비',
    detailCategory: null,
  );

  static const ShoppingCategoryPair clothing = (
    mainCategory: '의류/잡화',
    subCategory: '의류',
    detailCategory: null,
  );

  // 주류: recommended to live under "식품·음료비" as an optional subcategory.
  static const ShoppingCategoryPair alcohol = (
    mainCategory: '식품·음료비',
    subCategory: '주류',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesKitchen = (
    mainCategory: '생활용품비',
    subCategory: '주방용품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesStationery = (
    mainCategory: '생활용품비',
    subCategory: '문구/사무용품',
    detailCategory: null,
  );

  static const ShoppingCategoryPair suppliesPet = (
    mainCategory: '생활용품비',
    subCategory: '반려동물용품',
    detailCategory: null,
  );

  // --- Keyword maps (defined in part files) ---
  static const groceryKeywords = _groceryKeywords;
  static const snackKeywords = _snackKeywords;
  static const processedKeywords = _processedKeywords;
  static const meatKeywords = _meatKeywords;
  static const drinkKeywords = _drinkKeywords;
  static const alcoholKeywords = _alcoholKeywords;
  static const hygieneKeywords = _hygieneKeywords;
  static const paperKeywords = _paperKeywords;
  static const consumableKeywords = _consumableKeywords;
  static const babyKeywords = _babyKeywords;
  static const kitchenKeywords = _kitchenKeywords;
  static const stationeryKeywords = _stationeryKeywords;
  static const petKeywords = _petKeywords;
  static const medicalPharmacyKeywords = _medicalPharmacyKeywords;
  static const medicalHospitalKeywords = _medicalHospitalKeywords;
  static const transportPublicKeywords = _transportPublicKeywords;
  static const transportParkingKeywords = _transportParkingKeywords;
  static const housingKeywords = _housingKeywords;
  static const clothingKeywords = _clothingKeywords;

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
