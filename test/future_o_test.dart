import 'package:missile/missile.dart';
import 'package:test/test.dart';

void main() {
  group('Some FutureO', () {
    final future = Option.some(1).toFutureO();

    test('can be mapped', () {
      expect(
        future.map((it) async => '$it'),
        completion(Option.some('1')),
      );
    });

    test('can be flat mapped', () {
      expect(
        future.flatMap((it) async => Option.some('$it')),
        completion(Option.some('1')),
      );
    });
  });

  group('None FutureO', () {
    final future = const Option<int>.none().toFutureO();

    test('cannot be mapped', () {
      expect(
        future.map((it) async => throw Error()),
        completion(const Option<String>.none()),
      );
    });

    test('cannot be flat mapped', () {
      expect(
        future.flatMap((it) async => throw Error()),
        completion(const Option<String>.none()),
      );
    });
  });
}
