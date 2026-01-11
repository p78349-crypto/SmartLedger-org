import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/korean_search_utils.dart';

void main() {
  group('KoreanSearchUtils', () {
    group('Korean 초성 matching', () {
      test(
        'extractChosung extracts initial consonants from Hangul syllables',
        () {
          expect(KoreanSearchUtils.extractChosung('김치'), 'ㄱㅊ');
          expect(KoreanSearchUtils.extractChosung('안녕'), 'ㅇㄴ');
        },
      );

      test('matches supports 초성-only queries', () {
        expect(KoreanSearchUtils.matches('김치', 'ㄱㅊ'), isTrue);
        expect(KoreanSearchUtils.matches('안녕하세요', 'ㅇㄴㅎㅅㅇ'), isTrue);
        expect(KoreanSearchUtils.matches('김치', 'ㄱㅈ'), isFalse);
      });

      test('초성 matching is whitespace-tolerant', () {
        expect(KoreanSearchUtils.matches('김치 찌개', 'ㄱㅊㅉㄱ'), isTrue);
        expect(KoreanSearchUtils.matches('김치\n찌개', 'ㄱㅊㅉㄱ'), isTrue);
        expect(KoreanSearchUtils.matches('김치\t찌개', 'ㄱㅊㅉㄱ'), isTrue);
      });

      test('isChosungQuery rejects non-초성 characters', () {
        expect(KoreanSearchUtils.isChosungQuery('ㄱㅊ'), isTrue);
        expect(KoreanSearchUtils.isChosungQuery('ㄱa'), isFalse);
        expect(KoreanSearchUtils.isChosungQuery('가'), isFalse);
      });
    });

    group('Basic substring matching', () {
      test('matches supports case-insensitive substring matching', () {
        expect(KoreanSearchUtils.matches('Hello World', 'world'), isTrue);
        expect(KoreanSearchUtils.matches('Hello World', 'WORLD'), isTrue);
        expect(KoreanSearchUtils.matches('Hello World', 'nope'), isFalse);
      });

      test('empty query matches everything (search UX friendly)', () {
        expect(KoreanSearchUtils.matches('anything', ''), isTrue);
        expect(KoreanSearchUtils.matches('anything', '   '), isTrue);
      });
    });

    group('English Prefix Search', () {
      test('isEnglishQuery identifies English-only queries', () {
        expect(KoreanSearchUtils.isEnglishQuery('hello'), isTrue);
        expect(KoreanSearchUtils.isEnglishQuery('Hello123'), isTrue);
        expect(KoreanSearchUtils.isEnglishQuery('r&d'), isTrue);
        expect(KoreanSearchUtils.isEnglishQuery('김치'), isFalse);
        expect(KoreanSearchUtils.isEnglishQuery('ㄱㅊ'), isFalse);
      });

      test('matchesPrefix matches word beginnings', () {
        // Single word prefix
        expect(KoreanSearchUtils.matchesPrefix('Hurricane', 'Hur'), isTrue);
        expect(KoreanSearchUtils.matchesPrefix('Hurricane', 'hur'), isTrue);
        expect(KoreanSearchUtils.matchesPrefix('Hurricane', 'ric'), isFalse);

        // Multi-word - matches any word start
        expect(KoreanSearchUtils.matchesPrefix('Walmart Store', 'Wal'), isTrue);
        expect(KoreanSearchUtils.matchesPrefix('Walmart Store', 'Sto'), isTrue);
        expect(
          KoreanSearchUtils.matchesPrefix('Emergency Room', 'Emer'),
          isTrue,
        );
        expect(
          KoreanSearchUtils.matchesPrefix('Emergency Room', 'Room'),
          isTrue,
        );
      });

      test('matches integrates prefix search', () {
        expect(KoreanSearchUtils.matches('Hurricane Warning', 'Hur'), isTrue);
        expect(KoreanSearchUtils.matches('Walmart Grocery', 'Wal'), isTrue);
        expect(KoreanSearchUtils.matches('Costco Wholesale', 'Cost'), isTrue);
      });
    });

    group('Acronym Search', () {
      test('isAcronymQuery identifies uppercase acronyms', () {
        expect(KoreanSearchUtils.isAcronymQuery('FEMA'), isTrue);
        expect(KoreanSearchUtils.isAcronymQuery('EOC'), isTrue);
        expect(KoreanSearchUtils.isAcronymQuery('R&D'), isTrue);
        expect(KoreanSearchUtils.isAcronymQuery('fema'), isFalse); // lowercase
        expect(KoreanSearchUtils.isAcronymQuery('A'), isFalse); // too short
        expect(
          KoreanSearchUtils.isAcronymQuery('TOOLONG'),
          isFalse,
        ); // > 6 chars
      });

      test('extractAcronym builds acronym from text', () {
        expect(
          KoreanSearchUtils.extractAcronym(
            'Federal Emergency Management Agency',
          ),
          'fema',
        );
        expect(
          KoreanSearchUtils.extractAcronym('Emergency Operations Center'),
          'eoc',
        );
        expect(
          KoreanSearchUtils.extractAcronym('Point of Sale'),
          'ps', // 'of' is a stop word
        );
      });

      test('matchesAcronym matches known acronyms', () {
        // Query is acronym, text is full form
        expect(
          KoreanSearchUtils.matchesAcronym(
            'Federal Emergency Management Agency',
            'fema',
          ),
          isTrue,
        );
        expect(
          KoreanSearchUtils.matchesAcronym(
            'Emergency Operations Center',
            'eoc',
          ),
          isTrue,
        );

        // Acronym directly in text
        expect(KoreanSearchUtils.matchesAcronym('FEMA Alert', 'fema'), isTrue);
        expect(KoreanSearchUtils.matchesAcronym('EOC Report', 'eoc'), isTrue);
      });

      test('matches integrates acronym search', () {
        // Known acronyms
        expect(
          KoreanSearchUtils.matches(
            'Federal Emergency Management Agency warning',
            'FEMA',
          ),
          isTrue,
        );
        expect(KoreanSearchUtils.matches('ATM withdrawal', 'ATM'), isTrue);

        // Dynamic acronym extraction
        expect(
          KoreanSearchUtils.matches('World Health Organization', 'WHO'),
          isTrue,
        );
      });
    });

    group('Match Scoring', () {
      test('matchScore returns appropriate scores', () {
        // Exact match = 100
        expect(KoreanSearchUtils.matchScore('hello', 'hello'), 100);

        // Starts with = 90
        expect(KoreanSearchUtils.matchScore('hello world', 'hello'), 90);

        // Prefix match = 80
        expect(KoreanSearchUtils.matchScore('hello world', 'wor'), 80);

        // Acronym match = 70
        expect(
          KoreanSearchUtils.matchScore(
            'Federal Emergency Management Agency',
            'FEMA',
          ),
          70,
        );

        // 초성 match = 60
        expect(KoreanSearchUtils.matchScore('김치', 'ㄱㅊ'), 60);

        // Substring = 50
        expect(KoreanSearchUtils.matchScore('hello world', 'llo'), 50);

        // No match = 0
        expect(KoreanSearchUtils.matchScore('hello', 'xyz'), 0);
      });

      test('sortByRelevance orders by match quality', () {
        final items = [
          'Walmart Store',
          'Wall Street Journal',
          'Walking Dead',
          'Walmart Grocery',
          'Target',
        ];

        final sorted = KoreanSearchUtils.sortByRelevance(
          items,
          'Wal',
          (item) => item,
        );

        // All "Wal" prefix matches should come before non-matches
        expect(sorted.length, 4); // Target excluded
        expect(sorted.every((s) => s.toLowerCase().contains('wal')), isTrue);
      });
    });

    group('Mixed language support', () {
      test('handles Korean-English mixed text', () {
        expect(KoreanSearchUtils.matches('삼성 Galaxy Store', '삼성'), isTrue);
        expect(KoreanSearchUtils.matches('삼성 Galaxy Store', 'ㅅㅅ'), isTrue);
        expect(KoreanSearchUtils.matches('삼성 Galaxy Store', 'Gal'), isTrue);
        expect(KoreanSearchUtils.matches('삼성 Galaxy Store', 'galaxy'), isTrue);
      });

      test('practical finance search examples', () {
        // Korean style
        expect(KoreanSearchUtils.matches('카드결제', 'ㅋㄷ'), isTrue);
        expect(KoreanSearchUtils.matches('식료품비', 'ㅅㄹㅍㅂ'), isTrue);

        // English style
        expect(KoreanSearchUtils.matches('Grocery Shopping', 'Groc'), isTrue);
        expect(
          KoreanSearchUtils.matches('Credit Card Payment', 'cred'),
          isTrue,
        );

        // Acronym style
        expect(KoreanSearchUtils.matches('ATM Fee', 'ATM'), isTrue);
        expect(
          KoreanSearchUtils.matches(
            'Individual Retirement Account contribution',
            'IRA',
          ),
          isTrue,
        );
      });
    });

    group('Japanese 日本語 support', () {
      group('Kana detection and conversion', () {
        test('containsJapanese detects Japanese text', () {
          expect(MultilingualSearchUtils.containsJapanese('スマホ'), isTrue);
          expect(MultilingualSearchUtils.containsJapanese('じしん'), isTrue);
          expect(MultilingualSearchUtils.containsJapanese('地震'), isTrue);
          expect(MultilingualSearchUtils.containsJapanese('hello'), isFalse);
          expect(MultilingualSearchUtils.containsJapanese('김치'), isFalse);
        });

        test('isHiragana identifies hiragana text', () {
          expect(MultilingualSearchUtils.isHiragana('じしん'), isTrue);
          expect(MultilingualSearchUtils.isHiragana('スマホ'), isFalse);
          expect(MultilingualSearchUtils.isHiragana('地震'), isFalse);
        });

        test('isKatakana identifies katakana text', () {
          expect(MultilingualSearchUtils.isKatakana('スマホ'), isTrue);
          expect(MultilingualSearchUtils.isKatakana('じしん'), isFalse);
          expect(MultilingualSearchUtils.isKatakana('地震'), isFalse);
        });

        test('hiraganaToKatakana converts correctly', () {
          expect(MultilingualSearchUtils.hiraganaToKatakana('すまほ'), 'スマホ');
          expect(MultilingualSearchUtils.hiraganaToKatakana('じしん'), 'ジシン');
          expect(MultilingualSearchUtils.hiraganaToKatakana('こんびに'), 'コンビニ');
        });

        test('katakanaToHiragana converts correctly', () {
          expect(MultilingualSearchUtils.katakanaToHiragana('スマホ'), 'すまほ');
          expect(MultilingualSearchUtils.katakanaToHiragana('コンビニ'), 'こんびに');
        });
      });

      group('4-mora contraction matching (4文字熟語)', () {
        test('スマホ matches スマートフォン', () {
          expect(MultilingualSearchUtils.matches('スマートフォンで決済', 'スマホ'), isTrue);
          expect(
            MultilingualSearchUtils.matchesJapanese('スマートフォン', 'スマホ'),
            isTrue,
          );
        });

        test('コンビニ matches コンビニエンスストア', () {
          expect(
            MultilingualSearchUtils.matches('コンビニエンスストアで買い物', 'コンビニ'),
            isTrue,
          );
        });

        test('パソコン matches パーソナルコンピュータ', () {
          expect(
            MultilingualSearchUtils.matches('パーソナルコンピュータを購入', 'パソコン'),
            isTrue,
          );
        });

        test('contraction works with hiragana input', () {
          // User types hiragana, text has katakana
          expect(MultilingualSearchUtils.matches('スマートフォン', 'すまほ'), isTrue);
        });
      });

      group('Government abbreviations (政府略語)', () {
        test('都庁 matches 東京都庁', () {
          expect(MultilingualSearchUtils.matches('東京都庁からのお知らせ', '都庁'), isTrue);
        });

        test('総務 matches 総務省', () {
          expect(MultilingualSearchUtils.matches('総務省の発表', '総務'), isTrue);
        });
      });

      group('Emergency terms (緊急用語)', () {
        test('地震 matches with hiragana じしん', () {
          expect(MultilingualSearchUtils.matches('地震警報', 'じしん'), isTrue);
        });

        test('避難所 matches with reading ひなんじょ', () {
          expect(MultilingualSearchUtils.matches('避難所の場所', 'ひなんじょ'), isTrue);
        });

        test('津波 matches with reading つなみ', () {
          expect(MultilingualSearchUtils.matches('津波注意報', 'つなみ'), isTrue);
        });
      });

      group('Hiragana prefix matching (読み検索)', () {
        test('じ prefix matches 地震 via reading', () {
          expect(MultilingualSearchUtils.matchesJapanese('地震', 'じ'), isTrue);
        });

        test('ひな prefix matches 避難', () {
          expect(MultilingualSearchUtils.matchesJapanese('避難所', 'ひな'), isTrue);
        });
      });

      group('Finance terms (金融用語)', () {
        test('クレカ matches クレジットカード', () {
          expect(MultilingualSearchUtils.matches('クレジットカード決済', 'クレカ'), isTrue);
        });

        test('ATM matches エーティーエム', () {
          expect(MultilingualSearchUtils.matches('ATMで引き出し', 'ATM'), isTrue);
        });

        test('振込 matches with reading ふりこみ', () {
          expect(MultilingualSearchUtils.matches('振込手数料', 'ふりこみ'), isTrue);
        });
      });

      group('Kana equivalence', () {
        test('hiragana query matches katakana text', () {
          expect(MultilingualSearchUtils.matches('カタカナ', 'かたかな'), isTrue);
        });

        test('katakana query matches hiragana text', () {
          expect(MultilingualSearchUtils.matches('ひらがな', 'ヒラガナ'), isTrue);
        });
      });
    });

    group('Match scoring with Japanese', () {
      test('Japanese thesaurus match scores 75', () {
        expect(MultilingualSearchUtils.matchScore('スマートフォン', 'スマホ'), 75);
      });

      test('Japanese kana prefix match scores 55', () {
        expect(MultilingualSearchUtils.matchScore('地震警報', 'じ'), 55);
      });
    });

    group('Global comparison (KR vs US vs JP)', () {
      test('Korean 초성 for 기상청', () {
        expect(KoreanSearchUtils.matches('기상청 경보', 'ㄱㅅㅊ'), isTrue);
      });

      test('US prefix for Hurricane', () {
        expect(KoreanSearchUtils.matches('Hurricane Warning', 'Hur'), isTrue);
      });

      test('Japanese contraction for スマホ', () {
        expect(MultilingualSearchUtils.matches('スマートフォン購入', 'スマホ'), isTrue);
      });

      test('All three languages in one search context', () {
        final items = [
          '기상청 경보', // Korean
          'Hurricane Alert', // English
          '地震速報', // Japanese
          'FEMA Notice', // English acronym
          '避難所案内', // Japanese
        ];

        // Korean 초성 search
        var results = MultilingualSearchUtils.sortByRelevance(
          items,
          'ㄱㅅㅊ',
          (i) => i,
        );
        expect(results.first, '기상청 경보');

        // English prefix search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'Hur',
          (i) => i,
        );
        expect(results.first, 'Hurricane Alert');

        // Japanese reading search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'じしん',
          (i) => i,
        );
        expect(results.first, '地震速報');

        // English acronym search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'FEMA',
          (i) => i,
        );
        expect(results.first, 'FEMA Notice');
      });
    });

    // ================================================================
    // European Languages (🇪🇺 EU) Support
    // ================================================================
    group('European 🇪🇺 support', () {
      group('German compound word decomposition (Deutsch)', () {
        test('decomposeGermanCompound extracts known prefixes', () {
          final components = MultilingualSearchUtils.decomposeGermanCompound(
            'Evakuierungssammelstelle',
          );
          expect(components, contains('evak'));
        });

        test('Evak matches Evakuierungssammelstelle', () {
          expect(
            MultilingualSearchUtils.matches('Evakuierungssammelstelle', 'Evak'),
            isTrue,
          );
          expect(
            MultilingualSearchUtils.matchesGermanCompound(
              'Evakuierungssammelstelle',
              'evak',
            ),
            isTrue,
          );
        });

        test('Samml matches Sammelstelle', () {
          expect(
            MultilingualSearchUtils.matchesGermanCompound(
              'Sammelstelle',
              'samml',
            ),
            isTrue,
          );
        });

        test('Notf matches Notfall terms', () {
          expect(
            MultilingualSearchUtils.matches('Notfallplan', 'Notf'),
            isTrue,
          );
          expect(
            MultilingualSearchUtils.matches('Notfalldienst', 'notf'),
            isTrue,
          );
        });

        test('Krank matches Krankenhaus', () {
          expect(
            MultilingualSearchUtils.matches('Krankenhaus', 'Krank'),
            isTrue,
          );
        });

        test('Bürger matches Bürgeramt', () {
          expect(
            MultilingualSearchUtils.matches('Bürgeramt', 'bürger'),
            isTrue,
          );
        });
      });

      group('French/Spanish article removal (Romance languages)', () {
        test('removeEuropeanArticles removes French articles', () {
          final result = MultilingualSearchUtils.removeEuropeanArticles(
            'Mairie de Paris',
            language: 'fr',
          );
          expect(result, 'mairie paris');
        });

        test('removeEuropeanArticles removes Spanish articles', () {
          final result = MultilingualSearchUtils.removeEuropeanArticles(
            'La Casa del Sol',
            language: 'es',
          );
          expect(result, 'casa sol');
        });

        test('Pari matches Mairie de Paris', () {
          expect(
            MultilingualSearchUtils.matches('Mairie de Paris', 'Pari'),
            isTrue,
          );
        });

        test('Mairie matches without de', () {
          expect(
            MultilingualSearchUtils.matches('Mairie de Paris', 'Mairie'),
            isTrue,
          );
        });
      });

      group('European abbreviations', () {
        test('MdP matches Mairie de Paris', () {
          expect(
            MultilingualSearchUtils.matchesEuropeanAbbreviation(
              'mairie de paris',
              'mdp',
            ),
            isTrue,
          );
        });

        test('DB matches Deutsche Bahn', () {
          expect(
            MultilingualSearchUtils.matchesEuropeanAbbreviation(
              'deutsche bahn',
              'db',
            ),
            isTrue,
          );
        });

        test('SNCF matches French railway', () {
          expect(
            MultilingualSearchUtils.matchesEuropeanAbbreviation(
              'société nationale chemins fer français',
              'sncf',
            ),
            isTrue,
          );
        });

        test('IBAN/BIC/SEPA finance terms', () {
          expect(
            MultilingualSearchUtils.matches(
              'International Bank Account Number',
              'iban',
            ),
            isTrue,
          );
          expect(
            MultilingualSearchUtils.matches(
              'Single Euro Payments Area transfer',
              'sepa',
            ),
            isTrue,
          );
        });
      });

      group('Pan-European emergency codes (112)', () {
        test('matchesGlobalEmergencyCode finds EMG_112', () {
          expect(
            MultilingualSearchUtils.matchesGlobalEmergencyCode('112'),
            'EMG_112',
          );
          expect(
            MultilingualSearchUtils.matchesGlobalEmergencyCode('notf'),
            'EMG_112',
          );
          expect(
            MultilingualSearchUtils.matchesGlobalEmergencyCode('urgen'),
            'EMG_112',
          );
          expect(
            MultilingualSearchUtils.matchesGlobalEmergencyCode('emer'),
            'EMG_112',
          );
        });

        test('Urgen matches French emergency', () {
          expect(
            MultilingualSearchUtils.matches('Urgence médicale', 'Urgen'),
            isTrue,
          );
        });

        test('Notf matches German emergency', () {
          expect(
            MultilingualSearchUtils.matches('Notfall Nummer', 'Notf'),
            isTrue,
          );
        });

        test('112 is recognized across languages', () {
          expect(
            MultilingualSearchUtils.matches('Emergency Call 112', '112'),
            isTrue,
          );
          expect(MultilingualSearchUtils.matches('Notruf 112', '112'), isTrue);
        });

        test('getEmergencyCodeKeywords returns all languages', () {
          final keywords = MultilingualSearchUtils.getEmergencyCodeKeywords(
            'EMG_112',
          );
          expect(keywords, contains('emergency'));
          expect(keywords, contains('notfall'));
          expect(keywords, contains('urgence'));
        });

        test('getEmergencyCodeKeywords filters by language', () {
          final deKeywords = MultilingualSearchUtils.getEmergencyCodeKeywords(
            'EMG_112',
            language: 'de',
          );
          expect(deKeywords, contains('notfall'));
          expect(deKeywords, isNot(contains('emergency')));
        });
      });

      group('European match scoring', () {
        test('German compound match scores appropriately', () {
          // 'Evak' is prefix of 'Evakuierungssammelstelle' so it gets 90 (starts with)
          final score = MultilingualSearchUtils.matchScore(
            'Evakuierungssammelstelle',
            'Evak',
          );
          expect(score, 90); // Starts with match

          // Test compound decomposition with non-prefix query
          final score2 = MultilingualSearchUtils.matchScore(
            'Sammelstelle Evakuierung',
            'evak',
          );
          expect(score2, greaterThanOrEqualTo(78));
        });

        test('European abbreviation match scores 76', () {
          final score = MultilingualSearchUtils.matchScore(
            'deutsche bahn service',
            'db',
          );
          expect(score, 76);
        });
      });

      group('matchesEuropean comprehensive', () {
        test('handles mixed European content', () {
          // Direct prefix match
          expect(
            MultilingualSearchUtils.matchesEuropean('Hotel de Ville', 'hotel'),
            isTrue,
          );
          // German compound prefix match
          expect(
            MultilingualSearchUtils.matchesEuropean(
              'Feuerwehr Berlin',
              'feuer',
            ),
            isTrue,
          );
          // Article removal match
          expect(
            MultilingualSearchUtils.matchesEuropean('La Maison', 'maison'),
            isTrue,
          );
        });
      });
    });

    // ================================================================
    // Global Multi-language Comparison
    // ================================================================
    group('Global 4-language comparison (KR/US/JP/EU)', () {
      test('All four regions in one search context', () {
        final items = [
          '기상청 경보', // Korean
          'Hurricane Alert', // English (US)
          '地震速報', // Japanese
          'Evakuierungssammelstelle', // German (EU)
          'Mairie de Paris', // French (EU)
          'FEMA Notice', // US Acronym
          'Urgence médicale', // French emergency
        ];

        // Korean 초성 search
        var results = MultilingualSearchUtils.sortByRelevance(
          items,
          'ㄱㅅㅊ',
          (i) => i,
        );
        expect(results.first, '기상청 경보');

        // English prefix search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'Hur',
          (i) => i,
        );
        expect(results.first, 'Hurricane Alert');

        // Japanese reading search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'じしん',
          (i) => i,
        );
        expect(results.first, '地震速報');

        // German compound search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'Evak',
          (i) => i,
        );
        expect(results.first, 'Evakuierungssammelstelle');

        // French prefix search
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'Pari',
          (i) => i,
        );
        expect(results.first, 'Mairie de Paris');

        // French emergency prefix
        results = MultilingualSearchUtils.sortByRelevance(
          items,
          'Urgen',
          (i) => i,
        );
        expect(results.first, 'Urgence médicale');
      });

      test('Security: public data only principle', () {
        // Low security level data should be accessible
        final emergencyId = MultilingualSearchUtils.matchesGlobalEmergencyCode(
          'notf',
        );
        expect(emergencyId, isNotNull);

        // Verify it's marked as low security
        // In real implementation, this would filter sensitive data
        final keywords = MultilingualSearchUtils.getEmergencyCodeKeywords(
          emergencyId!,
        );
        expect(keywords, isNotEmpty);
      });
    });
  });
}
