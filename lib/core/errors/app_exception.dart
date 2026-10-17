class ValidationException implements Exception {
  const ValidationException(this.message, {this.field});

  final String message;
  final String? field;

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}
