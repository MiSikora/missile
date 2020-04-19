import 'package:missile/src/either.dart';
import 'package:missile/src/utils.dart';
import 'package:meta/meta.dart';

/// A container that represents a presence of a value.
@immutable
abstract class Option<T> {
  const Option._();

  /// Creates a new [Option] with a provided non-null [value].
  factory Option.some(T value) = _Some<T>;

  /// Creates a new [Option] that does not contain any data.
  const factory Option.none() = _None<T>;

  /// Creates a new [Option] that will either hold the [value] if it is not `null`
  /// or in other case will be empty.
  factory Option.of(T value) {
    return value != null ? Option.some(value) : Option<T>.none();
  }

  /// Conditionally creates a new [Option]. If [predicate] yields `true`
  /// an [Option] with a non-null [value] is created. Otherwise empty [Option] is returned.
  factory Option.when({@required bool predicate, @required T value}) {
    return predicate ? Option.some(value) : Option<T>.none();
  }

  /// Allows to safely apply effects on [Option] containers. If any of the effects does not
  /// succeed computation is stopped and empty [Option] is returned.
  ///
  /// ```dart
  /// // Results in an option with a value.
  /// final sum = Option.fx((effects) {
  ///   final int one = Option.some(1).bind(effects);
  ///   final int two = Option.some(2).bind(effects);
  ///   final int three = Option.some(3).bind(effects);
  ///   return one + two + three;
  /// });
  ///
  /// // Results in an option without a value.
  /// final sum = Option.fx((effects) {
  ///   final int one = Option.some(1).bind(effects);
  ///   final int two = Option.none().bind(effects);
  ///   final int three = Option.some(3).bind(effects);
  ///   return one + two + three;
  /// });
  /// ```
  static Option<T> fx<T>(T Function(OptionFx) function) {
    try {
      return Option<T>.some(function(const OptionFx._instance()));
    } on _NoOptionValueException catch (_) {
      return Option<T>.none();
    }
  }

  /// Allows to safely apply effects on [Option] containers. If any of the effects does not
  /// succeed computation is stopped and empty [Option] is returned.
  ///
  /// ```dart
  /// // Results in an option with a value.
  /// final sum = await Option.fxAsync((effects) async {
  ///   final awaitedOne = await Future.value(Option.some(1));
  ///   final awaitedTwo = await Future.value(Option.some(2));
  ///   final awaitedThree = await Future.value(Option.some(3));
  ///   final one = awaitedOne.bind(effects);
  ///   final two = awaitedTwo.bind(effects);
  ///   final three = awaitedThree.bind(effects);
  ///   return one + two + three;
  /// });
  ///
  /// // Results in an option without a value.
  /// final sum = await Option.fxAsync((effects) async {
  ///   final awaitedOne = await Future.value(Option.some(1));
  ///   final awaitedTwo = await Future.value(Option.none());
  ///   final awaitedThree = await Future.value(Option.some(3));
  ///   final one = awaitedOne.bind(effects);
  ///   final two = awaitedTwo.bind(effects);
  ///   final three = awaitedThree.bind(effects);
  ///   return one + two + three;
  /// });
  /// ```
  static Future<Option<T>> fxAsync<T>(Future<T> Function(OptionFx) function) async {
    try {
      return Option<T>.some(await function(const OptionFx._instance()));
    } on _NoOptionValueException catch (_) {
      return Option<T>.none();
    }
  }

  T _get();

  /// Returns `true` if this [Option] does not hold any value, `false` otherwise.
  bool get isEmpty;

  /// Returns `true` if this [Option] does hold any value, `false` otherwise.
  @nonVirtual
  bool get isNotEmpty => !isEmpty;

  /// Returns a value held by this [Option] or returns a value provided by the [provider].
  @nonVirtual
  T getOrElseProvide(T Function() provider) {
    return isEmpty ? provider() : _get();
  }

