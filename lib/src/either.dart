import 'package:bullseye/src/option.dart';
import 'package:bullseye/src/utils.dart';
import 'package:meta/meta.dart';

/// A container that represents one of two possible values. It is right biased.
@immutable
abstract class Either<L, R> {
  const Either._();

  /// Creates a new [Either] with a provided non-null right [value].
  const factory Either.right(R value) = _Right<L, R>;

  /// Creates a new [Either] with a provided non-null left [value].
  const factory Either.left(L value) = _Left<L, R>;

  /// Creates a right sided [Either] if the [provider] does not fail to yield a value.
  /// If an [Exception] or [Error] is thrown a left side [Either] is created from the [orElse] function.
  factory Either.tryOrElseProvide({
    R Function() provider,
    L Function(Either<Error, Exception>) orElse,
  }) {
    try {
      return Either<L, R>.right(provider());
    } on Exception catch (exception) {
      return Either<L, R>.left(orElse(Either<Error, Exception>.right(exception)));
    } on Error catch (error) {
      return Either<L, R>.left(orElse(Either<Error, Exception>.left(error)));
    }
  }

  /// Creates a right sided [Either] if the [provider] does not fail to yield a value.
  /// If an [Exception] or [Error] is thrown a left side [Either] is created with the [orElse] value.
  factory Either.tryOrElse({R Function() provider, L orElse}) {
    return Either<L, R>.tryOrElseProvide(provider: provider, orElse: (_) => orElse);
  }

  /// Creates a right sided [Either] if the [provider] does not fail to yield a value.
  /// In case of of an [Exception] a left sided [Either] is created with that [Exception]
  /// passed to the [onException] function.
  factory Either.safeOnException({R Function() provider, L Function(Exception) onException}) {
    try {
      return Either<L, R>.right(provider());
    } on Exception catch (e) {
      return Either<L, R>.left(onException(e));
    }
  }

  /// Creates a right sided [Either] if the [provider] does not fail to yield a value.
  /// In case of of an [Error] a left sided [Either] is created with that [Error]
  /// passed to the [onException] function.
  factory Either.safeOnError({R Function() provider, L Function(Error) onError}) {
    try {
      return Either<L, R>.right(provider());
    } on Error catch (e) {
      return Either<L, R>.left(onError(e));
    }
  }

  /// Allows to safely bind values in [Either] containers. If any of the bounded values
  /// does not exists computation is stopped and left sided [Either] is returned.
  ///
  /// ```dart
  /// // Results in an either with a right value of '6'.
  /// final sum = Either.fx((effects) {
  ///   final int one = Either.right(1).bind(effects);
  ///   final int two = Either.right(2).bind(effects);
  ///   final int three = Either.right(3).bind(effects);
  ///   return one + two + three;
  /// });
  ///
  /// // Results in an either with a left value of 'false'.
  /// final sum = Either.fx((effects) {
  ///   final int one = Either.right(1).bind(effects);
  ///   final int two = Either.left(false).bind(effects);
  ///   final int three = Either.right(3).bind(effects);
  ///   return one + two + three;
  /// });
  /// ```
  static Either<L, R> fx<L, R>(R Function(EitherFx<L>) function) {
    try {
      return Either<L, R>.right(function(EitherFx<L>._instance()));
    } on _NoRightValueException catch (e) {
      return Either<L, R>.left(e.left);
    }
  }

