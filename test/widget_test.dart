import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/errors/failures.dart';

void main() {
  group('E-commerce Architecture Unit Tests', () {
    test('ServerFailure equatable comparison returns true for identical error payloads', () {
      const failure1 = ServerFailure('Server unreachable. Please check API logs.');
      const failure2 = ServerFailure('Server unreachable. Please check API logs.');
      expect(failure1, equals(failure2));
    });

    test('NetworkFailure default message mapping', () {
      const failure = NetworkFailure();
      expect(failure.message, equals('No Internet Connection'));
    });
  });
}
