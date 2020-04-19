import 'package:missile/missile.dart';
import 'package:test/test.dart';

void main() {
  group('Right FutureE', () {
    final future = const Either<String, int>.right(1).toFutureE();

    test('can be mapped', () {
      expect(
        future.map((it) async => '$it'),
        completion(const Either<String, String>.right('1')),
      );
    });

    test('can be flat mapped', () {
      expect(
        future.flatMap((it) async => Either<String, String>.right('$it')),
        completion(const Either<String, String>.right('1')),
      );
    });

    test('does not recover', () {
      expect(
        future.recover((_) async => throw Error()),
        completion(const Either<String, int>.right(1)),
      );
    });

    test('does not flat recover', () {
      expect(
        future.flatRecover((_) async => throw Error()),
        completion(const Either<String, int>.right(1)),
      );
    });
  });

  group('Left FutureE', () {
    final future = const Either<String, int>.left('foo').toFutureE();

    test('cannot be mapped', () {
      expect(
        future.map((_) async => throw Error()),
        completion(const Either<String, int>.left('foo')),
      );
    });

    test('cannot flat mapped', () {
      expect(
        future.flatMap((_) async => throw Error()),
        completion(const Either<String, int>.left('foo')),
      );
    });

    test('can recover', () {
      expect(
        future.recover((it) async => it.length),
        completion(const Either<String, int>.right(3)),
      );
    });

    test('can flat recover', () {
      expect(
        future.flatRecover((it) async => Either<String, int>.right(it.length)),
        completion(const Either<String, int>.right(3)),
      );
    });
  });
}
