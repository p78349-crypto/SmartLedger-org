part of 'korean_search_utils.dart';

// ============================================================
// Japanese Thesaurus (シソーラス) - 4文字熟語 & 略語
// ============================================================

const Map<String, List<String>> _japaneseThesaurus = <String, List<String>>{
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

/// Reverse lookup cache: full form → contracted form.
Map<String, String>? _reverseJapaneseThesaurus;

/// Builds the reverse thesaurus on first access.
Map<String, String> get _japaneseReverseMap {
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

const Map<String, String> _hiraKataTable = {
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

Map<String, String>? _kataHiraCache;

Map<String, String> get _kataToHiraMap {
  _kataHiraCache ??= _hiraKataTable.map((k, v) => MapEntry(v, k));
  return _kataHiraCache!;
}