  /// Allows to safely bind values in [Either] containers. If any of the bounded values
  /// does not exists computation is stopped and left sided [Either] is returned.
  ///
  /// ```dart
  /// // Results in an either with a right value of '6'.
  /// final sum = await Either.fxAsync((effects) async {
  ///   final awaitedOne = await Future.value(Either.right(1));
  ///   final awaitedTwo = await Future.value(Either.right(2));
  ///   final awaitedThree = await Future.value(Either.right(3));
  ///   final one = awaitedOne.bind(effects);
  ///   final two = awaitedTwo.bind(effects);
  ///   final three = awaitedThree.bind(effects);
  ///   return one + two + three;
  /// });
  ///
  /// // Results in an either with a left value of 'false'.
  /// final sum = await Either.fxAsync((effects) async {
  ///   final awaitedOne = await Future.value(Either.right(1));
  ///   final awaitedTwo = await Future.value(Either.left(false));
  ///   final awaitedThree = await Future.value(Either.right(3));
  ///   final one = awaitedOne.bind(effects);
  ///   final two = awaitedTwo.bind(effects);
  ///   final three = awaitedThree.bind(effects);
  ///   return one + two + three;
  /// });
  /// ```
  static Future<Either<L, R>> fxAsync<L,R>(Future<R> Function(EitherFx<L>) function) async {
    try {
      return Either<L, R>.right(await function(EitherFx<L>._instance()));
    } on _NoRightValueException catch (e) {
      return Either<L, R>.left(e.left);
    }
  }

  R _get();

  L _getLeft();

  /// Returns `true` if this [Either] does not hold a right value, `false` otherwise.
  bool get isLeft;

  /// Returns `true` if this [Either] does hold a right value, `false` otherwise.
  bool get isRight => !isLeft;

  /// Returns a right value held by this [Either] or returns a value provided by the [provider].
  @nonVirtual
  R getOrElseProvide(R Function() provider) {
    return isLeft ? provider() : _get();
  }

  /// Returns a right value held by this [Either] or returns [other] value.
  @nonVirtual
  R getOrElse(R other) => getOrElseProvide(() => other);

  /// Returns a right value held by this [Either] or throws an [Exception] from the [provider].
  @nonVirtual
  R getOrException(Exception Function() provider) {
    return isLeft ? throw provider() : _get();
  }

  /// Returns a right value held by this [Either] or throws an [Error] from the [provider].
  @nonVirtual
  R getOrError(Error Function() provider) {
    return isLeft ? throw provider() : _get();
  }

  /// Returns an [Error] provided by the [provider] if there is no right value.
  @nonVirtual
  Either<L, R> orElseProvide(Either<L, R> Function() provider) {
    return isLeft ? provider() : this;
  }

  /// Returns the [other] if there is no right  value.
  @nonVirtual
  Either<L, R> orElse(Either<L, R> other) => orElseProvide(() => other);

  /// Returns a right sided [Either] if the right value matches the [predicate].
  /// Otherwise it returns a left sided [Either] with a value provided by the [orElse] function.
  /// If it is already left sided it returns self.
  @nonVirtual
  Either<L, R> filterOrElseProvide({bool Function(R) predicate, L Function() orElse}) {
    return isLeft || predicate(_get()) ? this : Either<L, R>.left(orElse());
  }

  /// Returns a right sided [Either] if the right value matches the [predicate].
  /// Otherwise it returns a left sided [Either] with a [orElse] value.
  /// If it is already left sided it returns self.
  @nonVirtual
  Either<L, R> filterOrElse({bool Function(R) predicate, L orElse}) {
    return filterOrElseProvide(predicate: predicate, orElse: () => orElse);
  }

  /// Returns a right sided [Either] if the right does not match the [predicate].
  /// Otherwise it returns a left sided [Either] with a value provided by the [orElse] function.
  /// If it is already left sided it returns self.
  @nonVirtual
  Either<L, R> filterNotOrElseProvide({bool Function(R) predicate, L Function() orElse}) {
    return filterOrElseProvide(predicate: (it) => !predicate(it), orElse: orElse);
  }

  /// Returns a right sided [Either] if the right value does not match the [predicate].
  /// Otherwise it returns a left sided [Either] with a [orElse] value.
  /// If it is already left sided it returns self.
  @nonVirtual
  Either<L, R> filterNotOrElse({bool Function(R) predicate, L orElse}) {
    return filterNotOrElseProvide(predicate: predicate, orElse: () => orElse);
  }

  /// Returns a value from the [ifLeft] function or the [ifRight] function depending on the content
  /// of this [Either].
  @nonVirtual
  U fold<U>({U Function(L) ifLeft, U Function(R) ifRight}) {
    return isLeft ? ifLeft(_getLeft()) : ifRight(_get());
  }

  /// Applies the [transformer] to this [Either].
  @nonVirtual
  U transform<U>(U Function(Either<L, R>) transformer) => transformer(this);

