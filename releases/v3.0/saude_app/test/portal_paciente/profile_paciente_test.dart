import 'package:flutter_test/flutter_test.dart';

/// Replica o cálculo de `_iniciais` em `_ProfileScreenState._carregarPerfil`.
/// Retorna as primeiras letras do primeiro e último nome, em maiúsculas.
/// Nome com apenas uma palavra → primeira letra. String vazia → '?'.
String calcularIniciais(String nome) {
  final partes = nome.trim().split(' ');
  if (nome.trim().isEmpty) return '?';
  if (partes.length >= 2) {
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
  return nome.trim()[0].toUpperCase();
}

/// Replica `_verificarSincronizacaoPush`:
/// Devolve o novo estado do toggle "Notificações (Geral)".
/// Regra: Push = true se e só se Email E SMS estiverem ambos a true.
bool calcularEstadoPushGeral({
  required bool notifEmail,
  required bool notifSMS,
}) {
  return notifEmail && notifSMS;
}

/// Replica `_atualizarPushGeral`:
/// Quando o toggle Geral muda, Email e SMS acompanham.
/// Devolve o novo estado dos três toggles.
({bool push, bool email, bool sms}) aplicarPushGeral(bool novoValor) {
  return (push: novoValor, email: novoValor, sms: novoValor);
}

/// Replica `buildPreferencePayload` de `_guardarPreferencia`.
Map<String, dynamic> buildPreferencePayload({
  required String userId,
  required String campo,
  required bool valor,
}) {
  return {'user_id': userId, campo: valor};
}

/// Replica a validação de nome em `_guardarAlteracoes`.
/// Retorna mensagem de erro se inválido, null se válido.
String? validarNome(String nome) {
  if (nome.trim().isEmpty) return 'O nome não pode estar vazio.';
  return null;
}

/// Replica a construção do payload para o UPDATE na tabela 'users'.
/// Telefone ou morada vazios → null (não inserir string vazia na BD).
Map<String, dynamic> buildUpdatePayload({
  required String nome,
  required String telefone,
  required String morada,
}) {
  return {
    'name': nome,
    'phone': telefone.trim().isEmpty ? null : telefone.trim(),
    'address': morada.trim().isEmpty ? null : morada.trim(),
  };
}
//  TESTES

void main() {
  group('ProfileScreen - cálculo de iniciais do avatar do paciente', () {
    // TESTE 1 - Nome e apelido → duas iniciais maiúsculas
    // Caso mais comum: exibido no círculo verde do topo do perfil.
    test('nome e apelido devolvem duas iniciais em maiúscula', () {
      expect(calcularIniciais('Ana Lima'), equals('AL'));
    });
    // TESTE 2 - Nome composto (três palavras) usa primeiro e último token
    test('nome com três palavras usa primeira e última inicial', () {
      expect(calcularIniciais('Maria João Santos'), equals('MS'));
    });
    // TESTE 3 - Apenas um nome → primeira letra em maiúscula
    test('nome de uma palavra devolve apenas a primeira letra', () {
      expect(calcularIniciais('Rui'), equals('R'));
    });
    // TESTE 4 - Nome com espaços extra no início/fim - trim não quebra
    test('espaços extra no início e fim são ignorados', () {
      expect(calcularIniciais('  Carlos Mendes  '), equals('CM'));
    });
    // TESTE 5 - String vazia (BD devolveu null→'') → fallback '?'
    // Evita crash no Text widget quando o utilizador não tem nome definido.
    test('string vazia devolve "?"', () {
      expect(calcularIniciais(''), equals('?'));
    });
    // TESTE 6 - Só espaços → equivalente a vazio → '?'
    test('string só de espaços devolve "?"', () {
      expect(calcularIniciais('   '), equals('?'));
    });
    // TESTE 7 - Nome em minúscula → devolvido em maiúscula
    test('nome em minúscula é capitalizado corretamente', () {
      expect(calcularIniciais('pedro alves'), equals('PA'));
    });
  });

  group('ProfileScreen - sincronização do toggle "Notificações (Geral)"', () {
    // TESTE 8 - Email ON + SMS ON → Push Geral deve ligar

    // Regra central: Push só fica true se AMBOS estiverem ativos.
    test('push geral liga quando email e SMS estão ambos ativos', () {
      final push = calcularEstadoPushGeral(notifEmail: true, notifSMS: true);
      expect(
        push,
        isTrue,
        reason:
            'Com email e SMS ligados, o toggle geral deve sincronizar para true',
      );
    });
    // TESTE 9 - Email ON + SMS OFF → Push Geral deve desligar
    test('push geral desliga quando SMS está desligado', () {
      final push = calcularEstadoPushGeral(notifEmail: true, notifSMS: false);
      expect(push, isFalse);
    });
    // TESTE 10 - Email OFF + SMS ON → Push Geral deve desligar
    test('push geral desliga quando email está desligado', () {
      final push = calcularEstadoPushGeral(notifEmail: false, notifSMS: true);
      expect(push, isFalse);
    });
    // TESTE 11 - Ambos OFF → Push Geral desligado
    test(
      'push geral permanece desligado quando email e SMS estão desligados',
      () {
        final push = calcularEstadoPushGeral(
          notifEmail: false,
          notifSMS: false,
        );
        expect(push, isFalse);
      },
    );
    // TESTE 12 - Toggle Geral para true → email e SMS acompanham
    test('ligar toggle geral propaga true para email e SMS', () {
      final resultado = aplicarPushGeral(true);
      expect(resultado.push, isTrue);
      expect(resultado.email, isTrue);
      expect(resultado.sms, isTrue);
    });
    // TESTE 13 - Toggle Geral para false → email e SMS acompanham
    test('desligar toggle geral propaga false para email e SMS', () {
      final resultado = aplicarPushGeral(false);
      expect(resultado.push, isFalse);
      expect(resultado.email, isFalse);
      expect(resultado.sms, isFalse);
    });
  });


  group('ProfileScreen - payload de preferências de notificação', () {
    const uid = 'patient-uuid-123';
    // TESTE 14 - email_notifications → payload correto sem chaves extra
    test('email_notifications true → apenas essa chave além de user_id', () {
      final payload = buildPreferencePayload(
        userId: uid,
        campo: 'email_notifications',
        valor: true,
      );
      expect(payload['user_id'], equals(uid));
      expect(payload['email_notifications'], isTrue);
      expect(payload.containsKey('sms_notifications'), isFalse);
      expect(payload.containsKey('push_notifications'), isFalse);
    });

    // TESTE 15 - sms_notifications false → valor persiste como false, não null
    // Importante: null e false têm semânticas diferentes no upsert do Supabase.
    test('sms_notifications false → valor false, não null', () {
      final payload = buildPreferencePayload(
        userId: uid,
        campo: 'sms_notifications',
        valor: false,
      );
      expect(payload['sms_notifications'], isFalse);
      expect(payload['sms_notifications'], isNotNull);
    });

    // TESTE 16 - reminder_24h → user_id sempre presente (necessário para upsert)
    test('user_id está sempre presente em todos os campos de preferência', () {
      for (final campo in [
        'email_notifications',
        'sms_notifications',
        'push_notifications',
        'reminder_24h',
        'newsletter_optin',
      ]) {
        final p = buildPreferencePayload(
          userId: uid,
          campo: campo,
          valor: true,
        );
        expect(
          p.containsKey('user_id'),
          isTrue,
          reason:
              'user_id em falta para campo=$campo - upsert vai falhar sem ele',
        );
      }
    });
  });

  group('PatientEditProfileScreen - validação do nome antes do UPDATE', () {
    // TESTE 17 - Nome preenchido → sem erro

    test('nome válido não retorna erro', () {
      expect(
        validarNome('Ana Lima'),
        isNull,
        reason: 'Nome preenchido deve passar a validação',
      );
    });

    // TESTE 18 - Nome vazio → mensagem de erro correta
    // Se não validado, o UPDATE insere NULL em `users.name`, quebrando
    // saudações, iniciais e exibições em todo o sistema.
    test('nome vazio retorna mensagem de erro adequada', () {
      expect(validarNome(''), equals('O nome não pode estar vazio.'));
    });

    // TESTE 19 - Nome só de espaços → equivalente a vazio → erro
    test('nome só de espaços é tratado como vazio', () {
      expect(
        validarNome('   '),
        isNotNull,
        reason: 'Trim deve ser aplicado antes da validação',
      );
    });
  });

  group('PatientEditProfileScreen - construção do payload para o UPDATE', () {
    // TESTE 20 - Payload completo: todos os campos preenchidos
    test('payload com todos os campos devolve valores corretos', () {
      final payload = buildUpdatePayload(
        nome: 'Ana Lima',
        telefone: '912345678',
        morada: 'Rua das Flores, 10',
      );
      expect(payload['name'], equals('Ana Lima'));
      expect(payload['phone'], equals('912345678'));
      expect(payload['address'], equals('Rua das Flores, 10'));
    });

    // TESTE 21 - Telefone vazio → null no payload (não string vazia)
    // String vazia quebraria validações de formato de telefone na BD.
    test('telefone vazio é normalizado para null', () {
      final payload = buildUpdatePayload(
        nome: 'Ana Lima',
        telefone: '',
        morada: 'Rua das Flores, 10',
      );
      expect(
        payload['phone'],
        isNull,
        reason: 'Campo phone vazio deve ser null, não string vazia',
      );
    });

    // TESTE 22 - Morada vazia → null no payload
    test('morada vazia é normalizada para null', () {
      final payload = buildUpdatePayload(
        nome: 'Ana Lima',
        telefone: '912345678',
        morada: '',
      );
      expect(payload['address'], isNull);
    });

    // TESTE 23 - Telefone e morada com só espaços → null após trim
    test('telefone e morada com só espaços são normalizados para null', () {
      final payload = buildUpdatePayload(
        nome: 'Ana Lima',
        telefone: '   ',
        morada: '   ',
      );
      expect(payload['phone'], isNull);
      expect(payload['address'], isNull);
    });

    // TESTE 24 - Nome nunca está ausente do payload
    test('campo "name" está sempre presente no payload do UPDATE', () {
      final payload = buildUpdatePayload(
        nome: 'João Ferreira',
        telefone: '',
        morada: '',
      );
      expect(payload.containsKey('name'), isTrue);
      expect(payload['name'], equals('João Ferreira'));
    });
  });
}
