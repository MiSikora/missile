import 'package:meta/meta.dart';

/// A tuple of two values.
@immutable
class Pair<T1, T2> {
  /// First value of this tuple.
  final T1 first;

  /// Second value of this tuple.
  final T2 second;

  const Pair._(this.first, this.second);

  /// Creates a new pair with two values.
  const factory Pair(T1 first, T2 second) = Pair<T1, T2>._;

  Pair<R, T2> mapFirst<R>(R Function(T1) mapper) => Pair(mapper(first), second);

  Pair<T1, R> mapSecond<R>(R Function(T2) mapper) => Pair(first, mapper(second));

  R transform<R>(R Function(Pair<T1, T2>) transformer) => transformer(this);

  R transformValues<R>(R Function(T1, T2) transformer) => transformer(first, second);

  @override
  String toString() => 'Pair($first,$second)';

  @override
  bool operator ==(Object other) => other is Pair && first == other.first && second == other.second;

  @override
  int get hashCode => first.hashCode + second.hashCode;
}