  /// Converts a left value to a right value and vice versa.
  @nonVirtual
  Either<R, L> swap() {
    return isLeft ? Either<R, L>.right(_getLeft()) : Either<R, L>.left(_get());
  }

  /// Executes the [mapper] and wraps the result in an [Either] if this [Either] is left sided.
  /// Otherwise it returns self.
  @nonVirtual
  Either<L, R> recover(R Function(L) mapper) {
    return isLeft ? Either<L, R>.right(mapper(_getLeft())) : this;
  }

  /// Executes the [mapper] if this [Either] is left sided.
  /// Otherwise it returns self.
  @nonVirtual
  Either<L, R> flatRecover(Either<L, R> Function(L) mapper) {
    return isLeft ? mapper(_getLeft()) : this;
  }

  /// Maps a value with the [ifLeft] function or the [ifRight] function depending on the content
  /// of this [Either].
  @nonVirtual
  Either<L2, R2> bimap<L2, R2>({L2 Function(L) ifLeft, R2 Function(R) ifRight}) {
    if (isLeft) {
      return Either<L2, R2>.left(ifLeft(_getLeft()));
    } else {
      return Either<L2, R2>.right(ifRight(_get()));
    }
  }

  /// Maps a left value held by this [Either] if there is one.
  @nonVirtual
  Either<U, R> mapLeft<U>(U Function(L) mapper) {
    return isLeft ? Either<U, R>.left(mapper(_getLeft())) : this;
  }

  /// Maps this [Either] to another one if it is left sided.
  @nonVirtual
  Either<U, R> flatMapLeft<U>(Either<U, R> Function(L) mapper) {
    return isLeft ? mapper(_getLeft()) : this;
  }

  /// Maps a right value held by this [Either] if there is one.
  @nonVirtual
  Either<L, U> map<U>(U Function(R) mapper) {
    return isLeft ? this : Either<L, U>.right(mapper(_get()));
  }

  /// Maps this [Either] to another one if it is right sided.
  @nonVirtual
  Either<L, U> flatMap<U>(Either<L, U> Function(R) mapper) {
    return isLeft ? this : mapper(_get());
  }

  /// Executes the [ifLeft] consumer or the [ifRight] consumer depending on the content of this [Either].
  @nonVirtual
  void peek({Function(L) ifLeft, Function(R) ifRight}) {
    isLeft ? ifLeft(_getLeft()) : ifRight(_get());
  }

  /// Converts this [Either] to an [Option] with a value if it is right sided. Otherwise an empty
  /// [Option] is returned.
  @nonVirtual
  Option<R> toOption() {
    return isLeft ? Option<R>.none() : Option<R>.some(_get());
  }

  /// Binds a right value of this [Either]. If no right value is present [effects] control flow is interrupted.
  R bind(EitherFx effects) {
    return effects._bind(this);
  }
}

@immutable
class _Right<L, R> extends Either<L, R> {
  final R _value;

  const _Right(this._value) : super._();

  @override
  String toString() => 'Right(value=$_value)';

  @override
  bool operator ==(Object other) => other is _Right && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  R _get() => _value;

  @override
  L _getLeft() => throw const NoSuchElementException('no left value present');

  @override
  bool get isLeft => false;
}

@immutable
class _Left<L, R> extends Either<L, R> {
  final L _value;

  const _Left(this._value) : super._();

  @override
  String toString() => 'Left(value=$_value)';

  @override
  bool operator ==(Object other) => other is _Left && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  R _get() => throw const NoSuchElementException('no right value present');

  @override
  L _getLeft() => _value;

  @override
  bool get isLeft => true;
}

/// Collection of effects over the [Either] type.
@immutable
class EitherFx<L> {
  const EitherFx._instance();

  @nonVirtual
  R _bind<R>(Either<L, R> either) {
    return either.fold(
      ifLeft: (left) => throw _NoRightValueException(left),
      ifRight: (right) => right,
    );
  }
}

class _NoRightValueException<L> implements Exception {
  final L left;

  const _NoRightValueException(this.left);
}
