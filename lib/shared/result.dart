/// Result type for safe error handling
library;

/// Provides type-safe error handling using sealed classes.
/// Use pattern matching with `when` method to handle success/failure cases.
///
/// Example:
/// ```dart
/// final result = await repository.fetchData();
/// result.when(
///   success: (data) => print('Success: $data'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```

import 'errors.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);

  @override
  String toString() => 'Failure(${error.message})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Extension methods for Result type
extension ResultExt<T> on Result<T> {
  /// Returns true if this is a Success
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure
  bool get isFailure => this is Failure<T>;

  /// Returns the data if Success, null otherwise
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  /// Returns the error if Failure, null otherwise
  AppError? get errorOrNull =>
      this is Failure<T> ? (this as Failure<T>).error : null;

  /// Pattern matching for Result
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }

  /// Maps the success value
  Result<R> map<R>(R Function(T data) transform) {
    return when(
      success: (data) => Success(transform(data)),
      failure: Failure.new,
    );
  }

  /// FlatMap for chaining Results
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return when(success: transform, failure: Failure.new);
  }

  /// Async map
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    return when(
      success: (data) async => Success(await transform(data)),
      failure: Failure.new,
    );
  }

  /// Get data or throw error
  T getOrThrow() {
    return when(
      success: (data) => data,
      failure: (error) => throw Exception(error.message),
    );
  }

  /// Get data or return default value
  T getOrElse(T defaultValue) {
    return when(success: (data) => data, failure: (_) => defaultValue);
  }

  /// Fold for custom handling
  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    return when(success: onSuccess, failure: onFailure);
  }
}
