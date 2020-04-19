// ignore: public_member_api_docs
T requireNotNull<T>(T value, {String name = 'value'}) {
  if (value == null) throw ArgumentError.notNull(name);
  return value;
}

// ignore: public_member_api_docs
class NoSuchElementException implements Exception {
  final String _message;

  // ignore: public_member_api_docs
  const NoSuchElementException(this._message);

  @override
  String toString() => _message;
}
