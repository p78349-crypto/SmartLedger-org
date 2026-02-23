/// Unit type for void operations
library;

/// Represents successful operations that don't return a value.
/// Use this instead of Result\<void\> which is not type-safe.
///
/// Example:
/// ```dart
/// Future<Result<Unit>> deleteItem(String id) async {
///   try {
///     await database.delete(id);
///     return successVoid();
///   } catch (e) {
///     return Failure(StorageError('Delete failed'));
///   }
/// }
/// 
/// // Usage in UI
/// final result = await deleteItem('123');
/// result.when(
///   success: (_) => print('Deleted'),  // Unit value ignored with _
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```

import 'result.dart';

/// Unit type - a type with exactly one value
/// 
/// Unit is a type that has exactly one value, used to represent
/// "no meaningful value" in a type-safe way.
class Unit {
  const Unit._();
  
  /// The single instance of Unit (singleton pattern)
  static const instance = Unit._();
  
  @override
  String toString() => '()';
  
  @override
  bool operator ==(Object other) => other is Unit;
  
  @override
  int get hashCode => 0;
}

/// Helper function to create successful void result
/// 
/// This is a convenience function to avoid typing:
/// `const Success(Unit.instance)` every time.
Result<Unit> successVoid() => const Success(Unit.instance);

/// Type alias for void results
/// 
/// Makes the intent clearer when declaring void operation signatures.
/// 
/// Example:
/// ```dart
/// Future<VoidResult> clearCache() async {
///   await cache.clear();
///   return successVoid();
/// }
/// ```
typedef VoidResult = Result<Unit>;
