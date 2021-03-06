import 'package:missile/missile.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  group('Either', () {
    group('created as exception safe', () {
      test('yields a provided value', () {
        expect(
          Either<String, int>.safeOnException(
            provider: () => 1,
            onException: (exception) => throw exception,
          ),
          const Either<String, int>.right(1),
        );
      });

      test('catches exceptions', () {
        expect(
          Either<String, int>.safeOnException(
            provider: () => throw const FormatException('message'),
            onException: (exception) => (exception as FormatException).message,
          ),
          const Either<String, int>.left('message'),
        );
      });

      test('fails on errors', () {
        expect(
          () => Either<String, int>.safeOnException(
            provider: () => throw Error(),
            onException: (exception) => 'Exception',
          ),
          throwsError,
        );
      });
    });

    group('created as error safe', () {
      test('yields a provided value', () {
        expect(
          Either<String, int>.safeOnError(
            provider: () => 1,
            onError: (error) => throw error,
          ),
          const Either<String, int>.right(1),
        );
      });

      test('catches errors', () {
        expect(
          Either<String, int>.safeOnError(
            provider: () => throw StateError('message'),
            onError: (error) => (error as StateError).message,
          ),
          const Either<String, int>.left('message'),
        );
      });

      test('fails on exceptions', () {
        expect(
          () => Either<String, int>.safeOnError(
            provider: () => throw Exception(),
            onError: (error) => 'Error',
          ),
          throwsException,
        );
      });
    });

    group('created as safe with provider', () {
      test('yields a provided value', () {
        expect(
          Either<String, int>.tryOrElseProvide(
            provider: () => 1,
            orElse: (_) => throw Error(),
          ),
          const Either<String, int>.right(1),
        );
      });

      test('catches exceptions', () {
        expect(
          Either<String, int>.tryOrElseProvide(
            provider: () => throw const FormatException('message'),
            orElse: (e) => (e.getOrError(() => Error()) as FormatException).message,
          ),
          const Either<String, int>.left('message'),
        );
      });

      test('catches error', () {
        expect(
          Either<String, int>.tryOrElseProvide(
            provider: () => throw StateError('message'),
            orElse: (e) => (e.swap().getOrException(() => Exception()) as StateError).message,
          ),
          const Either<String, int>.left('message'),
        );
      });
    });

    group('created as safe with value', () {
      test('yields a provided value', () {
        expect(
          Either<String, int>.tryOrElse(
            provider: () => 1,
            orElse: 'message',
          ),
          const Either<String, int>.right(1),
        );
      });

      test('catches exceptions', () {
        expect(
          Either<String, int>.tryOrElse(
            provider: () => throw const FormatException('message'),
            orElse: 'message',
          ),
          const Either<String, int>.left('message'),
        );
      });

      test('catches error', () {
        expect(
          Either<String, int>.tryOrElse(
            provider: () => throw StateError('message'),
            orElse: 'message',
          ),
          const Either<String, int>.left('message'),
        );
      });
    });
  });

  group('Effect', () {
    test('fx computes the value if all bounded are right', () {
      final sum = Either.fx<String, int>((effects) {
        final one = const Either<String, int>.right(1).bind(effects);
        final two = const Either<String, int>.right(2).bind(effects);
        final three = const Either<String, int>.right(3).bind(effects);
        return one + two + three;
      });
      expect(sum, const Either<String, int>.right(6));
    });

    test('fx stops computation if any of the bounded values is left', () {
      final sum = Either.fx<String, int>((effects) {
        final one = const Either<String, int>.right(1).bind(effects);
        final two = const Either<String, int>.left('hello').bind(effects);
        final three = const Either<String, int>.right(3).bind(effects);
        return one + two + three;
      });
      expect(sum, const Either<String, int>.left('hello'));
    });

    test('fx rethrows exception', () {
      expect(
        () => Either.fx<String, int>((effects) {
          final one = const Either<String, int>.right(1).bind(effects);
          final two = const Either<String, int>.left('hello').getOrException(() => Exception());
          final three = const Either<String, int>.right(3).bind(effects);
          return one + two + three;
        }),
        throwsException,
      );
    });

    test('fx rethrows error', () {
      expect(
        () => Either.fx<String, int>((effects) {
          final one = const Either<String, int>.right(1).bind(effects);
          final two = const Either<String, int>.left('hello').getOrError(() => Error());
          final three = const Either<String, int>.right(3).bind(effects);
          return one + two + three;
        }),
        throwsError,
      );
    });

    test('async fx computes the value if all bounded are right', () {
      final sum = Either.fxAsync((effects) async {
        final awaitedOne = await Future.value(const Either<String, int>.right(1));
        final awaitedTwo = await Future.value(const Either<String, int>.right(2));
        final awaitedThree = await Future.value(const Either<String, int>.right(3));
        final one = awaitedOne.bind(effects);
        final two = awaitedTwo.bind(effects);
        final three = awaitedThree.bind(effects);
        return one + two + three;
      });
      expect(sum, completion(const Either<String, int>.right(6)));
    });

    test('async fx stops computation if any of the bounded values is left', () {
      final sum = Either.fxAsync((effects) async {
        final awaitedOne = await Future.value(const Either<String, int>.right(1));
        final awaitedTwo = await Future.value(const Either<String, int>.left('hello'));
        final awaitedThree = await Future.value(const Either<String, int>.right(3));
        final one = awaitedOne.bind(effects);
        final two = awaitedTwo.bind(effects);
        final three = awaitedThree.bind(effects);
        return one + two + three;
      });
      expect(sum, completion(const Either<String, int>.left('hello')));
    });

    test('async fx rethrows future exception', () {
      expect(
        () => Either.fxAsync<String, int>((effects) async {
          final awaitedOne = await Future.error(Exception());
          final awaitedTwo = await Future.value(const Either<String, int>.right(2));
          final awaitedThree = await Future.value(const Either<String, int>.right(3));
          final one = awaitedOne.bind(effects);
          final two = awaitedTwo.bind(effects);
          final three = awaitedThree.bind(effects);
          return one + two + three;
        }),
        throwsException,
      );
    });

    test('async fx rethrows future error', () {
      expect(
        () => Either.fxAsync<String, int>((effects) async {
          final awaitedOne = await Future.error(Error());
          final awaitedTwo = await Future.value(const Either<String, int>.right(2));
          final awaitedThree = await Future.value(const Either<String, int>.right(3));
          final one = awaitedOne.bind(effects);
          final two = awaitedTwo.bind(effects);
          final three = awaitedThree.bind(effects);
          return one + two + three;
        }),
        throwsError,
      );
    });

    test('async fx rethrows exception', () {
      expect(
        () => Either.fxAsync<String, int>((effects) async {
          final awaitedOne = await Future.value(const Either<String, int>.right(1));
          final awaitedTwo = await Future.value(const Either<String, int>.left('hello'));
          final awaitedThree = await Future.value(const Either<String, int>.right(3));
          final one = awaitedOne.bind(effects);
          final two = awaitedTwo.getOrException(() => Exception());
          final three = awaitedThree.bind(effects);
          return one + two + three;
        }),
        throwsException,
      );
    });

    test('async fx rethrows error', () {
      expect(
        () => Either.fxAsync<String, int>((effects) async {
          final awaitedOne = await Future.value(const Either<String, int>.right(1));
          final awaitedTwo = await Future.value(const Either<String, int>.left('hello'));
          final awaitedThree = await Future.value(const Either<String, int>.right(3));
          final one = awaitedOne.bind(effects);
          final two = awaitedTwo.getOrError(() => Error());
          final three = awaitedThree.bind(effects);
          return one + two + three;
        }),
        throwsError,
      );
    });
  });

  group('Right', () {
    const either = Either<String, int>.right(1);

    test('is right', () {
      expect(either.isLeft, false);
      expect(either.isRight, true);
    });

    test('does not return alternative provided value', () {
      expect(either.getOrElseProvide(() => 2), 1);
    });

    test('does not return alternative value', () {
      expect(either.getOrElse(2), 1);
    });

    test('does not throw provided exeption', () {
      expect(either.getOrException(() => Exception()), 1);
    });

    test('does not throw provided error', () {
      expect(either.getOrError(() => Error()), 1);
    });

    test('can be filtered', () {
      expect(
        either.filterOrElseProvide(predicate: (it) => it != 1, orElse: () => 'foo'),
        const Either<String, int>.left('foo'),
      );
      expect(
        either.filterOrElse(predicate: (it) => it != 1, orElse: 'foo'),
        const Either<String, int>.left('foo'),
      );
      expect(
        either.filterNotOrElseProvide(predicate: (it) => it == 1, orElse: () => 'foo'),
        const Either<String, int>.left('foo'),
      );
      expect(
        either.filterNotOrElse(predicate: (it) => it == 1, orElse: 'foo'),
        const Either<String, int>.left('foo'),
      );
    });

    test('can be not filtered', () {
      expect(
        either.filterOrElseProvide(predicate: (it) => it == 1, orElse: () => throw Error()),
        const Either<String, int>.right(1),
      );
      expect(
        either.filterOrElse(predicate: (it) => it == 1, orElse: 'foo'),
        const Either<String, int>.right(1),
      );
      expect(
        either.filterNotOrElseProvide(predicate: (it) => it != 1, orElse: () => throw Error()),
        const Either<String, int>.right(1),
      );
      expect(
        either.filterNotOrElse(predicate: (it) => it != 1, orElse: 'foo'),
        const Either<String, int>.right(1),
      );
    });

    test('uses right fold provider', () {
      expect(either.fold(ifLeft: (_) => throw Error(), ifRight: (it) => '$it'), '1');
    });

    test('can be transformed', () {
      final value = either.transform((it) => '${it.getOrElse(2)}');
      expect(value, '1');
    });

    test('can be swapped', () {
      expect(either.swap(), const Either<int, String>.left(1));
    });

    test('does not recover', () {
      expect(either.recover((_) => throw Error()), const Either<String, int>.right(1));
    });

    test('does not flat recover', () {
      expect(either.flatRecover((_) => throw Error()), const Either<String, int>.right(1));
    });

    test('uses right bimap mapper', () {
      final mappedEither = either.bimap(ifLeft: (_) => throw Error(), ifRight: (it) => '$it');
      expect(mappedEither, const Either<String, String>.right('1'));
    });

    test('cannot be left mapped', () {
      final mappedEither = either.mapLeft((_) => '1');
      expect(mappedEither, const Either<String, int>.right(1));
    });

    test('cannot be left flat mapped', () {
      final mappedEither = either.flatMapLeft((_) => const Either<String, int>.left('1'));
      expect(mappedEither, const Either<String, int>.right(1));
    });

    test('can be mapped', () {
      final mappedEither = either.map((it) => '$it');
      expect(mappedEither, const Either<String, String>.right('1'));
    });

    test('can be flat mapped', () {
      final mappedEither = either.flatMap((it) => const Either<String, int>.right(2));
      expect(mappedEither, const Either<String, int>.right(2));
    });

    test('uses right peek consumer', () {
      var value = '';
      either.peek(ifLeft: (_) => throw Error(), ifRight: (it) => value = '$it');
      expect(value, '1');
    });

    test('can be converted to option', () {
      expect(either.toOption(), Option<int>.some(1));
    });
  });

  group('Left', () {
    const either = Either<int, String>.left(1);

    test('is left', () {
      expect(either.isLeft, true);
      expect(either.isRight, false);
    });

    test('returns alternative provided value', () {
      expect(either.getOrElseProvide(() => '2'), '2');
    });

    test('returns alternative value', () {
      expect(either.getOrElse('2'), '2');
    });

    test('throws provided exeption', () {
      expect(() => either.getOrException(() => Exception()), throwsException);
    });

    test('throws provided error', () {
      expect(() => either.getOrError(() => Error()), throwsError);
    });

    test('is never filtered', () {
      expect(
        either.filterOrElseProvide(predicate: (it) => it != '1', orElse: () => throw Error()),
        const Either<int, String>.left(1),
      );
      expect(
        either.filterOrElse(predicate: (it) => it != '1', orElse: 2),
        const Either<int, String>.left(1),
      );
      expect(
        either.filterNotOrElseProvide(predicate: (it) => it == '1', orElse: () => throw Error()),
        const Either<int, String>.left(1),
      );
      expect(
        either.filterNotOrElse(predicate: (it) => it == '1', orElse: 2),
        const Either<int, String>.left(1),
      );
    });

    test('is always not filtered', () {
      expect(
        either.filterOrElseProvide(predicate: (it) => it == '1', orElse: () => throw Error()),
        const Either<int, String>.left(1),
      );
      expect(
        either.filterOrElse(predicate: (it) => it == '1', orElse: 2),
        const Either<int, String>.left(1),
      );
      expect(
        either.filterNotOrElseProvide(predicate: (it) => it != '1', orElse: () => throw Error()),
        const Either<int, String>.left(1),
      );
      expect(
        either.filterNotOrElse(predicate: (it) => it != '1', orElse: 2),
        const Either<int, String>.left(1),
      );
    });

    test('uses left fold provider', () {
      expect(either.fold(ifLeft: (it) => '$it', ifRight: (_) => throw Error()), '1');
    });

    test('can be transformed', () {
      final value = either.transform((it) => '${it.getOrElse('2')}');
      expect(value, '2');
    });

    test('can be swapped', () {
      expect(either.swap(), const Either<String, int>.right(1));
    });

    test('can be recovered', () {
      final recoveredEither = either.recover((it) => '$it');
      expect(recoveredEither, const Either<int, String>.right('1'));
    });

    test('can be flat recovered', () {
      final recoveredEither = either.flatRecover((it) => Either<int, String>.left(it + 1));
      expect(recoveredEither, const Either<int, String>.left(2));
    });

    test('uses left bimap mapper', () {
      final mappedEither = either.bimap(ifLeft: (it) => '$it', ifRight: (_) => throw Error());
      expect(mappedEither, const Either<String, String>.left('1'));
    });

    test('can be left mapped', () {
      final mappedEither = either.mapLeft((it) => '$it');
      expect(mappedEither, const Either<String, String>.left('1'));
    });

    test('can be left flat mapped', () {
      final mappedEither = either.flatMapLeft((it) => Either<String, String>.left('$it'));
      expect(mappedEither, const Either<String, String>.left('1'));
    });

    test('cannot be mapped', () {
      final mappedEither = either.map((_) => '2');
      expect(mappedEither, const Either<int, String>.left(1));
    });

    test('cannot be flat mapped', () {
      final mappedEither = either.flatMap((it) => const Either<int, String>.right('2'));
      expect(mappedEither, const Either<int, String>.left(1));
    });

    test('uses left peek consumer', () {
      var value = '';
      either.peek(ifLeft: (it) => value = '$it', ifRight: (_) => throw Error());
      expect(value, '1');
    });

    test('can be converted to option', () {
      expect(either.toOption(), const Option<int>.none());
    });
  });
}
