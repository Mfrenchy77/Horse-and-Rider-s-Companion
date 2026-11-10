import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';

void main() {
  group('Email', () {
    for (final value in [
      'rider@example.com',
      'first.last+training@my-stable.example.co.uk',
      'rider@horse-ranch.com',
    ]) {
      test('accepts $value', () => expect(Email.dirty(value).isValid, isTrue));
    }
    for (final value in [
      '',
      'rider',
      '@example.com',
      'rider@',
      'rider@example.com trailing',
      'rider@example.com@other.com',
      ' rider@example.com',
      'rider@example.com\n',
    ]) {
      test('rejects ${value.replaceAll('\n', r'\n')}', () {
        expect(Email.dirty(value).isValid, isFalse);
      });
    }
  });

  group('Password', () {
    for (final value in ['', 'short']) {
      test('rejects "$value"', () {
        expect(Password.dirty(value).isValid, isFalse);
      });
    }
    for (final value in ['secret', 'a much longer password']) {
      test('accepts "$value"', () {
        expect(Password.dirty(value).isValid, isTrue);
      });
    }
    test('requires confirmation to match', () {
      expect(
        const ConfirmedPassword.dirty(password: 'secret', value: 'other')
            .isValid,
        isFalse,
      );
      expect(
        const ConfirmedPassword.dirty(password: 'secret', value: 'secret')
            .isValid,
        isTrue,
      );
    });
  });

  group('Name', () {
    for (final value in ['', 'Al', 'alice', 'Alice1', '   ']) {
      test('rejects "$value"', () {
        expect(Name.dirty(value).isValid, isFalse);
      });
    }
    for (final value in ['Alice', 'Alice Smith']) {
      test('accepts "$value"', () {
        expect(Name.dirty(value).isValid, isTrue);
      });
    }
  });

  group('URL', () {
    for (final value in [
      'https://example.com',
      'http://example.com/path?q=1',
    ]) {
      test('accepts $value', () => expect(Url.dirty(value).isValid, isTrue));
    }
    for (final value in [
      '',
      'example.com',
      'https://',
      'http://[broken',
      'javascript:alert(1)',
      'ftp://example.com',
      '//example.com',
    ]) {
      test('rejects $value without throwing', () {
        expect(Url.dirty(value).isValid, isFalse);
      });
    }
  });

  group('Zip code', () {
    for (final value in ['92101', '01234', '92101-1234']) {
      test(
        'accepts $value',
        () => expect(ZipCode.dirty(value).isValid, isTrue),
      );
    }
    for (final value in ['', '9210', '921011', 'ABCDE', '92101-123']) {
      test(
        'rejects $value',
        () => expect(ZipCode.dirty(value).isValid, isFalse),
      );
    }
  });

  group('Location range', () {
    for (final value in [0, 1, 99, 100]) {
      test('accepts $value', () {
        expect(LocationRange.dirty(value).isValid, isTrue);
      });
    }
    for (final value in [-1, 101]) {
      test('rejects $value', () {
        expect(LocationRange.dirty(value).isValid, isFalse);
      });
    }
  });

  group('Nonnegative number', () {
    for (final value in [0, 1, 100000]) {
      test(
        'accepts $value',
        () => expect(Numberz.dirty(value).isValid, isTrue),
      );
    }
    test('rejects negative values', () {
      expect(const Numberz.dirty(-1).isValid, isFalse);
    });
  });

  test('required text rejects whitespace', () {
    expect(const SingleWord.dirty('   ').isValid, isFalse);
    expect(const SingleWord.dirty('Training notes').isValid, isTrue);
  });
}
