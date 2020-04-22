import 'dart:async';

import 'package:meta/meta.dart';
import 'package:missile/missile.dart';
import 'package:missile/src/utils.dart';

/// A specialized version of a [Future] that contains an [Option].
class FutureO<T> implements Future<Option<T>> {
  final Future<Option<T>> _delegate;

  FutureO._(Future<Option<T>> future) : _delegate = requireNotNull(future);

  /// Creates a [FutureO] from the [future].
  factory FutureO(Future<Option<T>> future) = FutureO<T>._;

  /// Creates a [FutureO] with a value from the [provider].
  factory FutureO.provide(Future<Option<T>> Function() provider) {
    requireNotNull(provider, name: 'provider');
    return FutureO<T>(provider());
  }

  /// Maps a value inside an [Option] to another value.
  @nonVirtual
  FutureO<R> map<R>(Future<R> Function(T) mapper) {
    requireNotNull(mapper, name: 'mapper');
    final mappedFuture = _delegate.then((option) {
      return option.fold(
        ifNone: () => Future.value(Option<R>.none()),
        ifSome: (value) => mapper(value).then((it) => Option<R>.some(it)),
      );
    });
    return FutureO<R>(mappedFuture);
  }

  /// Maps a value inside an [Option] to another [Option].
  @nonVirtual
  FutureO<R> flatMap<R>(Future<Option<R>> Function(T) mapper) {
    requireNotNull(mapper, name: 'mapper');
    final mappedFuture = _delegate.then((option) {
      return option.fold(
        ifNone: () => Future.value(Option<R>.none()),
        ifSome: (value) => mapper(value),
      );
    });
    return FutureO<R>(mappedFuture);
  }

  @override
  Stream<Option<T>> asStream() => _delegate.asStream();

  @override
  Future<Option<T>> catchError(Function onError, {bool Function(Object error) test}) {
    return _delegate.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(Option<T> value) onValue, {Function onError}) {
    return _delegate.then(onValue, onError: onError);
  }

  @override
  Future<Option<T>> timeout(Duration timeLimit, {FutureOr<Option<T>> Function() onTimeout}) {
    return _delegate.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<Option<T>> whenComplete(FutureOr Function() action) {
    return _delegate.whenComplete(action);
  }
}

// ignore: public_member_api_docs
extension FutureOptions<T> on Future<Option<T>> {
  /// Creates a [FutureO] from this [Future].
  FutureO<T> toFutureO() => FutureO<T>(this);
}
