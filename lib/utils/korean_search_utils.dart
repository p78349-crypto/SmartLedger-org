/// Multilingual text matching utilities.
///
/// Supports:
/// - Korean: Hangul initial consonants (초성) matching
///   Example: query `ㄱㅊ` matches `김치`
/// - English: Prefix search and acronym matching
///   Example: query `Hur` matches `Hurricane`
///   Example: query `FEMA` matches `Federal Emergency Management Agency`
/// - Japanese: 4-mora contraction (4文字熟語) and reading-based prefix
///   Example: query `スマホ` matches `スマートフォン`
///   Example: query `じ` matches `地震`
class MultilingualSearchUtils {
  // ============================================================
  // Korean Constants
  // ============================================================
  static const List<String> _chosung = <String>[
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

  static const Set<String> _compatChosungSet = <String>{
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
  /// Common acronyms mapping for English text.
  /// Maps acronym -> full form for bidirectional matching.
  static const Map<String, String> _commonAcronyms = <String, String>{
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

  // ============================================================
  // Japanese Thesaurus (シソーラス) - 4文字熟語 & 略語
  // ============================================================
  /// Japanese contraction mappings (略語 → 正式名称).
  /// Supports 4-mora contractions and common abbreviations.
  static const Map<String, List<String>> _japaneseThesaurus =
      <String, List<String>>{
        // Technology (テクノロジー)
        'パソコン': ['パーソナルコンピュータ', 'パーソナルコンピューター', 'personal computer'],
        'スマホ': ['スマートフォン', 'スマートホン', 'smartphone'],
        'ガラケー': ['ガラパゴス携帯', 'ガラパゴスけいたい', 'feature phone'],
        'アプリ': ['アプリケーション', 'application'],
        'ネット': ['インターネット', 'internet'],
        'メアド': ['メールアドレス', 'email address'],
        'リモコン': ['リモートコントローラー', 'remote controller'],
        'エアコン': ['エアコンディショナー', 'air conditioner'],
        'デジカメ': ['デジタルカメラ', 'digital camera'],
        'プリクラ': ['プリント倶楽部', 'print club'],

        // Places & Stores (場所・店舗)
        'コンビニ': ['コンビニエンスストア', 'convenience store'],
        'デパート': ['デパートメントストア', 'department store'],
        'スーパー': ['スーパーマーケット', 'supermarket'],
        'ファミレス': ['ファミリーレストラン', 'family restaurant'],
        'ドラッグ': ['ドラッグストア', 'drug store'],
        'カラオケ': ['空オーケストラ', 'karaoke'],

        // Government & Organizations (政府・組織)
        '都庁': ['東京都庁', 'とうきょうとちょう', 'tokyo metropolitan government'],
        '県庁': ['けんちょう', 'prefectural office'],
        '市役所': ['しやくしょ', 'city hall'],
        '区役所': ['くやくしょ', 'ward office'],
        '総務': ['総務省', 'そうむしょう', 'ministry of internal affairs'],
        '経産': ['経済産業省', 'けいざいさんぎょうしょう', 'ministry of economy'],
        '国交': ['国土交通省', 'こくどこうつうしょう', 'ministry of land'],
        '厚労': ['厚生労働省', 'こうせいろうどうしょう', 'ministry of health'],
        '文科': ['文部科学省', 'もんぶかがくしょう', 'ministry of education'],
        '警視庁': ['けいしちょう', 'metropolitan police'],
        '消防': ['消防署', 'しょうぼうしょ', 'fire station'],
        '自衛隊': ['じえいたい', 'self defense force'],

        // Emergency & Disaster (緊急・災害)
        '地震': ['じしん', 'earthquake'],
        '津波': ['つなみ', 'tsunami'],
        '台風': ['たいふう', 'typhoon'],
        '避難所': ['ひなんじょ', 'evacuation shelter'],
        '避難': ['ひなん', 'evacuation'],
        '救急': ['きゅうきゅう', 'emergency', 'ambulance'],
        '救助': ['きゅうじょ', 'rescue'],
        '防災': ['ぼうさい', 'disaster prevention'],
        '緊急': ['きんきゅう', 'emergency'],
        '警報': ['けいほう', 'warning', 'alert'],
        '注意報': ['ちゅういほう', 'advisory'],

        // Transportation (交通)
        '電車': ['でんしゃ', 'train'],
        '新幹線': ['しんかんせん', 'shinkansen', 'bullet train'],
        '地下鉄': ['ちかてつ', 'subway', 'metro'],
        'バス停': ['バスてい', 'bus stop'],
        '空港': ['くうこう', 'airport'],
        '駅前': ['えきまえ', 'station front'],

        // Finance (金融)
        '銀行': ['ぎんこう', 'bank'],
        'ATM': ['エーティーエム', 'atm', 'automated teller machine'],
        '振込': ['ふりこみ', 'bank transfer'],
        '引落': ['ひきおとし', 'direct debit'],
        '口座': ['こうざ', 'account'],
        'クレカ': ['クレジットカード', 'credit card'],
        '電子マネー': ['でんしまねー', 'electronic money'],
        'ペイペイ': ['paypay'],

        // Media (メディア)
        'NHK': ['日本放送協会', 'にほんほうそうきょうかい', 'nippon housou kyoukai'],
        'テレビ': ['テレビジョン', 'television'],
        'ラジオ': ['radio'],
        '新聞': ['しんぶん', 'newspaper'],
        'ニュース': ['news'],
      };

  /// Reverse lookup: full form → contracted form
  static Map<String, String>? _reverseJapaneseThesaurus;

  /// Builds the reverse thesaurus on first access.
  static Map<String, String> get _japaneseReverseMap {
    if (_reverseJapaneseThesaurus == null) {
      _reverseJapaneseThesaurus = <String, String>{};
      for (final entry in _japaneseThesaurus.entries) {
        for (final fullForm in entry.value) {
          _reverseJapaneseThesaurus![fullForm.toLowerCase()] = entry.key;
        }
      }
    }
    return _reverseJapaneseThesaurus!;
  }

  // ============================================================
  // Hiragana ↔ Katakana Conversion Tables
  // ============================================================
  static const Map<String, String> _hiraganaToKatakana = {
    'あ': 'ア',
    'い': 'イ',
    'う': 'ウ',
    'え': 'エ',
    'お': 'オ',
    'か': 'カ',
    'き': 'キ',
    'く': 'ク',
    'け': 'ケ',
    'こ': 'コ',
    'さ': 'サ',
    'し': 'シ',
    'す': 'ス',
    'せ': 'セ',
    'そ': 'ソ',
    'た': 'タ',
    'ち': 'チ',
    'つ': 'ツ',
    'て': 'テ',
    'と': 'ト',
    'な': 'ナ',
    'に': 'ニ',
    'ぬ': 'ヌ',
    'ね': 'ネ',
    'の': 'ノ',
    'は': 'ハ',
    'ひ': 'ヒ',
    'ふ': 'フ',
    'へ': 'ヘ',
    'ほ': 'ホ',
    'ま': 'マ',
    'み': 'ミ',
    'む': 'ム',
    'め': 'メ',
    'も': 'モ',
    'や': 'ヤ',
    'ゆ': 'ユ',
    'よ': 'ヨ',
    'ら': 'ラ',
    'り': 'リ',
    'る': 'ル',
    'れ': 'レ',
    'ろ': 'ロ',
    'わ': 'ワ',
    'を': 'ヲ',
    'ん': 'ン',
    'が': 'ガ',
    'ぎ': 'ギ',
    'ぐ': 'グ',
    'げ': 'ゲ',
    'ご': 'ゴ',
    'ざ': 'ザ',
    'じ': 'ジ',
    'ず': 'ズ',
    'ぜ': 'ゼ',
    'ぞ': 'ゾ',
    'だ': 'ダ',
    'ぢ': 'ヂ',
    'づ': 'ヅ',
    'で': 'デ',
    'ど': 'ド',
    'ば': 'バ',
    'び': 'ビ',
    'ぶ': 'ブ',
    'べ': 'ベ',
    'ぼ': 'ボ',
    'ぱ': 'パ',
    'ぴ': 'ピ',
    'ぷ': 'プ',
    'ぺ': 'ペ',
    'ぽ': 'ポ',
    'ゃ': 'ャ',
    'ゅ': 'ュ',
    'ょ': 'ョ',
    'っ': 'ッ',
    'ー': 'ー',
  };

  static Map<String, String>? _katakanaToHiragana;

  static Map<String, String> get _kataToHiraMap {
    _katakanaToHiragana ??= _hiraganaToKatakana.map((k, v) => MapEntry(v, k));
    return _katakanaToHiragana!;
  }

  // ============================================================
  // European Languages Support (🇪🇺 EU)
  // ============================================================

  /// Articles and prepositions to remove for European languages.
  /// These are filtered out during search indexing.
  static const Map<String, Set<String>> _europeanStopWords = {
    // German (Deutsch)
    'de': {
      'der', 'die', 'das', 'den', 'dem', 'des', // Articles
      'ein', 'eine', 'einer', 'einem', 'einen', // Indefinite articles
      'und', 'oder', 'aber', 'für', 'mit', 'von', 'zu', 'bei', 'nach', 'aus',
      'an', 'auf', 'in', 'im', 'am', // Prepositions
    },
    // French (Français)
    'fr': {
      'le', 'la', 'les', 'l', 'un', 'une', 'des', // Articles
      'de', 'du', 'au', 'aux', // Contracted articles
      'et', 'ou', 'mais', 'pour', 'avec', 'dans', 'sur', 'par', 'en',
      'à', 'ce', 'cette', 'ces', // Prepositions & demonstratives
    },
    // Spanish (Español)
    'es': {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', // Articles
      'de', 'del', 'al', // Contracted articles
      'y', 'o', 'pero', 'para', 'con', 'en', 'por', 'sin',
      'este', 'esta', 'estos', 'estas', // Prepositions & demonstratives
    },
    // Italian (Italiano)
    'it': {
      'il', 'lo', 'la', 'i', 'gli', 'le', 'l', // Articles
      'un', 'uno', 'una', // Indefinite articles
      'di', 'del', 'dello', 'della', 'dei', 'degli', 'delle',
      'a', 'al', 'allo', 'alla', 'ai', 'agli', 'alle',
      'da', 'dal', 'dallo', 'dalla', 'dai', 'dagli', 'dalle',
      'in', 'nel', 'nello', 'nella', 'nei', 'negli', 'nelle',
      'e', 'o', 'ma', 'per', 'con', 'su',
    },
    // Portuguese (Português)
    'pt': {
      'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas', // Articles
      'de', 'do', 'da', 'dos', 'das', // Contracted
      'em', 'no', 'na', 'nos', 'nas',
      'e', 'ou', 'mas', 'para', 'com', 'por', 'sem',
    },
    // Dutch (Nederlands)
    'nl': {
      'de', 'het', 'een', // Articles
      'van', 'voor', 'met', 'op', 'aan', 'in', 'naar', 'bij', 'tot',
      'en', 'of', 'maar',
    },
  };

  /// Common German compound word components for decomposition.
  /// Maps component -> possible full compound patterns.
  static const Map<String, List<String>> _germanCompoundPrefixes = {
    // Emergency (Notfall)
    'evak': ['evakuierung', 'evakuierungssammelstelle', 'evakuierungsplan'],
    'notf': ['notfall', 'notfallplan', 'notfallnummer', 'notfalldienst'],
    'samml': ['sammelstelle', 'sammelpunkt', 'sammelplatz'],
    'flucht': ['fluchtweg', 'fluchtplan', 'fluchttür'],
    'feuer': ['feuerwehr', 'feuerlöscher', 'feuermelder', 'feueralarm'],
    'rett': ['rettung', 'rettungsdienst', 'rettungswagen', 'rettungsstelle'],
    'krank': ['krankenhaus', 'krankenwagen', 'krankenkasse'],

    // Government (Regierung)
    'rat': ['rathaus', 'ratsversammlung'],
    'bürger': ['bürgeramt', 'bürgerbüro', 'bürgermeister', 'bürgerdienst'],
    'finanz': ['finanzamt', 'finanzierung', 'finanzen'],
    'poliz': ['polizei', 'polizeiwache', 'polizeidienst'],
    'stadt': ['stadthaus', 'stadtverwaltung', 'stadtamt'],

    // Transportation (Verkehr)
    'bahn': ['bahnhof', 'bahnsteig', 'bahnlinie', 'autobahn'],
    'flug': ['flughafen', 'flugzeug', 'fluglinie'],
    'haupt': ['hauptbahnhof', 'hauptstraße', 'hauptstadt'],

    // Finance (Finanzen)
    'spar': ['sparkasse', 'sparbuch', 'sparplan'],
    'geld': ['geldautomat', 'geldwechsel', 'geldtransfer'],
    'bank': ['bankfiliale', 'bankkonto', 'banküberweisung'],
    'über': ['überweisung', 'überweisungsformular'],
    'kont': ['konto', 'kontostand', 'kontoauszug'],
  };

  /// European abbreviations mapping (multilingual).
  /// Maps abbreviation -> {language: full form}.
  static const Map<String, Map<String, String>> _europeanAbbreviations = {
    // Emergency Services
    '112': {
      'en': 'emergency call',
      'de': 'notfall notruf',
      'fr': 'urgence appel urgence',
      'es': 'emergencia llamada emergencia',
      'it': 'emergenza chiamata emergenza',
    },
    'polizei': {'de': 'polizei polizeidienst'},
    'feuerwehr': {'de': 'feuerwehr brandbekämpfung'},
    'samu': {'fr': 'service aide médicale urgente'},
    'pompiers': {'fr': 'sapeurs pompiers'},
    'gendarmerie': {'fr': 'gendarmerie nationale'},
    'guardia': {'es': 'guardia civil'},
    'bomberos': {'es': 'cuerpo bomberos'},
    'carabinieri': {'it': 'arma carabinieri'},
    'vigili': {'it': 'vigili del fuoco'},

    // Government Abbreviations
    'mdp': {'fr': 'mairie de paris'},
    'bvg': {'de': 'berliner verkehrsbetriebe'},
    'ratp': {'fr': 'régie autonome transports parisiens'},
    'sncf': {'fr': 'société nationale chemins fer français'},
    'renfe': {'es': 'red nacional ferrocarriles españoles'},
    'db': {'de': 'deutsche bahn'},
    'ns': {'nl': 'nederlandse spoorwegen'},

    // Finance
    'bce': {
      'fr': 'banque centrale européenne',
      'es': 'banco central europeo',
      'it': 'banca centrale europea',
      'pt': 'banco central europeu',
    },
    'ezb': {'de': 'europäische zentralbank'},
    'ecb': {'en': 'european central bank'},
    'iban': {
      'en': 'international bank account number',
      'de': 'internationale bankkontonummer',
      'fr': 'numéro compte bancaire international',
    },
    'bic': {'en': 'bank identifier code', 'de': 'bankidentifikationscode'},
    'sepa': {
      'en': 'single euro payments area',
      'de': 'einheitlicher euro zahlungsverkehrsraum',
      'fr': 'espace unique paiement euros',
    },

    // Healthcare
    'nhs': {'en': 'national health service'},
    'aok': {'de': 'allgemeine ortskrankenkasse'},
    'tk': {'de': 'techniker krankenkasse'},
    'cpam': {'fr': 'caisse primaire assurance maladie'},
    'inps': {'it': 'istituto nazionale previdenza sociale'},
  };

  /// Multilingual emergency code mappings.
  /// Global ID -> {category, language-specific keywords}.
  static const Map<String, Map<String, dynamic>> _globalEmergencyCodes = {
    'EMG_112': {
      'category': 'emergency',
      'security_level': 'low',
      'keywords': {
        'en': ['emergency', 'emer', '112', 'help'],
        'de': ['notfall', 'notf', 'notruf', 'hilfe'],
        'fr': ['urgence', 'urgen', 'secours'],
        'es': ['emergencia', 'emerg', 'socorro'],
        'it': ['emergenza', 'emerg', 'soccorso'],
        'pt': ['emergência', 'emerg', 'socorro'],
        'nl': ['noodgeval', 'nood', 'hulp'],
      },
    },
    'EMG_FIRE': {
      'category': 'fire',
      'security_level': 'low',
      'keywords': {
        'en': ['fire', 'fire department', 'firefighter'],
        'de': ['feuer', 'feuerwehr', 'brand'],
        'fr': ['feu', 'pompier', 'incendie'],
        'es': ['fuego', 'bombero', 'incendio'],
        'it': ['fuoco', 'pompiere', 'incendio'],
      },
    },
    'EMG_POLICE': {
      'category': 'police',
      'security_level': 'low',
      'keywords': {
        'en': ['police', 'cop', 'officer'],
        'de': ['polizei', 'poliz'],
        'fr': ['police', 'gendarmerie'],
        'es': ['policía', 'guardia'],
        'it': ['polizia', 'carabinieri'],
      },
    },
    'EMG_MEDICAL': {
      'category': 'medical',
      'security_level': 'low',
      'keywords': {
        'en': ['ambulance', 'hospital', 'medical', 'doctor'],
        'de': ['krankenwagen', 'krankenhaus', 'arzt', 'krank'],
        'fr': ['ambulance', 'hôpital', 'médecin', 'samu'],
        'es': ['ambulancia', 'hospital', 'médico'],
        'it': ['ambulanza', 'ospedale', 'medico'],
      },
    },
    'EMG_EVAC': {
      'category': 'evacuation',
      'security_level': 'low',
      'keywords': {
        'en': ['evacuation', 'shelter', 'evac'],
        'de': ['evakuierung', 'sammelstelle', 'evak', 'samml'],
        'fr': ['évacuation', 'abri', 'refuge'],
        'es': ['evacuación', 'refugio', 'albergue'],
        'it': ['evacuazione', 'rifugio'],
      },
    },
  };

  // ============================================================
  // Normalization & Detection
  // ============================================================

  /// Returns a normalized string for matching (trim + lower-case).
  static String normalize(String input) => input.trim().toLowerCase();

  /// Returns true if [query] looks like a 초성 query (only compat jamo + spaces).
  static bool isChosungQuery(String query) {
    final q = normalize(query);
    if (q.isEmpty) return false;

    for (final rune in q.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ') continue;
      if (!_compatChosungSet.contains(ch)) return false;
    }
    return true;
  }

  /// Returns true if [query] looks like an English-only query (ASCII letters/numbers/spaces).
  static bool isEnglishQuery(String query) {
    final q = normalize(query);
    if (q.isEmpty) return false;

    // Check if all characters are ASCII letters, numbers, spaces, or common punctuation
    return RegExp(r'^[a-z0-9\s\-&]+$').hasMatch(q);
  }

  /// Returns true if [query] looks like an acronym (2-6 uppercase letters).
  static bool isAcronymQuery(String query) {
    final q = query.trim();
    if (q.isEmpty || q.length < 2 || q.length > 6) return false;

    // Pure uppercase letters (possibly with & for things like R&D)
    return RegExp(r'^[A-Z&]+$').hasMatch(q);
  }

  /// Returns true if [text] contains Japanese characters (Hiragana, Katakana, or Kanji).
  static bool containsJapanese(String text) {
    for (final rune in text.runes) {
      // Hiragana: 3040-309F
      if (rune >= 0x3040 && rune <= 0x309F) return true;
      // Katakana: 30A0-30FF
      if (rune >= 0x30A0 && rune <= 0x30FF) return true;
      // CJK Unified Ideographs (Kanji): 4E00-9FFF
      if (rune >= 0x4E00 && rune <= 0x9FFF) return true;
      // Katakana Phonetic Extensions: 31F0-31FF
      if (rune >= 0x31F0 && rune <= 0x31FF) return true;
      // Half-width Katakana: FF65-FF9F
      if (rune >= 0xFF65 && rune <= 0xFF9F) return true;
    }
    return false;
  }

  /// Returns true if [text] is primarily Hiragana.
  static bool isHiragana(String text) {
    if (text.isEmpty) return false;
    for (final rune in text.runes) {
      if (rune >= 0x3040 && rune <= 0x309F) continue;
      if (rune == 0x30FC) continue; // Long vowel mark
      if (rune == 0x0020) continue; // Space
      return false;
    }
    return true;
  }

  /// Returns true if [text] is primarily Katakana.
  static bool isKatakana(String text) {
    if (text.isEmpty) return false;
    for (final rune in text.runes) {
      if (rune >= 0x30A0 && rune <= 0x30FF) continue;
      if (rune == 0x0020) continue; // Space
      return false;
    }
    return true;
  }

  // ============================================================
  // Korean: 초성 Extraction
  // ============================================================

  /// Extracts a 초성 string from Hangul syllables in [text].
  ///
  /// Non-Hangul characters are preserved as-is (lowercased by caller if desired).
  static String extractChosung(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final code = rune;
      // Hangul syllables: AC00-D7A3
      if (code >= 0xAC00 && code <= 0xD7A3) {
        final sIndex = code - 0xAC00;
        final lIndex = sIndex ~/ (21 * 28);
        buffer.write(_chosung[lIndex]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  // ============================================================
  // English: Acronym Extraction
  // ============================================================

  /// Extracts an acronym from multi-word English text.
  ///
  /// Takes the first letter of each word.
  /// Example: "Federal Emergency Management Agency" → "fema"
  static String extractAcronym(String text) {
    final words = normalize(text).split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final word in words) {
      if (word.isNotEmpty) {
        // Skip common small words for better acronym matching
        if (_isStopWord(word)) continue;
        buffer.write(word[0]);
      }
    }
    return buffer.toString();
  }

  /// Common stop words to skip in acronym extraction.
  static bool _isStopWord(String word) {
    const stopWords = {
      'a',
      'an',
      'the',
      'of',
      'and',
      'or',
      'to',
      'for',
      'in',
      'on',
      'at',
      'by',
    };
    return stopWords.contains(word.toLowerCase());
  }

  // ============================================================
  // Japanese: Kana Conversion & Thesaurus
  // ============================================================

  /// Converts Hiragana to Katakana.
  static String hiraganaToKatakana(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_hiraganaToKatakana[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Converts Katakana to Hiragana.
  static String katakanaToHiragana(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_kataToHiraMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Normalizes Japanese text for comparison.
  /// Converts all kana to Hiragana for consistent matching.
  static String normalizeJapanese(String text) {
    return katakanaToHiragana(text.trim());
  }

  /// Looks up a Japanese contraction in the thesaurus.
  /// Returns the list of full forms if found, null otherwise.
  static List<String>? lookupJapaneseContraction(String query) {
    // Try direct lookup
    if (_japaneseThesaurus.containsKey(query)) {
      return _japaneseThesaurus[query];
    }

    // Try with Katakana conversion
    final katakana = hiraganaToKatakana(query);
    if (_japaneseThesaurus.containsKey(katakana)) {
      return _japaneseThesaurus[katakana];
    }

    // Try with Hiragana conversion
    final hiragana = katakanaToHiragana(query);
    for (final entry in _japaneseThesaurus.entries) {
      if (katakanaToHiragana(entry.key) == hiragana) {
        return entry.value;
      }
    }

    return null;
  }

  /// Looks up a full form and returns its contracted form.
  static String? lookupJapaneseFullForm(String fullForm) {
    final normalized = fullForm.toLowerCase();
    return _japaneseReverseMap[normalized];
  }

  // ============================================================
  // Matching Functions
  // ============================================================

  /// Checks if [text] starts with [prefix] (case-insensitive).
  ///
  /// This is the English equivalent of 초성 matching.
  /// Example: "Hurricane" matches prefix "Hur"
  static bool matchesPrefix(String text, String prefix) {
    final t = normalize(text);
    final p = normalize(prefix);
    if (p.isEmpty) return true;

    // Check if any word in the text starts with the prefix
    final words = t.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith(p)) return true;
    }
    return false;
  }

  /// Checks if [text] matches the acronym [query].
  ///
  /// Works bidirectionally:
  /// - "FEMA" query matches "Federal Emergency Management Agency"
  /// - "Federal Emergency Management Agency" matches if query is "fema"
  static bool matchesAcronym(String text, String query) {
    final t = normalize(text);
    final q = normalize(query);
    if (q.isEmpty) return true;

    // Direct acronym in text
    if (t.contains(q)) return true;

    // Check if query is a known acronym and text contains its expansion
    if (_commonAcronyms.containsKey(q)) {
      final expansion = _commonAcronyms[q]!;
      if (t.contains(expansion)) return true;
    }

    // Check if text contains a known acronym that matches query expansion
    for (final entry in _commonAcronyms.entries) {
      if (t.contains(entry.value) && entry.key == q) {
        return true;
      }
    }

    // Extract acronym from text and compare
    final textAcronym = extractAcronym(t);
    if (textAcronym == q || textAcronym.contains(q)) return true;

    // Also try matching the query against individual words' first letters
    final words = t.split(RegExp(r'\s+'));
    if (words.length >= q.length) {
      final buffer = StringBuffer();
      for (var i = 0; i < words.length && buffer.length < q.length; i++) {
        if (words[i].isNotEmpty && !_isStopWord(words[i])) {
          buffer.write(words[i][0]);
        }
      }
      if (buffer.toString() == q) return true;
    }

    return false;
  }

  /// Checks if [text] matches the Japanese [query] using thesaurus and prefix.
  ///
  /// Supports:
  /// - 4-mora contractions: スマホ → スマートフォン
  /// - Kana prefix: じ → 地震
  /// - Hiragana ↔ Katakana equivalence
  static bool matchesJapanese(String text, String query) {
    final t = text.trim();
    final q = query.trim();
    if (q.isEmpty) return true;

    // 1. Direct match (case-insensitive for mixed content)
    if (t.toLowerCase().contains(q.toLowerCase())) return true;

    // 2. Kana-normalized match (ひらがな ↔ カタカナ)
    final tNorm = normalizeJapanese(t);
    final qNorm = normalizeJapanese(q);
    if (tNorm.contains(qNorm)) return true;

    // 3. Thesaurus lookup: query is contraction, text has full form
    final fullForms = lookupJapaneseContraction(q);
    if (fullForms != null) {
      for (final form in fullForms) {
        if (t.toLowerCase().contains(form.toLowerCase())) return true;
        if (tNorm.contains(normalizeJapanese(form))) return true;
      }
    }

    // 4. Reverse thesaurus: query is full form, text has contraction
    final contraction = lookupJapaneseFullForm(q);
    if (contraction != null) {
      if (t.contains(contraction)) return true;
      if (tNorm.contains(normalizeJapanese(contraction))) return true;
    }

    // 5. Check if text contains any thesaurus entry that matches query
    for (final entry in _japaneseThesaurus.entries) {
      // Check if query matches any full form
      for (final form in entry.value) {
        if (qNorm == normalizeJapanese(form) ||
            q.toLowerCase() == form.toLowerCase()) {
          // Query is a full form, check if text has the contraction
          if (t.contains(entry.key) ||
              tNorm.contains(normalizeJapanese(entry.key))) {
            return true;
          }
        }
      }
    }

    // 6. Prefix match for Hiragana input (reading-based search)
    if (isHiragana(q)) {
      // Check thesaurus readings
      for (final entry in _japaneseThesaurus.entries) {
        for (final form in entry.value) {
          final formHira = normalizeJapanese(form);
          if (formHira.startsWith(qNorm)) {
            if (t.contains(entry.key)) return true;
            // Also check if text contains the kanji form directly
            for (final f in entry.value) {
              if (t.contains(f)) return true;
            }
          }
        }
        // Also check the key itself
        if (normalizeJapanese(entry.key).startsWith(qNorm) &&
            t.contains(entry.key)) {
          return true;
        }
      }
    }

    return false;
  }

  // ============================================================
  // European Languages: Compound Decomposition & Article Removal
  // ============================================================

  /// Detects if text contains European language characters (accented Latin).
  static bool containsEuropeanAccents(String text) {
    // Common European accented characters
    return RegExp(
      r'[àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿßœ]',
      caseSensitive: false,
    ).hasMatch(text);
  }

  /// Removes articles and common prepositions from European text.
  ///
  /// Example: "Mairie de Paris" → "Mairie Paris"
  static String removeEuropeanArticles(String text, {String? language}) {
    final result = normalize(text);

    // Determine which stop words to use
    Set<String> stopWords;
    if (language != null && _europeanStopWords.containsKey(language)) {
      stopWords = _europeanStopWords[language]!;
    } else {
      // Use all European stop words if language not specified
      stopWords = _europeanStopWords.values.expand((s) => s).toSet();
    }

    // Split, filter, rejoin
    final words = result.split(RegExp(r'\s+'));
    final filtered = words.where((w) => !stopWords.contains(w)).toList();

    return filtered.join(' ');
  }

  /// Decomposes a German compound word and extracts searchable components.
  ///
  /// Example: "Evakuierungssammelstelle" → ["evak", "samml", "stelle"]
  static List<String> decomposeGermanCompound(String word) {
    final w = normalize(word);
    final components = <String>[];

    // Check known prefixes
    for (final entry in _germanCompoundPrefixes.entries) {
      if (w.startsWith(entry.key) || w.contains(entry.key)) {
        components.add(entry.key);
      }
    }

    // If no known components found, try syllable-based decomposition
    if (components.isEmpty && w.length > 6) {
      // Extract potential compound boundaries (common German patterns)
      final patterns = [
        RegExp(r'(ungs?)(?=[a-zäöü])'), // -ung(s)- boundary
        RegExp(r'(heit|keit)(?=[a-zäöü])'), // -heit/-keit boundary
        RegExp(r'(schaft)(?=[a-zäöü])'), // -schaft boundary
        RegExp(r'(stelle|platz|haus|amt|hof)'), // Common suffixes
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(w);
        if (match != null) {
          // Add prefix before the boundary
          if (match.start > 2) {
            components.add(w.substring(0, match.start));
          }
        }
      }
    }

    // Always include the first 4-5 characters as a prefix
    if (w.length >= 4) {
      final shortPrefix = w.substring(0, 4);
      if (!components.contains(shortPrefix)) {
        components.insert(0, shortPrefix);
      }
    }

    return components;
  }

  /// Checks if [text] matches a German compound word query.
  ///
  /// Example: "Evak" matches "Evakuierungssammelstelle"
  static bool matchesGermanCompound(String text, String query) {
    final t = normalize(text);
    final q = normalize(query);
    if (q.isEmpty) return true;

    // Direct match
    if (t.contains(q)) return true;

    // Check compound decomposition
    final words = t.split(RegExp(r'\s+'));
    for (final word in words) {
      // Check if query matches known prefix patterns
      for (final entry in _germanCompoundPrefixes.entries) {
        if (q == entry.key || q.startsWith(entry.key)) {
          for (final compound in entry.value) {
            if (word.contains(compound) || compound.contains(word)) {
              return true;
            }
          }
        }
      }

      // Check if word starts with query (prefix matching)
      if (word.startsWith(q)) return true;

      // Check decomposed components
      final components = decomposeGermanCompound(word);
      for (final comp in components) {
        if (comp.startsWith(q) || q.startsWith(comp)) return true;
      }
    }

    return false;
  }

  /// Checks if [text] matches a European abbreviation/acronym.
  ///
  /// Supports multilingual abbreviation lookup.
  static bool matchesEuropeanAbbreviation(String text, String query) {
    final t = normalize(text);
    final q = normalize(query);
    if (q.isEmpty) return true;

    // Direct match
    if (t.contains(q)) return true;

    // Check European abbreviations
    if (_europeanAbbreviations.containsKey(q)) {
      final expansions = _europeanAbbreviations[q]!;
      for (final expansion in expansions.values) {
        if (t.contains(expansion)) return true;
        // Also check individual words from expansion
        final words = expansion.split(' ');
        if (words.every(t.contains)) return true;
      }
    }

    // Reverse lookup: check if text contains an abbreviation that matches query
    for (final entry in _europeanAbbreviations.entries) {
      for (final expansion in entry.value.values) {
        if (expansion.contains(q) && t.contains(entry.key)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Checks if [query] matches a global emergency code.
  ///
  /// Returns the matched global ID if found, null otherwise.
  static String? matchesGlobalEmergencyCode(String query) {
    final q = normalize(query);
    if (q.isEmpty) return null;

    for (final entry in _globalEmergencyCodes.entries) {
      final keywords = entry.value['keywords'] as Map<String, List<String>>;
      for (final langKeywords in keywords.values) {
        for (final keyword in langKeywords) {
          if (keyword.startsWith(q) || q.startsWith(keyword) || keyword == q) {
            return entry.key;
          }
        }
      }
    }

    return null;
  }

  /// Gets all keywords for a global emergency code.
  static List<String> getEmergencyCodeKeywords(
    String globalId, {
    String? language,
  }) {
    if (!_globalEmergencyCodes.containsKey(globalId)) return [];

    final keywords =
        _globalEmergencyCodes[globalId]!['keywords']
            as Map<String, List<String>>;

    if (language != null && keywords.containsKey(language)) {
      return keywords[language]!;
    }

    // Return all keywords if no language specified
    return keywords.values.expand((list) => list).toList();
  }

  /// Comprehensive European text matching.
  ///
  /// Supports:
  /// - German compound word decomposition
  /// - French/Spanish/Italian article removal
  /// - Multilingual abbreviation lookup
  /// - Pan-European emergency code matching
  static bool matchesEuropean(String text, String query) {
    final t = normalize(text);
    final q = normalize(query);
    if (q.isEmpty) return true;

    // 1. Direct substring match
    if (t.contains(q)) return true;

    // 2. Match with articles removed
    final tNoArticles = removeEuropeanArticles(text);
    if (tNoArticles.contains(q)) return true;

    // 3. German compound matching
    if (matchesGermanCompound(t, q)) return true;

    // 4. European abbreviation matching
    if (matchesEuropeanAbbreviation(t, q)) return true;

    // 5. Global emergency code matching
    final emergencyId = matchesGlobalEmergencyCode(q);
    if (emergencyId != null) {
      final allKeywords = getEmergencyCodeKeywords(emergencyId);
      for (final keyword in allKeywords) {
        if (t.contains(keyword)) return true;
      }
    }

    // 6. Prefix matching for any word
    final words = t.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith(q)) return true;
    }

    return false;
  }

  // ============================================================
  // Main Matching Functions
  // ============================================================

  /// Flexible match supporting multiple languages and search styles:
  ///
  /// **Korean (한국어):**
  /// - Normal substring match (case-insensitive)
  /// - 초성 matching: `ㄱㅊ` matches `김치`
  ///
  /// **English:**
  /// - Prefix search: `Hur` matches `Hurricane`
  /// - Acronym matching: `FEMA` matches `Federal Emergency Management Agency`
  /// - Substring match (case-insensitive)
  ///
  /// **Japanese (日本語):**
  /// - 4-mora contraction: `スマホ` matches `スマートフォン`
  /// - Kana prefix: `じ` matches `地震`
  /// - Hiragana ↔ Katakana equivalence
  ///
  /// **European (🇪🇺 EU):**
  /// - German compound decomposition: `Evak` matches `Evakuierungssammelstelle`
  /// - Article removal: `Pari` matches `Mairie de Paris`
  /// - Multilingual abbreviations: `MdP` matches `Mairie de Paris`
  /// - Pan-European emergency codes: `Urgen` matches `Urgence` (FR) / `Notfall` (DE)
  static bool matches(String text, String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;

    final t = normalize(text);

    // 1. Direct substring match (works for all languages)
    if (t.contains(q)) return true;

    // 2. Korean 초성 matching
    if (isChosungQuery(q)) {
      final qNoSpace = q.replaceAll(RegExp(r'\s+'), '');
      final chosungNoSpace = extractChosung(t).replaceAll(RegExp(r'\s+'), '');
      if (chosungNoSpace.contains(qNoSpace)) return true;
    }

    // 3. English prefix search (word-start matching)
    if (isEnglishQuery(q) && matchesPrefix(t, q)) {
      return true;
    }

    // 4. Acronym matching (for uppercase queries or known acronyms)
    if (isAcronymQuery(query) || _commonAcronyms.containsKey(q)) {
      if (matchesAcronym(t, q)) return true;
    }

    // 5. Japanese matching (thesaurus + kana conversion)
    if (containsJapanese(query) || containsJapanese(text)) {
      if (matchesJapanese(text, query)) return true;
    }

    // 6. European matching (compound words, articles, abbreviations)
    if (matchesEuropean(text, query)) return true;

    return false;
  }

  /// Enhanced search with ranking support.
  ///
  /// Returns a score indicating match quality:
  /// - 100: Exact match
  /// - 90: Starts with query
  /// - 80: Word starts with query (prefix match)
  /// - 78: German compound match
  /// - 76: European abbreviation match
  /// - 75: Japanese thesaurus match (contraction ↔ full form)
  /// - 74: Pan-European emergency code match
  /// - 70: Acronym match
  /// - 60: 초성 match
  /// - 55: Japanese kana prefix match
  /// - 52: European article-removed match
  /// - 50: Contains query (substring)
  /// - 0: No match
  static int matchScore(String text, String query) {
    final q = normalize(query);
    if (q.isEmpty) return 100;

    final t = normalize(text);

    // Exact match
    if (t == q) return 100;

    // Starts with query
    if (t.startsWith(q)) return 90;

    // Word-start prefix match
    if (isEnglishQuery(q) && matchesPrefix(t, q)) return 80;

    // German compound match
    if (matchesGermanCompound(t, q) && !t.contains(q)) return 78;

    // European abbreviation match
    if (_europeanAbbreviations.containsKey(q)) {
      if (matchesEuropeanAbbreviation(t, q)) return 76;
    }

    // Japanese thesaurus match
    if (containsJapanese(query) || containsJapanese(text)) {
      final fullForms = lookupJapaneseContraction(query);
      if (fullForms != null) {
        for (final form in fullForms) {
          if (t.contains(form.toLowerCase()) ||
              normalizeJapanese(text).contains(normalizeJapanese(form))) {
            return 75;
          }
        }
      }
      // Kana-normalized exact or prefix match
      final tNorm = normalizeJapanese(text);
      final qNorm = normalizeJapanese(query);
      if (tNorm.startsWith(qNorm)) return 75;
      if (isHiragana(query.trim()) && matchesJapanese(text, query)) return 55;
    }

    // Pan-European emergency code match
    final emergencyId = matchesGlobalEmergencyCode(q);
    if (emergencyId != null) {
      final allKeywords = getEmergencyCodeKeywords(emergencyId);
      for (final keyword in allKeywords) {
        if (t.contains(keyword)) return 74;
      }
    }

    // Acronym match
    if ((isAcronymQuery(query) || _commonAcronyms.containsKey(q)) &&
        matchesAcronym(t, q)) {
      return 70;
    }

    // 초성 match
    if (isChosungQuery(q)) {
      final qNoSpace = q.replaceAll(RegExp(r'\s+'), '');
      final chosungNoSpace = extractChosung(t).replaceAll(RegExp(r'\s+'), '');
      if (chosungNoSpace.contains(qNoSpace)) return 60;
    }

    // European article-removed match
    final tNoArticles = removeEuropeanArticles(text);
    if (tNoArticles.contains(q) && !t.contains(q)) return 52;

    // Substring match
    if (t.contains(q)) return 50;

    // Japanese substring with kana conversion
    if (containsJapanese(query) || containsJapanese(text)) {
      if (normalizeJapanese(text).contains(normalizeJapanese(query))) return 50;
    }

    // European fallback match
    if (matchesEuropean(text, query)) return 45;

    return 0;
  }

  /// Sort a list of items by match relevance.
  ///
  /// Higher scores appear first.
  static List<T> sortByRelevance<T>(
    List<T> items,
    String query,
    String Function(T) textExtractor,
  ) {
    if (query.trim().isEmpty) return items;

    final scored =
        items
            .map(
              (item) => MapEntry(item, matchScore(textExtractor(item), query)),
            )
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }
}

/// Backward-compatible alias for existing code.
/// @deprecated Use [MultilingualSearchUtils] instead.
typedef KoreanSearchUtils = MultilingualSearchUtils;
