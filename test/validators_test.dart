import 'package:agrolink/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('acepta correos válidos', () {
      expect(Validators.email('ana@correo.com'), isNull);
      expect(Validators.email('  ana@correo.com  '), isNull);
    });

    test('rechaza vacío y malformados', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('ana'), isNotNull);
      expect(Validators.email('ana@correo'), isNotNull);
    });
  });

  group('Validators.newPassword (misma regla que el backend)', () {
    test('acepta 8+ con mayúscula, minúscula y número', () {
      expect(Validators.newPassword('Secreta123'), isNull);
    });

    test('rechaza cortas, sin mayúsculas o sin número', () {
      expect(Validators.newPassword('Ab1'), isNotNull);
      expect(Validators.newPassword('secreta123'), isNotNull);
      expect(Validators.newPassword('SECRETA123'), isNotNull);
      expect(Validators.newPassword('SecretaSecreta'), isNotNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('acepta con coma de miles y rechaza cero o texto', () {
      expect(Validators.positiveNumber('1,500'), isNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
      expect(Validators.positiveNumber(null), isNotNull);
    });
  });
}
