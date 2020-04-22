import 'package:meta/meta.dart';
import 'package:missile/src/utils.dart';

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

  /// Maps the first value of this [Pair] and returns a new one with the second value copied.
  Pair<R, T2> mapFirst<R>(R Function(T1) mapper) {
    requireNotNull(mapper);
    return Pair(mapper(first), second);
  }

  /// Maps the second value of this [Pair] and returns a new one with the first value copied.
  Pair<T1, R> mapSecond<R>(R Function(T2) mapper) {
    requireNotNull(mapper);
    return Pair(first, mapper(second));
  }

  /// Applies the [transformer] to this [Pair].
  R transform<R>(R Function(Pair<T1, T2>) transformer) {
    requireNotNull(transformer);
    return  transformer(this);
  }

  /// Applies the [transformer] to values of this [Pair].
  R transformValues<R>(R Function(T1, T2) transformer) {
    requireNotNull(transformer);
    return transformer(first, second);
  }

  @override
  String toString() => 'Pair($first,$second)';

  @override
  bool operator ==(Object other) => other is Pair && first == other.first && second == other.second;

  @override
  int get hashCode => first.hashCode + second.hashCode;
}
