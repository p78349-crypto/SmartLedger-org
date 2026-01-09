// RecommendRecipe Action Handler
// "레시피 추천해줘" 같은 발화로 유통기한 화면의 오늘의 요리 추천 섹션으로 이동합니다.

const endpoints = require('./endpoints.js');

module.exports.function = function recommendRecipe($vivContext) {
  return endpoints.OpenRecipeRecommendation();
};
