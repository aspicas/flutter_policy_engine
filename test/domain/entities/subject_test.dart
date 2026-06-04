import 'package:flutter_policy_engine/src/domain/entities/subject.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subject', () {
    test('getAttribute returns value when present', () {
      const subject = Subject(
        attributes: {'role': 'admin', 'region': 'eu'},
      );
      expect(subject.getAttribute('role'), equals('admin'));
    });

    test('getAttribute returns null when absent', () {
      const subject = Subject(attributes: {'role': 'admin'});
      expect(subject.getAttribute('department'), isNull);
    });

    test('hasAttribute returns true when key is present', () {
      const subject = Subject(attributes: {'role': 'admin'});
      expect(subject.hasAttribute('role'), isTrue);
    });

    test('hasAttribute returns false when key is absent', () {
      const subject = Subject(attributes: {});
      expect(subject.hasAttribute('role'), isFalse);
    });

    test('attributes are unmodifiable', () {
      const subject = Subject(attributes: {'role': 'admin'});
      expect(
        () => subject.attributes['x'] = 'y',
        throwsUnsupportedError,
      );
    });

    test('empty subject has no attributes', () {
      const subject = Subject(attributes: {});
      expect(subject.attributes, isEmpty);
    });

    test('equality by attributes', () {
      const a = Subject(attributes: {'role': 'admin'});
      const b = Subject(attributes: {'role': 'admin'});
      const c = Subject(attributes: {'role': 'user'});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
