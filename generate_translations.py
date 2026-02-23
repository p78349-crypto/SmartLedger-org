#!/usr/bin/env python3
"""Generate 8 new language translations for all recipes."""

# 8 new languages: de, ar, el, nl, sv, th, tr, vi
# Current order: 'ko', 'en', 'es', 'fr', 'hi', 'it', 'ja', 'pl', 'pt', 'ru'
# New order: 'ko', 'en', 'ar', 'de', 'el', 'es', 'fr', 'hi', 'it', 'ja', 'nl', 'pl', 'pt', 'sv', 'th', 'tr', 'vi', 'ru'

translations_2b = {
    'r27': {
        'en': 'Kalguksu',
        'de': 'Kalguksu',
        'ar': 'كالجوكسو',
        'el': 'Κάλγουχ',
        'nl': 'Kalguksu',
        'sv': 'Kalguksu',
        'th': 'คัลกุกสู',
        'tr': 'Kalguksu',
        'vi': 'Kalguksu'
    },
    'r28': {
        'en': 'Dumpling Soup',
        'de': 'Knödel-Suppe',
        'ar': 'حساء الفطائر',
        'el': 'Σούπα Ζυμαρικών',
        'nl': 'Dumplingsoep',
        'sv': 'Klimpsoppa',
        'th': 'น้ำแกงมันโด้',
        'tr': 'Mandu Çorbası',
        'vi': 'Cơm Bánh Chiên'
    },
    'r29': {
        'en': 'Spicy Beef Soup',
        'de': 'Scharfe Rindersuppe',
        'ar': 'حساء اللحم البقري الحار',
        'el': 'Τσιγαρομένη Σούπα Βόειας',
        'nl': 'Pikante Rundvleessoep',
        'sv': 'Kryddig Nötköttsoppa',
        'th': 'ยุคแกแจ',
        'tr': 'Yüksektansız Soslu Çorba',
        'vi': 'Cơm Bò Cay'
    },
    'r30': {
        'en': 'Stir-fried Julienned Potatoes',
        'de': 'Gebratene Kartoffelstäbchen',
        'ar': 'بطاطس مقلية رفيعة',
        'el': 'Τηγανιτές Πατάτες Ζουλιέν',
        'nl': 'Gebakken Aardappelstengels',
        'sv': 'Stekt Potatisstrimmor',
        'th': 'มันฝรั่งเจอลิแอนทอด',
        'tr': 'Patates Çubukları Kızartılmış',
        'vi': 'Khoai Tây Cắt Sợi Chiên'
    },
    'r31': {
        'en': 'Zucchini Pancake',
        'de': 'Zucchini-Pfannkuchen',
        'ar': 'فطيرة الكوسة',
        'el': 'Κολοκύθι Παγκέικ',
        'nl': 'Courgettepannenkoek',
        'sv': 'Zucchini Pannkaka',
        'th': 'แพนเค้กฟักทอง',
        'tr': 'Kabak Pancake',
        'vi': 'Bánh Roti Bí'
    },
    'r32': {
        'en': 'Kimchi Pancake',
        'de': 'Kimchi-Pfannkuchen',
        'ar': 'فطيرة الكيمتشي',
        'el': 'Κιμτσι Παγκέικ',
        'nl': 'Kimchi Pannenkoek',
        'sv': 'Kimchi Pannkaka',
        'th': 'แพนเค้กกิมจิ',
        'tr': 'Kimchi Pancake',
        'vi': 'Bánh Kimchi'
    },
    'r33': {
        'en': 'Seafood Green Onion Pancake',
        'de': 'Meeresfrüchte-Zwiebel-Pfannkuchen',
        'ar': 'فطيرة المأكولات البحرية والبصل',
        'el': 'Θαλασσινά Κρεμμύδι Παγκέικ',
        'nl': 'Zeevruchten Ui Pannenkoek',
        'sv': 'Skaldjur Lök Pannkaka',
        'th': 'แพนเค้กหอมเหลือบทะเล',
        'tr': 'Deniz Ürünleri Soğan Pancake',
        'vi': 'Bánh Hải Sản Hành Lá'
    },
    'r34': {
        'en': 'Rolled Omelette',
        'de': 'Gerolltes Omelett',
        'ar': 'البيض المقلي الملفوف',
        'el': 'Περιστρεφόμενη Ωμελέτα',
        'nl': 'Gerold Omelet',
        'sv': 'Rullad Omelett',
        'th': 'ไข่ม้วน',
        'tr': 'Sarılmış Omlet',
        'vi': 'Trứng Cuộn'
    }
}

print("Translations generated successfully for 2b recipes.")
for recipe_id in sorted(translations_2b.keys()):
    print(f"  {recipe_id}: {len(translations_2b[recipe_id])} languages")
