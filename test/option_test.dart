import 'package:missile/missile.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  group('Option', () {
    test('some cannot be created with null', () {
      expect(() => Option.some(null), throwsArgumentError);
    });

    test('of null creates empty', () {
      expect(Option.of(null), const Option.none());
    });

    test('of value creates not empty', () {
      expect(Option.of(1), Option.some(1));
    });

    test('when creates empty if false', () {
      expect(Option.when(predicate: false, value: 1), const Option.none());
    });

    test('when creates not empty if true', () {
      expect(Option.when(predicate: true, value: 1), Option.some(1));
    });
  });

  group('Effect', () {
    test('fx computes the value if all bounded values exist', () {
      final sum = Option.fx((effects) {
        final one = Option.some(1).bind(effects);
        final two = Option.some(2).bind(effects);
        final three = Option.some(3).bind(effects);
        return one + two + three;
      });
      expect(sum, Option.some(6));
    });

    test('fx stops computation if any of the bounded values does not exist', () {
      final sum = Option.fx((effects) {
        final one = Option.some(1).bind(effects);
        final two = const Option<int>.none().bind(effects);
        final three = Option.some(3).bind(effects);
        return one + two + three;
      });
      expect(sum, const Option<int>.none());
    });

    test('fx rethrows exception', () {
      expect(
        () => Option.fx((effects) {
          final one = Option.some(1).bind(effects);
          final two = const Option<int>.none().getOrException(() => Exception());
          final three = Option.some(3).bind(effects);
          return one + two + three;
        }),
        throwsException,
      );
    });

    test('fx rethrows error', () {
      expect(
        () => Option.fx((effects) {
          final one = Option.some(1).bind(effects);
          final two = const Option<int>.none().getOrError(() => Error());
          final three = Option.some(3).bind(effects);
          return one + two + three;
        }),
        throwsError,
      );
    });

    test('async fx computes the value if all bounded values exist', () {
      final sum = Option.fxAsync((effects) async {
        final awaitedOne = await Future.value(Option.some(1));
        final awaitedTwo = await Future.value(Option.some(2));
        final awaitedThree = await Future.value(Option.some(3));
        final one = awaitedOne.bind(effects);
        final two = awaitedTwo.bind(effects);
        final three = awaitedThree.bind(effects);
        return one + two + three;
      });
      expect(sum, completion(Option.some(6)));
    });

    test('async fx stops computation if any of the bounded values does not exist', () {
      final sum = Option.fxAsync((effects) async {
        final awaitedOne = await Future.value(Option.some(1));
        final awaitedTwo = await Future.value(const Option<int>.none());
        final awaitedThree = await Future.value(Option.some(3));
        final one = awaitedOne.bind(effects);
        final two = awaitedTwo.bind(effects);
        final three = awaitedThree.bind(effects);
        return one + two + three;
      });
      expect(sum, completion(const Option<int>.none()));
    });

    test('async fx rethrows future exception', () {
      expect(
        Option.fxAsync((effects) async {
          final awaitedOne = await Future.error(Exception());
          final awaitedTwo = await Future.value(const Option<int>.none());
          final awaitedThree = await Future.value(Option.some(3));
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
        Option.fxAsync((effects) async {
          final awaitedOne = await Future.error(Error());
          final awaitedTwo = await Future.value(const Option<int>.none());
          final awaitedThree = await Future.value(Option.some(3));
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
        Option.fxAsync((effects) async {
          final awaitedOne = await Future.value(Option.some(1));
          final awaitedTwo = await Future.value(const Option<int>.none());
          final awaitedThree = await Future.value(Option.some(3));
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
        Option.fxAsync((effects) async {
          final awaitedOne = await Future.value(Option.some(1));
          final awaitedTwo = await Future.value(const Option<int>.none());
          final awaitedThree = await Future.value(Option.some(3));
          final one = awaitedOne.bind(effects);
          final two = awaitedTwo.getOrError(() => Error());
          final three = awaitedThree.bind(effects);
          return one + two + three;
        }),
        throwsError,
      );
    });
  });

  group('Some', () {
    final option = Option.some(1);

    test('is not empty', () {
      expect(option.isEmpty, false);
      expect(option.isNotEmpty, true);
    });

    test('does not return alternative provided value', () {
      expect(option.getOrElseProvide(() => 2), 1);
    });

    test('does not return alternative value', () {
      expect(option.getOrElse(2), 1);
    });

    test('does not throw provided exception', () {
      expect(option.getOrException(() => Exception()), 1);
    });

    test('does not throw provided error', () {
      expect(option.getOrError(() => Error()), 1);
    });

    test('does not use alternative provider', () {
      expect(option.orElseProvide(() => Option.some(2)), Option.some(1));
    });

    test('does not use alterntive', () {
      expect(option.orElse(Option.some(2)), Option.some(1));
    });

    test('can be filtered', () {
      expect(option.filter((it) => it != 1), const Option.none());
      expect(option.filterNot((it) => it == 1), const Option.none());
    });

    test('can be not filtered', () {
      expect(option.filter((it) => it == 1), Option.some(1));
      expect(option.filterNot((it) => it != 1), Option.some(1));
    });

    test('uses some fold provider', () {
      final value = option.fold(ifNone: () => throw Error(), ifSome: (it) => '$it');
      expect(value, '1');
    });

    test('can be transformed', () {
      final value = option.transform((it) => '${it.getOrElse(2)}');
      expect(value, '1');
    });

    test('can be mapped', () {
      final mappedOption = option.map((it) => it + 1);
      expect(mappedOption, Option.some(2));
    });

    test('can be flat mapped', () {
      final mappedOption = option.flatMap((it) => Option.some(it + 1));
      expect(mappedOption, Option.some(2));
    });

    test('uses some peek consumer', () {
      var value = '';
      option.peek(ifNone: () => throw Error(), ifSome: (it) => value = '$it');
      expect(value, '1');
    });

    test('can be converted to either', () {
      expect(option.toEither(''), const Either<String, int>.right(1));
    });
  });

  group('None', () {
    const option = Option<int>.none();

    test('is empty', () {
      expect(option.isEmpty, true);
      expect(option.isNotEmpty, false);
    });

    test('returns alternative provided value', () {
      expect(option.getOrElseProvide(() => 2), 2);
    });

    test('returns alternative value', () {
      expect(option.getOrElse(2), 2);
    });

    test('throws provided exception', () {
      expect(() => option.getOrException(() => Exception()), throwsException);
    });

    test('throws provided error', () {
      expect(() => option.getOrError(() => Error()), throwsError);
    });

    test('uses alternative provider', () {
      expect(option.orElseProvide(() => Option.some(2)), Option.some(2));
    });

    test('uses alterntive', () {
      expect(option.orElse(Option.some(2)), Option.some(2));
    });

    test('is never filtered', () {
      expect(option.filter((it) => false), const Option.none());
      expect(option.filterNot((it) => true), const Option.none());
    });

    test('is always not filtered', () {
      expect(option.filter((it) => true), const Option.none());
      expect(option.filterNot((it) => false), const Option.none());
    });

    test('uses none fold provider', () {
      final value = option.fold(ifNone: () => '1', ifSome: (it) => throw Error());
      expect(value, '1');
    });

    test('can be transformed', () {
      final value = option.transform((it) => '${it.getOrElse(1)}');
      expect(value, '1');
    });

    test('cannot be mapped', () {
      final mappedOption = option.map((it) => it + 1);
      expect(mappedOption, const Option.none());
    });

    test('uses none peek consumer', () {
      var value = '';
      option.peek(ifNone: () => value = '1', ifSome: (it) => throw Error());
      expect(value, '1');
    });

    test('can be converted to either', () {
      expect(option.toEither('2'), const Either<String, int>.left('2'));
    });
  });
}
