import 'package:flutter_test/flutter_test.dart';

/// Replica de `_NewUserPageState._normalizarIdentificador`
String normalizarIdentificador(String valor) =>
    valor.replaceAll(RegExp(r'\s+'), '');

/// Replica de `_NewUserPageState._mensagemConflitoDuplicado`
String mensagemConflitoDuplicado(String campo) {
  switch (campo) {
    case 'email':
      return 'Este e-mail já está registado no sistema.';
    case 'nif':
      return 'Este NIF já está registado no sistema.';
    case 'health_number':
      return 'Este número de utente já está registado.';
    default:
      return 'Já existe um utilizador com estes dados.';
  }
}

/// Replica de `_NewUserPageState._mensagemErroBaseDados`
String mensagemErroBaseDados(String pgCode, String pgMessage) {
  if (pgCode == '23505') {
    return 'Dados duplicados: e-mail, NIF ou número de utente já existem.';
  }
  if (pgCode == '42501') {
    return 'Sem permissão para criar utilizador. Inicie sessão novamente como admin.';
  }
  return 'Erro na base de dados: $pgMessage';
}

/// Replica da lógica de `_validarFormulario` (versão pura, sem setState)
/// Retorna null se válido, ou a mensagem de erro.
String? validarFormularioNovoUtilizador({
  required String nome,
  required String email,
  required String password,
  required String? tipoSelecionado,
  required String nif,
  required String healthNumber,
  required int? especialidadeSelecionada,
}) {
  if (nome.isEmpty) return 'Nome é obrigatório';
  if (email.isEmpty) return 'E-mail é obrigatório';
  if (!email.contains('@')) return 'E-mail inválido';
  if (password.isEmpty) return 'Palavra-passe é obrigatória';
  if (password.length < 6)
    return 'Palavra-passe deve ter pelo menos 6 caracteres';
  if (tipoSelecionado == null) return 'Selecione um tipo de utilizador';
  if (nif.trim().isEmpty) return 'NIF é obrigatório';
  if (tipoSelecionado != 'Paciente' && healthNumber.trim().isNotEmpty) {
    return 'Número de utente só se aplica a pacientes - deixe o campo vazio.';
  }
  if (tipoSelecionado == 'Paciente' && healthNumber.isEmpty) {
    return 'Número de utente é obrigatório para pacientes';
  }
  if (tipoSelecionado == 'Médico' && especialidadeSelecionada == null) {
    return 'Selecione uma especialidade para médicos';
  }
  return null;
}

/// Replica do roleMap em `_criarUtilizador`
String mapTipoParaRole(String tipo) {
  const roleMap = {
    'Paciente': 'patient',
    'Rececionista': 'receptionist',
    'Médico': 'doctor',
    'Admin': 'admin',
  };
  return roleMap[tipo] ?? 'patient';
}

//  TESTES

