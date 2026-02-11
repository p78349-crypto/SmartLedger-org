part of 'korean_search_utils.dart';

// ============================================================
// Korean Constants
// ============================================================

const List<String> _chosung = <String>[
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

const Set<String> _compatChosungSet = <String>{
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
};

// ============================================================
// English Acronyms
// ============================================================

const Map<String, String> _commonAcronyms = <String, String>{
  // Finance & Banking
  'atm': 'automated teller machine',
  'apr': 'annual percentage rate',
  'apy': 'annual percentage yield',
  'ira': 'individual retirement account',
  'etf': 'exchange traded fund',
  'roi': 'return on investment',
  'fico': 'fair isaac corporation',
  'fdic': 'federal deposit insurance corporation',
  'sec': 'securities and exchange commission',
  'ipo': 'initial public offering',
  'cfo': 'chief financial officer',
  'ceo': 'chief executive officer',

  // Emergency & Government
  'fema': 'federal emergency management agency',
  'eoc': 'emergency operations center',
  'ems': 'emergency medical services',
  'dhs': 'department of homeland security',
  'cdc': 'centers for disease control',
  'fbi': 'federal bureau of investigation',
  'irs': 'internal revenue service',
  'ssn': 'social security number',
  'dmv': 'department of motor vehicles',

  // Common Business
  'pos': 'point of sale',
  'crm': 'customer relationship management',
  'erp': 'enterprise resource planning',
  'hr': 'human resources',
  'it': 'information technology',
  'pr': 'public relations',
  'qa': 'quality assurance',
  'r&d': 'research and development',
  'b2b': 'business to business',
  'b2c': 'business to consumer',

  // Shopping & Retail
  'bogo': 'buy one get one',
  'msrp': 'manufacturer suggested retail price',
  'upc': 'universal product code',
  'sku': 'stock keeping unit',

  // Utilities & Bills
  'hvac': 'heating ventilation air conditioning',
  'led': 'light emitting diode',
  'kwh': 'kilowatt hour',
  'ac': 'air conditioning',
};
