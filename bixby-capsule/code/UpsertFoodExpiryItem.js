// UpsertFoodExpiryItem Action Handler
// 식재료/생활용품 등록(유통기한) 화면을 열고, 가능한 경우 자동 등록까지 이어지게 합니다.

const endpoints = require('./endpoints.js');

module.exports.function = function upsertFoodExpiryItem(name, quantity, unit, location, expiryDays, price, $vivContext) {
  return endpoints.UpsertFoodExpiryItem({
    name: name,
    quantity: quantity,
    unit: unit,
    location: location,
    expiryDays: expiryDays,
    price: price,
  });
};
