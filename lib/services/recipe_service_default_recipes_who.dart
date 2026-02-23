part of 'recipe_service.dart';

/// WHO 건강 추천 특별 메뉴
final List<Recipe> _defaultRecipesWHO = [
  Recipe(
    id: 'who_chicken',
    localizedNames: {
      'ko': '🌟 닭고기·버섯·채소 된장탕 (WHO추천)',
      'en':
          '🌟 Chicken, Mushroom & Vegetable Soybean Stew '
          '(WHO Recommended)',
      'ar':
          '🌟 حساء صويا بالدجاج والفطر والخضار '
          '(موصى به من قبل منظمة الصحة العالمية)',
      'de':
          '🌟 Hühner-, Pilz- und Gemüse-Misosuppe '
          '(WHO empfohlen)',
      'el':
          '🌟 Σούπα με κοτόπουλο, μανιτάρια και λαχανικά '
          '(Συνιστάται από ΠΟΥ)',
      'es':
          '🌟 Estofado de pollo, champiñones y verduras con soja '
          '(Recomendado por la OMS)',
      'fr':
          '🌟 Ragoût de poulet, champignons et légumes au soja '
          '(Recommandé par l\'OMS)',
      'hi':
          '🌟 चिकन, मशरूम और सब्ज़ियों का मिसो सूप '
          '(WHO अनुशंसित)',
      'it':
          '🌟 Stufato di pollo, funghi e verdure con soia '
          '(Raccomandato WHO)',
      'ja':
          '🌟 鶏肉・キノコ・野菜の味噌汁 '
          '(WHO推奨)',
      'nl':
          '🌟 Misosoep met kip, champignons en groenten '
          '(Aanbevolen door WHO)',
      'pl':
          '🌟 Gulasz z kurczaka, grzybów i warzyw z soją '
          '(Zalecane przez WHO)',
      'pt':
          '🌟 Caldo de Missô com Frango, Cogumelos e '
          'Vegetais (Recomendado pela OMS)',
      'sv':
          '🌟 Misosoppa med kyckling, svamp och grönsaker '
          '(Rekommenderat av WHO)',
      'th':
          '🌟 ซุปมิโสะไก่ เห็ด และผัก (แนะนำโดย WHO)',
      'tr':
          '🌟 Tavuk, mantar ve sebzeli miso çorbası '
          '(WHO önerisi)',
      'vi':
          '🌟 Súp miso với gà, nấm và rau (Được WHO khuyến nghị)',
      'ru':
          '🌟 Тушёное из курицы, грибов и овощей '
          '(Рекомендовано ВОЗ)',
    },
    healthScore: 5,
    ingredients: [
      RecipeIngredient(name: '닭볶음탕용 닭고기', quantity: 900, unit: 'g'),
      RecipeIngredient(name: '느타리버섯', quantity: 500, unit: 'g'),
      RecipeIngredient(name: '표고버섯', quantity: 500, unit: 'g'),
      RecipeIngredient(name: '팽이버섯', quantity: 3, unit: '봉'),
      RecipeIngredient(name: '호박', quantity: 1, unit: '개'),
      RecipeIngredient(name: '양배추', quantity: 1.5, unit: 'kg'),
      RecipeIngredient(name: '당근', quantity: 1, unit: '개'),
      RecipeIngredient(name: '가지', quantity: 2, unit: '개'),
      RecipeIngredient(name: '양파', quantity: 1, unit: '망'),
      RecipeIngredient(name: '마늘', quantity: 1, unit: '망'),
      RecipeIngredient(name: '브로콜리', quantity: 1, unit: '개'),
      RecipeIngredient(name: '감자', quantity: 7, unit: '개'),
      RecipeIngredient(name: '피망', quantity: 2, unit: '개'),
      RecipeIngredient(name: '고추장', quantity: 1, unit: '숟가락'),
      RecipeIngredient(name: '된장', quantity: 1, unit: '숟가락'),
    ],
  ),
  Recipe(
    id: 'who_pork',
    localizedNames: {
      'ko': '🌟 돼지고기·버섯·채소 된장탕 (WHO추천)',
      'en':
          '🌟 Pork, Mushroom & Vegetable Soybean Stew '
          '(WHO Recommended)',
      'ar':
          '🌟 حساء صويا بالخنزير والفطر والخضار '
          '(موصى به من قبل منظمة الصحة العالمية)',
      'de':
          '🌟 Schweine-, Pilz- und Gemüse-Misosuppe '
          '(WHO empfohlen)',
      'el':
          '🌟 Σούπα με χοιρινό, μανιτάρια και λαχανικά '
          '(Συνιστάται από ΠΟΥ)',
      'es':
          '🌟 Estofado de cerdo, champiñones y verduras con soja '
          '(Recomendado por la OMS)',
      'fr':
          '🌟 Ragoût de porc, champignons et légumes au soja '
          '(Recommandé par l\'OMS)',
      'hi':
          '🌟 पोर्क, मशरूम और सब्ज़ियों का मिसो सूप '
          '(WHO अनुशंसित)',
      'it':
          '🌟 Stufato di maiale, funghi e verdure con soia '
          '(Raccomandato WHO)',
      'ja':
          '🌟 豚肉・キノコ・野菜の味噌汁 '
          '(WHO推奨)',
      'nl':
          '🌟 Misosoep met varkensvlees, champignons en groenten '
          '(Aanbevolen door WHO)',
      'pl':
          '🌟 Gulasz z wieprzowiny, grzybów i warzyw z soją '
          '(Zalecane przez WHO)',
      'pt':
          '🌟 Caldo de Missô com Porco, Cogumelos e '
          'Vegetais (Recomendado pela OMS)',
      'sv':
          '🌟 Misosoppa med fläsk, svamp och grönsaker '
          '(Rekommenderat av WHO)',
      'th':
          '🌟 ซุปมิโสะหมู เห็ด และผัก (แนะนำโดย WHO)',
      'tr':
          '🌟 Domuz, mantar ve sebzeli miso çorbası '
          '(WHO önerisi)',
      'vi':
          '🌟 Súp miso với heo, nấm và rau (Được WHO khuyến nghị)',
      'ru':
          '🌟 Тушёное из свинины, грибов и овощей '
          '(Рекомендовано ВОЗ)',
    },
    healthScore: 5,
    ingredients: [
      RecipeIngredient(name: '돼지고기 (앞다리/사태)', quantity: 900, unit: 'g'),
      RecipeIngredient(name: '느타리버섯', quantity: 500, unit: 'g'),
      RecipeIngredient(name: '표고버섯', quantity: 500, unit: 'g'),
      RecipeIngredient(name: '팽이버섯', quantity: 3, unit: '봉'),
      RecipeIngredient(name: '호박', quantity: 1, unit: '개'),
      RecipeIngredient(name: '양배추', quantity: 1.5, unit: 'kg'),
      RecipeIngredient(name: '당근', quantity: 1, unit: '개'),
      RecipeIngredient(name: '가지', quantity: 2, unit: '개'),
      RecipeIngredient(name: '양파', quantity: 1, unit: '망'),
      RecipeIngredient(name: '마늘', quantity: 1, unit: '망'),
      RecipeIngredient(name: '브로콜리', quantity: 1, unit: '개'),
      RecipeIngredient(name: '감자', quantity: 7, unit: '개'),
      RecipeIngredient(name: '피망', quantity: 2, unit: '개'),
      RecipeIngredient(name: '고추장', quantity: 1, unit: '숟가락'),
      RecipeIngredient(name: '된장', quantity: 1, unit: '숟가락'),
    ],
  ),
];
