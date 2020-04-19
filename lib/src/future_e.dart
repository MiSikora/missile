import 'dart:async';

import 'package:meta/meta.dart';
import 'package:missile/missile.dart';
import 'package:missile/src/utils.dart';

/// A specialized version of a [Future] that contains an [Either].
@immutable
class FutureE<L, R> implements Future<Either<L, R>> {
  final Future<Either<L, R>> _delegate;

  FutureE._(Future<Either<L, R>> future) : _delegate = requireNotNull(future, name: 'future');

  /// Creates a [FutureE] from the [future].
  factory FutureE(Future<Either<L, R>> future) = FutureE<L, R>._;

  /// Creates a [FutureE] with a value from the [provider].
  factory FutureE.provide(Future<Either<L, R>> Function() provider) {
    requireNotNull(provider, name: 'provider');
    return FutureE<L, R>(provider());
  }

  /// Maps a right value inside an [Either] to another value.
  @nonVirtual
  FutureE<L, T> map<T>(Future<T> Function(R) mapper) {
    requireNotNull(mapper, name: 'mapper');
    final mappedFuture = _delegate.then((either) {
      return either.fold(
        ifLeft: (value) => Future.value(Either<L, T>.left(value)),
        ifRight: (value) => mapper(value).then((it) => Either<L, T>.right(it)),
      );
    });
    return FutureE<L, T>(mappedFuture);
  }

  /// Maps a value inside an [Either] to another [Either].
  @nonVirtual
  FutureE<L, T> flatMap<T>(Future<Either<L, T>> Function(R) mapper) {
    requireNotNull(mapper, name: 'mapper');
    final mappedFuture = _delegate.then((either) {
      return either.fold(
        ifLeft: (value) => Future.value(Either<L, T>.left(value)),
        ifRight: (value) => mapper(value),
      );
    });
    return FutureE<L, T>(mappedFuture);
  }

  /// Executes the [mapper] and wraps the result in an [Either] if the [Either] is left sided.
  @nonVirtual
  FutureE<L, R> recover(Future<R> Function(L) mapper) {
    requireNotNull(mapper, name: 'mapper');
    final mappedFuture = _delegate.then((either) {
      return either.fold(
        ifLeft: (value) => mapper(value).then((it) => Either<L, R>.right(it)),
        ifRight: (value) => Future.value(Either<L, R>.right(value)),
      );
    });
    return FutureE<L, R>(mappedFuture);
  }

  /// Executes the [mapper] if the [Either] is left sided.
  @nonVirtual
  FutureE<L, R> flatRecover(Future<Either<L, R>> Function(L) mapper) {
    requireNotNull(mapper, name: 'mapper');
    final mappedFuture = _delegate.then((either) {
      return either.fold(
        ifLeft: (value) => mapper(value),
        ifRight: (value) => Future.value(Either<L, R>.right(value)),
      );
    });
    return FutureE<L, R>(mappedFuture);
  }

  @override
  Stream<Either<L, R>> asStream() => _delegate.asStream();

  @override
  Future<Either<L, R>> catchError(Function onError, {bool Function(Object error) test}) {
    return _delegate.catchError(onError, test: test);
  }

  @override
  Future<U> then<U>(FutureOr<U> Function(Either<L, R> value) onValue, {Function onError}) {
    return _delegate.then(onValue, onError: onError);
  }

  @override
  Future<Either<L, R>> timeout(Duration timeLimit, {FutureOr<Either<L, R>> Function() onTimeout}) {
    return _delegate.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<Either<L, R>> whenComplete(FutureOr Function() action) {
    return _delegate.whenComplete(action);
  }
}

// ignore: public_member_api_docs
extension FutureEithers<L, R> on Future<Either<L, R>> {
  /// Creates a [FutureE] from this [future].
  FutureE<L, R> toFutureE() => FutureE<L, R>(this);
}
