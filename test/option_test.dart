import 'package:bullseye/bullseye.dart';
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
      final sum = Option.fx((binder) {
        final one = binder.bind(Option.some(1));
        final two = binder.bind(Option.some(2));
        final three = binder.bind(Option.some(3));
        return one + two + three;
      });
      expect(sum, Option.some(6));
    });

    test('fx stops computation if any of the bounded values does not exist', () {
      final sum = Option.fx((binder) {
        final one = binder.bind(Option.some(1));
        final two = binder.bind(const Option<int>.none());
        final three = binder.bind(Option.some(3));
        return one + two + three;
      });
      expect(sum, const Option<int>.none());
    });

    test('fx rethrows exception', () {
      expect(
        () => Option.fx((binder) {
          final one = binder.bind(Option.some(1));
          final two = const Option<int>.none().getOrException(() => Exception());
          final three = binder.bind(Option.some(3));
          return one + two + three;
        }),
        throwsException,
      );
    });

    test('fx rethrows error', () {
      expect(
        () => Option.fx((binder) {
          final one = binder.bind(Option.some(1));
          final two = const Option<int>.none().getOrError(() => Error());
          final three = binder.bind(Option.some(3));
          return one + two + three;
        }),
        throwsError,
      );
    });
  });

  group('Some', () {
    final option = Option.some(1);

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
  });

  group('None', () {
    const option = Option<int>.none();

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

    test('cannot be flat mapped', () {
      final mappedOption = option.flatMap((it) => Option.some(it + 1));
      expect(mappedOption, const Option.none());
    });

    test('uses none peek consumer', () {
      var value = '';
      option.peek(ifNone: () => value = '1', ifSome: (it) => throw Error());
      expect(value, '1');
    });
  });
}
