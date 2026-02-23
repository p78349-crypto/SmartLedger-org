/// Application error types for type-safe error handling
library;

/// All errors inherit from AppError base class and use sealed class
/// pattern for exhaustive error handling.

sealed class AppError {
  final String message;
  final Object? cause;
  
  const AppError(this.message, [this.cause]);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError &&
          runtimeType == other.runtimeType &&
          message == other.message;
  
  @override
  int get hashCode => message.hashCode;
  
  @override
  String toString() => '$runtimeType: $message';
}

/// Validation error for invalid input
class ValidationError extends AppError {
  const ValidationError(super.message);
}

/// Network error for HTTP/API failures
class NetworkError extends AppError {
  final int? statusCode;
  
  const NetworkError(super.message, {this.statusCode});
  
  @override
  String toString() => 
      'NetworkError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Storage error for database/file operations
class StorageError extends AppError {
  const StorageError(super.message);
}

/// Not found error for missing resources
class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

/// Permission error for unauthorized access
class PermissionError extends AppError {
  const PermissionError(super.message);
}

/// Unknown error for unexpected failures
class UnknownError extends AppError {
  const UnknownError(Object cause) : super('Unknown error occurred', cause);
  
  @override
  String toString() => 'UnknownError: $message (${cause.toString()})';
}