  /// Returns a value held by this [Option] or returns [other] value.
  @nonVirtual
  T getOrElse(T other) => getOrElseProvide(() => other);

  /// Returns a value held by this [Option] or throws an [Exception] from the [provider].
  @nonVirtual
  T getOrException(Exception Function() provider) {
    return isEmpty ? throw provider() : _get();
  }

  /// Returns a value held by this [Option] or throws an [Error] from the [provider].
  @nonVirtual
  T getOrError(Error Function() provider) {
    return isEmpty ? throw provider() : _get();
  }

  /// Returns an [Option] provided by the [provider] if there is no value.
  @nonVirtual
  Option<T> orElseProvide(Option<T> Function() provider) {
    return isEmpty ? provider() : this;
  }

  /// Returns the [other] if there is no value.
  @nonVirtual
  Option<T> orElse(Option<T> other) => orElseProvide(() => other);

  /// Returns an empty [Option] if the value does not match the [predicate].
  @nonVirtual
  Option<T> filter(bool Function(T) predicate) {
    return isEmpty || predicate(_get()) ? this : Option<T>.none();
  }

  /// Returns and empty [Option] if the value matches the [predicate].
  @nonVirtual
  Option<T> filterNot(bool Function(T) predicate) => filter((it) => !predicate(it));

  /// Returns from the [ifNone] provider if there is no value or from the [ifSome] mapper
  /// if there is one.
  @nonVirtual
  R fold<R>({@required R Function() ifNone, @required R Function(T) ifSome}) {
    return map(ifSome).getOrElseProvide(ifNone);
  }

  /// Applies the [transformer] to this [Option].
  @nonVirtual
  R transform<R>(R Function(Option<T>) transformer) => transformer(this);

  /// Maps a value held by this [Option] if there is one.
  @nonVirtual
  Option<R> map<R>(R Function(T) mapper) {
    return isEmpty ? Option<R>.none() : Option.some(mapper(_get()));
  }

  /// Maps this [Option] to another one if currently there is a value being held.
  @nonVirtual
  Option<R> flatMap<R>(Option<R> Function(T) mapper) {
    return isEmpty ? Option<R>.none() : mapper(_get());
  }

  /// Executes the [ifNone] function if this [Option] is empty, otherwise it uses the [ifSome] consumer.
  @nonVirtual
  void peek({@required Function() ifNone, @required Function(T) ifSome}) {
    isEmpty ? ifNone() : ifSome(_get());
  }

  /// Converts this [Option] to a right sided [Either] if there is a value. Otherwise a left sided
  /// [Either] is created with the [ifNone] value.
  @nonVirtual
  Either<L, T> toEither<L>(L ifNone) {
    return isEmpty ? Either<L, T>.left(ifNone) : Either<L, T>.right(_get());
  }

  /// Binds value of this [Option]. If no value is present [effects] control flow is interrupted.
  T bind(OptionFx effects) {
    return effects._bind(this);
  }
}

@immutable
class _Some<T> extends Option<T> {
  final T _value;

  _Some(T value)
      : _value = requireNotNull(value),
        super._();

  @override
  String toString() => 'Some(value=$_value)';

  @override
  bool operator ==(Object other) => other is _Some && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  bool get isEmpty => false;

  @override
  T _get() => _value;
}

@immutable
class _None<T> extends Option<T> {
  const _None() : super._();

  @override
  String toString() => 'None';

  @override
  bool operator ==(Object other) => other is _None;

  @override
  int get hashCode => null.hashCode;

  @override
  bool get isEmpty => true;

  @override
  T _get() => throw const NoSuchElementException('no value present');
}

/// Collection of effects over the [Option] type.
@immutable
class OptionFx {
  const OptionFx._instance();

  @nonVirtual
  T _bind<T>(Option<T> option) {
    return option.getOrException(() => const _NoOptionValueException());
  }
}

class _NoOptionValueException implements Exception {
  const _NoOptionValueException();
}
