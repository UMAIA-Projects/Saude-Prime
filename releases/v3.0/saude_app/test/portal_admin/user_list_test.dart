import 'package:flutter_test/flutter_test.dart';

/// Replica de `_UsersListPageState._roleLabel`
String roleLabel(String role) {
  switch (role) {
    case 'doctor':
      return 'Médico';
    case 'receptionist':
      return 'Receção';
    case 'admin':
      return 'Admin';
    default:
      return 'Paciente';
  }
}

/// Replica de `_UsersListPageState._initials`
String initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2)
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return name.substring(0, 2).toUpperCase();
}

/// Replica de `_UsersListPageState._sinceLabel`
String sinceLabel(String? isoDate) {
  if (isoDate == null) return '-';
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return '-';
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

/// Replica do filtro de tabs + pesquisa de `_UsersListPageState`
List<Map<String, dynamic>> filtrarPorTab(
  List<Map<String, dynamic>> users,
  int tab,
  String pesquisa,
) {
  List<Map<String, dynamic>> filtered;
  switch (tab) {
    case 1:
      filtered = users.where((u) => u['role'] == 'patient').toList();
      break;
    case 2:
      filtered = users.where((u) => u['role'] == 'doctor').toList();
      break;
    case 3:
      filtered = users.where((u) => u['role'] == 'admin').toList();
      break;
    default:
      filtered = List.from(users);
  }
  if (pesquisa.isEmpty) return filtered;
  final q = pesquisa.toLowerCase();
  return filtered.where((u) {
    final name = (u['name'] as String? ?? '').toLowerCase();
    final email = (u['email'] as String? ?? '').toLowerCase();
    return name.contains(q) || email.contains(q);
  }).toList();
}

//  TESTES

void main() {
  //  _roleLabel
  group('users_list - _roleLabel', () {
    // TESTE 1 - mapeamento correto de todos os roles
    test('converte roles da BD para labels em português', () {
      expect(roleLabel('doctor'), 'Médico');
      expect(roleLabel('receptionist'), 'Receção');
      expect(roleLabel('admin'), 'Admin');
      expect(roleLabel('patient'), 'Paciente');
    });
  });

  //  _initials
  group('users_list - _initials', () {
    // TESTE 2 - nome com dois tokens
    test('extrai iniciais de primeiro e último nome', () {
      expect(initials('Carlos Ferreira'), 'CF');
    });

    // TESTE 3 - nome único usa os dois primeiros caracteres
    test('usa dois primeiros caracteres para nome de uma palavra', () {
      expect(initials('Admin'), 'AD');
    });

    // TESTE 4 - nome composto: primeiro e último token
    test('usa primeiro e último token em nomes compostos', () {
      expect(initials('Maria de Fátima Costa'), 'MC');
    });
  });

  //  _sinceLabel
  group('users_list - _sinceLabel', () {
    // TESTE 5 - formata ISO para "Mês Ano" em PT
    test('formata data ISO como "Mês Ano" em português', () {
      expect(sinceLabel('2025-01-15T10:00:00'), 'Jan 2025');
      expect(sinceLabel('2024-12-01T00:00:00'), 'Dez 2024');
      expect(sinceLabel('2026-06-09T09:30:00'), 'Jun 2026');
    });

    // TESTE 6 - null - traço
    test('retorna "-" para data null', () {
      expect(sinceLabel(null), '-');
    });

    // TESTE 7 - string inválida - traço
    test('retorna "-" para string não-ISO', () {
      expect(sinceLabel('nao-e-data'), '-');
    });
  });

 
  //  filtrarPorTab  (kanban #11 - Pesquisa de Médicos)
  group('users_list - filtrarPorTab', () {
    final users = [
      {'name': 'Ana Lima', 'email': 'ana@x.pt', 'role': 'patient'},
      {'name': 'Dr. Rui', 'email': 'rui@x.pt', 'role': 'doctor'},
      {'name': 'Sara Admin', 'email': 'sara@x.pt', 'role': 'admin'},
      {'name': 'João Marques', 'email': 'joao@x.pt', 'role': 'patient'},
      {'name': 'Dr. Marta', 'email': 'marta@x.pt', 'role': 'doctor'},
    ];

    // TESTE 8 - tab Todos
    test('tab Todos devolve todos os utilizadores', () {
      expect(filtrarPorTab(users, 0, '').length, 5);
    });

    // TESTE 9 - tab Pacientes
    test('tab Pacientes devolve apenas pacientes', () {
      final r = filtrarPorTab(users, 1, '');
      expect(r.length, 2);
      expect(r.every((u) => u['role'] == 'patient'), isTrue);
    });

    // TESTE 10 - tab Médicos
    test('tab Médicos devolve apenas médicos', () {
      final r = filtrarPorTab(users, 2, '');
      expect(r.length, 2);
      expect(r.every((u) => u['role'] == 'doctor'), isTrue);
    });

    // TESTE 11 - pesquisa por nome (case-insensitive)
    // Crítico para o kanban #11 - pesquisa deve ignorar maiúsculas/minúsculas.
    test('filtra por pesquisa de nome parcial ignorando maiúsculas', () {
      final r = filtrarPorTab(users, 0, 'marta');
      expect(r.length, 1);
      expect(r.first['name'], 'Dr. Marta');
    });

    // TESTE 12 - pesquisa por e-mail parcial
    test('filtra por pesquisa de e-mail parcial', () {
      final r = filtrarPorTab(users, 0, 'joao@');
      expect(r.length, 1);
      expect(r.first['name'], 'João Marques');
    });

    // TESTE 13 - pesquisa sem resultados
    test('devolve lista vazia se pesquisa não encontra nenhum utilizador', () {
      expect(filtrarPorTab(users, 0, 'zzznaoexiste'), isEmpty);
    });

    // TESTE 14 - tab + pesquisa combinados
    test('tab e pesquisa funcionam em conjunto', () {
      final r = filtrarPorTab(users, 2, 'rui');
      expect(r.length, 1);
      expect(r.first['role'], 'doctor');
    });
  });
}
