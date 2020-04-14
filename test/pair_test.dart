import 'package:bullseye/src/pair.dart';
import 'package:test/test.dart';

void main() {
  const pair = Pair(false, 1);

  test('can map first value', () {
    expect(pair.mapFirst((it) => !it), const Pair(true, 1));
  });

  test('can map second value', () {
    expect(pair.mapSecond((it) => it * 2), const Pair(false, 2));
  });

  test('can be transformed', () {
    expect(pair.transform((it) => '${it.first},${it.second}'), 'false,1');
  });

  test('can have values transformed', () {
    expect(pair.transformValues((first, second) => '$first,$second'), 'false,1');
  });
}
