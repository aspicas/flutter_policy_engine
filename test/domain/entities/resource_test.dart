import 'package:flutter_policy_engine/src/domain/entities/resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Resource', () {
    test('holds id and empty attributes by default', () {
      final resource = Resource(id: 'dashboard');
      expect(resource.id, equals('dashboard'));
      expect(resource.attributes, isEmpty);
    });

    test('holds attributes when provided', () {
      final resource = Resource(
        id: 'report-eu',
        attributes: const {'region': 'eu', 'type': 'financial'},
      );
      expect(resource.getAttribute('region'), equals('eu'));
    });

    test('getAttribute returns null when absent', () {
      final resource = Resource(id: 'x');
      expect(resource.getAttribute('missing'), isNull);
    });

    test('hasAttribute checks key presence', () {
      final resource = Resource(id: 'x', attributes: const {'type': 'private'});
      expect(resource.hasAttribute('type'), isTrue);
      expect(resource.hasAttribute('owner'), isFalse);
    });

    test('equality by id and attributes', () {
      final a = Resource(id: 'x', attributes: const {'k': 'v'});
      final b = Resource(id: 'x', attributes: const {'k': 'v'});
      final c = Resource(id: 'y');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('id cannot be empty', () {
      expect(() => Resource(id: ''), throwsArgumentError);
    });
  });
}
