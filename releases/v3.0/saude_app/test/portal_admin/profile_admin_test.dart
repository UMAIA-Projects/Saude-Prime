import 'package:flutter_test/flutter_test.dart';

//  LÓGICA EXTRAÍDA DE PRODUÇÃO  (profile_page.dart)

/// Replica de `_ProfilePageState._buildIniciais`
String buildIniciais(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  final uteis = parts.where((p) => !p.endsWith('.')).toList();
  if (uteis.length >= 2)
    return '${uteis.first[0]}${uteis.last[0]}'.toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

//  TESTES

void main() {
  group('profile_admin - _buildIniciais', () {
    // TESTE 1 - nome completo padrão
    test('extrai iniciais de nome com dois tokens', () {
      expect(buildIniciais('Ana Costa'), 'AC');
    });

    // TESTE 2 - nome composto com preposição
    // "de" não termina em "." - não é filtrado; resultado: M + F
    test('usa primeiro e último token útil em nomes com preposição', () {
      expect(buildIniciais('Maria de Fátima'), 'MF');
    });

    // TESTE 3 - abreviatura "Dr." é filtrada
    // Garante que o avatar não mostra "D" em vez da inicial do nome próprio.
    // Tokens: ["Dr.", "Rui", "Ferreira"] - úteis: ["Rui", "Ferreira"] - RF
    test('filtra abreviaturas terminadas em ponto', () {
      expect(buildIniciais('Dr. Rui Ferreira'), 'RF');
    });

    // TESTE 4 - nome de uma só palavra
    test('retorna primeira letra para nome de uma palavra', () {
      expect(buildIniciais('Admin'), 'A');
    });

    // TESTE 5 - nome vazio ou só espaços -> "?"
    test('retorna "?" para nome vazio ou só espaços', () {
      expect(buildIniciais(''), '?');
      expect(buildIniciais('   '), '?');
    });

    // TESTE 6 - letras minúsculas são capitalizadas
    test('devolve sempre iniciais em maiúsculas', () {
      expect(buildIniciais('ana silva'), 'AS');
    });
  });
}
