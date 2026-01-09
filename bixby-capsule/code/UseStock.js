// UseStock Action Handler
// 재고 차감 요청을 처리합니다

const endpoints = require('./endpoints.js');

module.exports.function = function useStock(productName, amount, unit, $vivContext) {
  // 상품명 정규화
  const normalizedName = normalizeProductName(productName);

  // 딥링크 생성하여 앱에서 재고 차감 실행
  const result = endpoints.UseStock({
    productName: normalizedName,
    amount: amount,
    unit: unit
  });
  
  return result;
};

/**
 * 상품명 정규화 (동의어 처리)
 */
function normalizeProductName(name) {
  if (!name) return '';
  
  const synonymMap = {
    '팽이': '팽이버섯',
    '팽이버섯': '팽이버섯',
    '새송이': '새송이버섯',
    '표고': '표고버섯',
    '양파': '양파',
    '당근': '당근',
    '감자': '감자',
    '대파': '대파',
    '파': '대파',
    '마늘': '마늘',
    '달걀': '달걀',
    '계란': '달걀',
    '에그': '달걀',
    '소고기': '소고기',
    '쇠고기': '소고기',
    '돼지고기': '돼지고기',
    '삼겹살': '삼겹살',
    '닭고기': '닭고기',
    '닭': '닭고기',
    '새우': '새우',
    '오징어': '오징어',
    '우유': '우유',
    '치즈': '치즈',
    '두부': '두부',
    '라면': '라면'
  };
  
  const cleanName = name.trim();
  return synonymMap[cleanName] || cleanName;
}

/**
 * 상품별 기본 단위 반환
 */
function getDefaultUnit(productName) {
  const unitMap = {
    // 봉지/팩 단위
    '팽이버섯': '봉',
    '새송이버섯': '팩',
    '표고버섯': '팩',
    '라면': '개',

    // 개 단위
    '양파': '개',
    '당근': '개',
    '감자': '개',
    '고추': '개',
    '두부': '모',

    // 판/개 단위
    '달걀': '개',

    // 근/단 단위
    '대파': '단',
    '마늘': '통',

    // 팩/통 단위
    '우유': '팩',
    '치즈': '장',

    // 그램 단위 (육류/해산물)
    '소고기': 'g',
    '돼지고기': 'g',
    '삼겹살': 'g',
    '닭고기': 'g',
    '새우': 'g',
    '오징어': 'g'
  };

  return unitMap[productName] || '개';
}