void main() {
  //  _normalizarIdentificador
  group('new_user - _normalizarIdentificador', () {
    // TESTE 1 - espaços em NIF seriam registados como valor diferente na BD
    test('remove todos os espaços internos e externos', () {
      expect(normalizarIdentificador('123 456 789'), '123456789');
      expect(normalizarIdentificador('  12345678  '), '12345678');
      expect(normalizarIdentificador('1 2 3'), '123');
    });

    // TESTE 2 - string sem espaços mantém-se igual
    test('não altera string sem espaços', () {
      expect(normalizarIdentificador('123456789'), '123456789');
    });
  });

  //  _mensagemConflitoDuplicado
  group('new_user - _mensagemConflitoDuplicado', () {
    // TESTE 3 - mensagens específicas por campo
    test('retorna mensagem correta para cada campo duplicado', () {
      expect(
        mensagemConflitoDuplicado('email'),
        'Este e-mail já está registado no sistema.',
      );
      expect(
        mensagemConflitoDuplicado('nif'),
        'Este NIF já está registado no sistema.',
      );
      expect(
        mensagemConflitoDuplicado('health_number'),
        'Este número de utente já está registado.',
      );
    });

    // TESTE 4 - campo desconhecido -> mensagem genérica
    test('retorna mensagem genérica para campo desconhecido', () {
      expect(
        mensagemConflitoDuplicado('outro'),
        'Já existe um utilizador com estes dados.',
      );
    });
  });

  //  _mensagemErroBaseDados
  group('new_user - _mensagemErroBaseDados', () {
    // TESTE 5 - 23505 (unique violation)
    test('mapeia 23505 para mensagem de dados duplicados', () {
      expect(mensagemErroBaseDados('23505', ''), contains('duplicados'));
    });

    // TESTE 6 - 42501 (RLS denied)
    test('mapeia 42501 para mensagem de sem permissão', () {
      expect(mensagemErroBaseDados('42501', ''), contains('permissão'));
    });

    // TESTE 7 - código desconhecido inclui mensagem original do Postgres
    test('inclui mensagem original para códigos desconhecidos', () {
      expect(
        mensagemErroBaseDados('99999', 'erro desconhecido X'),
        contains('erro desconhecido X'),
      );
    });
  });

  //  _validarFormulario
  group('new_user - _validarFormulario', () {
    Map<String, dynamic> base() => {
      'nome': 'Maria Santos',
      'email': 'maria@exemplo.pt',
      'password': 'segura123',
      'tipoSelecionado': 'Paciente',
      'nif': '123456789',
      'healthNumber': '12345678',
      'especialidadeSelecionada': null,
    };

    String? validar(Map<String, dynamic> d) => validarFormularioNovoUtilizador(
      nome: d['nome'],
      email: d['email'],
      password: d['password'],
      tipoSelecionado: d['tipoSelecionado'],
      nif: d['nif'],
      healthNumber: d['healthNumber'],
      especialidadeSelecionada: d['especialidadeSelecionada'],
    );

    // TESTE 8 - formulário válido de paciente
    test('retorna null para formulário de paciente completamente válido', () {
      expect(validar(base()), isNull);
    });

    // TESTE 9 - nome vazio
    test('rejeita nome vazio', () {
      expect(validar(base()..['nome'] = ''), 'Nome é obrigatório');
    });

    // TESTE 10 - e-mail sem "@" falha antes de chegar ao Supabase
    test('rejeita e-mail sem @', () {
      expect(validar(base()..['email'] = 'naoeumemail'), 'E-mail inválido');
    });

    // TESTE 11 - password curta
    test('rejeita password com menos de 6 caracteres', () {
      expect(validar(base()..['password'] = '123'), contains('6 caracteres'));
    });

    // TESTE 12 - tipo não selecionado
    test('rejeita quando tipo de utilizador é null', () {
      expect(
        validar(base()..['tipoSelecionado'] = null),
        contains('tipo de utilizador'),
      );
    });

    // TESTE 13 - NIF só com espaços (após trim fica vazio)
    test('rejeita NIF vazio', () {
      expect(validar(base()..['nif'] = '   '), 'NIF é obrigatório');
    });

    // TESTE 14 - health_number preenchido para não-paciente
    // Garante que médicos/admins não têm health_number associado erradamente.
    test('rejeita health_number preenchido para tipo não-Paciente', () {
      final d = base()
        ..['tipoSelecionado'] = 'Médico'
        ..['healthNumber'] = '12345'
        ..['especialidadeSelecionada'] = 1;
      expect(validar(d), contains('só se aplica a pacientes'));
    });

    // TESTE 15 - paciente sem número de utente
    test('rejeita paciente sem número de utente', () {
      expect(
        validar(base()..['healthNumber'] = ''),
        contains('obrigatório para pacientes'),
      );
    });

    // TESTE 16 - médico sem especialidade não aparece nas pesquisas (#11)
    test('rejeita médico sem especialidade', () {
      final d = base()
        ..['tipoSelecionado'] = 'Médico'
        ..['healthNumber'] = ''
        ..['especialidadeSelecionada'] = null;
      expect(validar(d), contains('especialidade'));
    });

    // TESTE 17 - médico com especialidade é válido
    test('aceita médico com especialidade selecionada', () {
      final d = base()
        ..['tipoSelecionado'] = 'Médico'
        ..['healthNumber'] = ''
        ..['especialidadeSelecionada'] = 2;
      expect(validar(d), isNull);
    });
  });


  //  roleMap
  group('new_user - roleMap', () {
    // TESTE 18 - mapeamento errado atribuiria permissões incorretas no Supabase
    test(
      'mapeia corretamente todos os tipos de utilizador para role de BD',
      () {
        expect(mapTipoParaRole('Paciente'), 'patient');
        expect(mapTipoParaRole('Rececionista'), 'receptionist');
        expect(mapTipoParaRole('Médico'), 'doctor');
        expect(mapTipoParaRole('Admin'), 'admin');
      },
    );
  });
}
