// CheckStock Action Handler
// 재고 조회 요청을 처리합니다

const endpoints = require('./endpoints.js');

module.exports.function = function checkStock(productName, $vivContext) {
  // 상품명 정규화
  const normalizedName = normalizeProductName(productName);
  
  // 딥링크 생성하여 앱에서 실제 재고 조회
  const result = endpoints.CheckStock({ productName: normalizedName });
  
  return result;
};

/**
 * 상품명 정규화 (동의어 처리)
 * @param {string} name - 원본 상품명
 * @returns {string} - 정규화된 상품명
 */
function normalizeProductName(name) {
  if (!name) return '';
  
  // 일반적인 동의어 매핑
  const synonymMap = {
    // 버섯류
    '팽이': '팽이버섯',
    '팽이버섯': '팽이버섯',
    '새송이': '새송이버섯',
    '새송이버섯': '새송이버섯',
    '표고': '표고버섯',
    '표고버섯': '표고버섯',
    
    // 채소류
    '양파': '양파',
    '당근': '당근',
    '감자': '감자',
    '대파': '대파',
    '파': '대파',
    '마늘': '마늘',
    '생강': '생강',
    '고추': '고추',
    '청양고추': '청양고추',
    
    // 달걀
    '달걀': '달걀',
    '계란': '달걀',
    '에그': '달걀',
    
    // 육류
    '소고기': '소고기',
    '쇠고기': '소고기',
    '돼지고기': '돼지고기',
    '삼겹살': '삼겹살',
    '닭고기': '닭고기',
    '닭': '닭고기',
    '치킨': '닭고기',
    
    // 해산물
    '새우': '새우',
    '오징어': '오징어',
    '고등어': '고등어',
    '삼치': '삼치',
    
    // 유제품
    '우유': '우유',
    '치즈': '치즈',
    '버터': '버터',
    '요거트': '요거트',
    '요구르트': '요거트',
    
    // 두부류
    '두부': '두부',
    '순두부': '순두부',
    
    // 면류
    '라면': '라면',
    '국수': '국수',
    '파스타': '파스타',
    
    // 조미료
    '간장': '간장',
    '된장': '된장',
    '고추장': '고추장',
    '소금': '소금',
    '설탕': '설탕',
    '식용유': '식용유',
    '참기름': '참기름',
    '들기름': '들기름'
  };
  
  // 이름 정리 (공백 제거, 소문자)
  const cleanName = name.trim();
  
  // 매핑된 이름이 있으면 반환
  if (synonymMap[cleanName]) {
    return synonymMap[cleanName];
  }
  
  // 없으면 원본 반환
  return cleanName;
}
