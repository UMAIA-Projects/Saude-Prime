import 'package:flutter_test/flutter_test.dart';

/// Replica `_ProfileState._toInitials`.
/// Retorna as primeiras letras do primeiro e último nome, em maiúsculas.
/// Nome com apenas uma palavra - primeira letra.
/// String vazia - '?'.
String toInitials(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) return '?';

  final parts = trimmedName.split(' ');
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return trimmedName[0].toUpperCase();
}

/// Replica a construção do payload usado em `_savePreference`.
///
/// Recebe o [userId], o nome da [column] e o [value] a atualizar.
/// Devolve o mapa que seria passado ao `db.from('user_preferences').upsert(...)`.
Map<String, dynamic> buildPreferencePayload({
  required String userId,
  required String column,
  required bool value,
}) {
  return {'user_id': userId, column: value};
}

// TESTES
void main() {
  // 1. _toInitials
  group('toInitials - avatar do médico', () {
    // casos normais
    test('nome e apelido → duas iniciais maiúsculas', () {
      expect(toInitials('Ana Lima'), 'AL');
    });

    test('nome composto - usa primeiro e último token', () {
      expect(toInitials('Maria João Silva'), 'MS');
    });

    test('nome com acentos - preserva o carácter acentuado em maiúscula', () {
      // O método não remove acentos, apenas capitaliza.
      expect(toInitials('álvaro Fernandes'), 'ÁF');
    });

    test('nome com espaços extra - trim não deve quebrar o resultado', () {
      expect(toInitials('  Carlos Mendes  '), 'CM');
    });

    // casos limite
    test('apenas um nome → retorna a primeira letra em maiúscula', () {
      expect(toInitials('João'), 'J');
    });

    test('nome com letra minúscula → retorna maiúscula', () {
      expect(toInitials('pedro'), 'P');
    });

    test('string vazia → retorna "?"', () {
      expect(toInitials(''), '?');
    });

    test('string só espaços → equivale a vazia → "?"', () {
      // trim() reduz a '' - mesma lógica de string vazia
      expect(toInitials('   '), '?');
    });

    test('nome com hífen (nome composto) - trata como uma palavra', () {
      // 'Ana-Maria' não tem espaço, é um só token → inicial 'A'
      expect(toInitials('Ana-Maria Costa'), 'AC');
    });
  });

  // 2. buildPreferencePayload  (_savePreference)
  group('buildPreferencePayload - upsert de preferências de notificação', () {
    const uid = 'doctor-uuid-123';

    // appointment_alerts
    test('appointment_alerts true → payload correcto', () {
      final payload = buildPreferencePayload(
        userId: uid,
        column: 'appointment_alerts',
        value: true,
      );
      expect(payload['user_id'], uid);
      expect(payload['appointment_alerts'], true);
      // não deve conter chaves não solicitadas
      expect(payload.containsKey('push_notifications'), false);
      expect(payload.containsKey('email_notifications'), false);
    });

    test('appointment_alerts false → valor persiste como false, não null', () {
      final payload = buildPreferencePayload(
        userId: uid,
        column: 'appointment_alerts',
        value: false,
      );
      expect(payload['appointment_alerts'], false);
    });

    // push_notifications
    test('push_notifications true → apenas essa chave no payload', () {
      final payload = buildPreferencePayload(
        userId: uid,
        column: 'push_notifications',
        value: true,
      );
      expect(payload['user_id'], uid);
      expect(payload['push_notifications'], true);
      expect(payload.containsKey('appointment_alerts'), false);
      expect(payload.containsKey('email_notifications'), false);
    });

    // email_notifications
    test('email_notifications false → apenas essa chave no payload', () {
      final payload = buildPreferencePayload(
        userId: uid,
        column: 'email_notifications',
        value: false,
      );
      expect(payload['user_id'], uid);
      expect(payload['email_notifications'], false);
      expect(payload.containsKey('appointment_alerts'), false);
      expect(payload.containsKey('push_notifications'), false);
    });

    // user_id sempre presente
    test('user_id é sempre incluído (necessário para onConflict)', () {
      for (final col in [
        'appointment_alerts',
        'push_notifications',
        'email_notifications',
      ]) {
        final p = buildPreferencePayload(userId: uid, column: col, value: true);
        expect(
          p.containsKey('user_id'),
          true,
          reason: 'user_id em falta para column=$col',
        );
      }
    });

    test('user_id diferente → é reflectido correctamente no payload', () {
      const outroUid = 'outro-doctor-456';
      final payload = buildPreferencePayload(
        userId: outroUid,
        column: 'appointment_alerts',
        value: true,
      );
      expect(payload['user_id'], outroUid);
    });
  });
}
