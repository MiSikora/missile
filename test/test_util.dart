import 'package:bullseye/src/utils.dart';
import 'package:test/test.dart';

const isError = TypeMatcher<Error>();

// ignore: type_annotate_public_apis
final throwsError = throwsA(isError);

const isNoSuchElementException = TypeMatcher<NoSuchElementException>();

// ignore: type_annotate_public_apis
final throwsNoSuchElementException = throwsA(isNoSuchElementException);
