import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/ingredient_health_score_utils.dart';

void main() {
  group('IngredientHealthScoreUtils', () {
    group('ingredientScores', () {
      test('contains vegetables with high scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['양배추'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['브로콜리'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['당근'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['시금치'], 5);
      });

      test('contains mushrooms with high scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['느타리버섯'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['표고버섯'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['팽이버섯'], 5);
      });

      test('contains tofu and beans with high scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['두부'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['콩'], 5);
      });

      test('contains meat with lower scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['돼지고기'], 2);
        expect(IngredientHealthScoreUtils.ingredientScores['삼겹살'], 2);
        expect(IngredientHealthScoreUtils.ingredientScores['닭고기'], 3);
      });

      test('contains processed foods with low scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['라면'], 1);
        expect(IngredientHealthScoreUtils.ingredientScores['햄'], 1);
        expect(IngredientHealthScoreUtils.ingredientScores['소시지'], 1);
      });

      test('contains seafood with good scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['생선'], 4);
        expect(IngredientHealthScoreUtils.ingredientScores['연어'], 4);
        expect(IngredientHealthScoreUtils.ingredientScores['김'], 5);
        expect(IngredientHealthScoreUtils.ingredientScores['미역'], 5);
      });

      test('contains grains with varied scores', () {
        expect(IngredientHealthScoreUtils.ingredientScores['쌀'], 3);
        expect(IngredientHealthScoreUtils.ingredientScores['현미'], 4);
        expect(IngredientHealthScoreUtils.ingredientScores['귀리'], 5);
      });

      test('potato and sweet potato have score 4', () {
        expect(IngredientHealthScoreUtils.ingredientScores['감자'], 4);
        expect(IngredientHealthScoreUtils.ingredientScores['고구마'], 4);
      });

      test('sugar has lowest score', () {
        expect(IngredientHealthScoreUtils.ingredientScores['설탕'], 1);
      });

      test('scores are between 1 and 5', () {
        for (final score in IngredientHealthScoreUtils.ingredientScores.values) {
          expect(score, greaterThanOrEqualTo(1));
          expect(score, lessThanOrEqualTo(5));
        }
      });
    });
  });
}
