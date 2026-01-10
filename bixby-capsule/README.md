Bixby Capsule for SmartLedger - Visit Price Report

Overview:
This capsule provides voice intents to report in-store prices and sends a deep-link to the SmartLedger mobile app to pre-fill the Visit Price Form.

Primary intent: report_price
Slots:
- store (e.g., '롯데마트 잠실')
- item (e.g., '양파')
- price (numeric, in KRW)
- quantity (optional)
- discount (optional, e.g., '1+1', '마감 세일')

Deep link format (example):
smartledger://visit_price_form?storeId=lotte_jamsil&skuId=onion_001&price=2100&quantity=1&discount=onePlusOne

Examples (Korean utterances):
- "롯데마트에서 양파 한 망이 2100원이에요" --> store, item, price, quantity
- "이마트 양파 1+1이라 2개에 2100원에 샀어요" --> discount=onePlusOne
- "오늘 마트에서 양파가 반값이었어" --> discount=clearance

Notes:
- Capsule should map common discount phrases into DiscountType values: onePlusOne, clearance, timeSale, coupon, custom.
- App must handle `visit_price_form` deep link and prefill `VisitPriceFormScreen` parameters.
