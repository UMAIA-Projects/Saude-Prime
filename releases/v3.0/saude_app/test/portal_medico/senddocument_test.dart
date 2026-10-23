import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

/// Replica o getter `_podeEnviar` de `_SendDocumentState`.
/// O upload só deve ser permitido quando há ficheiro, nome não vazio e
/// não está já a fazer upload.
bool podeEnviar({
  required bool temFicheiro,
  required String nome,
  required bool uploading,
}) {
  return temFicheiro && nome.trim().isNotEmpty && !uploading;
}

/// Replica `_foldAccents` de `_SendDocumentState`.
String foldAccents(String input) {
  const map = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ç': 'C',
    'Ñ': 'N',
  };
  final out = StringBuffer();
  for (final c in input.split('')) {
    out.write(map[c] ?? c);
  }
  return out.toString();
}

/// Replica `_sanitizeStorageFileName` de `_SendDocumentState`.
/// Remove extensão, aplica fold de acentos, substitui espaços por '_' e
/// elimina caracteres não ASCII simples.
String sanitizeStorageFileName(String original) {
  final base = original.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  var stem = dot > 0 ? base.substring(0, dot) : base;
  final ext = dot > 0 ? base.substring(dot).toLowerCase() : '.pdf';

  stem = foldAccents(stem)
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  if (stem.isEmpty) stem = 'documento';
  return '$stem$ext';
}

/// Replica a construção do `storagePath` em `_enviar`.
/// Formato: `{patientId}/{timestamp}_{safeFileName}`.
String buildStoragePath({
  required String patientId,
  required int timestamp,
  required String safeFileName,
}) {
  return '$patientId/${timestamp}_$safeFileName';
}

/// Replica `_novoIdDocumento` de produção.
String novoIdDocumento() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
}

// TESTES

void main() {
  // 1. podeEnviar - guard antes do upload
  group('podeEnviar - validação antes do upload', () {
    test('ficheiro presente, nome preenchido, sem upload → pode enviar', () {
      expect(
        podeEnviar(
          temFicheiro: true,
          nome: 'Análise sanguínea',
          uploading: false,
        ),
        true,
      );
    });

    test('sem ficheiro → não pode enviar', () {
      expect(
        podeEnviar(
          temFicheiro: false,
          nome: 'Análise sanguínea',
          uploading: false,
        ),
        false,
      );
    });

    test('nome vazio → não pode enviar', () {
      expect(podeEnviar(temFicheiro: true, nome: '', uploading: false), false);
    });

    test('nome só espaços → equivale a vazio → não pode enviar', () {
      expect(
        podeEnviar(temFicheiro: true, nome: '   ', uploading: false),
        false,
      );
    });

    test('já a fazer upload → não pode enviar (evita duplo submit)', () {
      expect(
        podeEnviar(temFicheiro: true, nome: 'Receita', uploading: true),
        false,
      );
    });

    test('sem ficheiro E sem nome → não pode enviar', () {
      expect(podeEnviar(temFicheiro: false, nome: '', uploading: false), false);
    });
  });

  // 2. sanitizeStorageFileName - sanitização para o bucket Supabase
  group('sanitizeStorageFileName - nomes seguros para Storage', () {
    test('nome simples ASCII → mantém stem, extensão lowercase', () {
      expect(sanitizeStorageFileName('relatorio.pdf'), 'relatorio.pdf');
    });

    test('espaços no nome → substituídos por "_"', () {
      expect(
        sanitizeStorageFileName('analise sanguinea.pdf'),
        'analise_sanguinea.pdf',
      );
    });

    test('acentos portugueses → removidos/substituídos', () {
      expect(
        sanitizeStorageFileName('Análise Clínica.pdf'),
        'Analise_Clinica.pdf',
      );
    });

    test('ç/ã → c/a', () {
      expect(
        sanitizeStorageFileName('receção-médica.pdf'),
        'rececao-medica.pdf',
      );
    });

    test('extensão uppercase → convertida para lowercase', () {
      expect(sanitizeStorageFileName('Exame.PDF'), 'Exame.pdf');
    });

    test('caracteres especiais (!, @, #) → substituídos por "_"', () {
      final result = sanitizeStorageFileName('file!@#name.png');
      // não deve conter !, @ ou #
      expect(result.contains('!'), false);
      expect(result.contains('@'), false);
      expect(result.contains('#'), false);
      expect(result.endsWith('.png'), true);
    });

    test('underscores consecutivos → colapsados em um', () {
      final result = sanitizeStorageFileName('file   name.pdf'); // 3 espaços
      expect(result.contains('__'), false);
    });

    test('stem vazio após sanitização → fallback "documento"', () {
      // ficheiro com nome só de caracteres especiais
      expect(sanitizeStorageFileName('!!!.pdf'), 'documento.pdf');
    });

    test('path com separador "/" → usa só o último segmento', () {
      expect(
        sanitizeStorageFileName('/tmp/uploads/resultado.jpg'),
        'resultado.jpg',
      );
    });

    test('sem extensão → assume ".pdf"', () {
      expect(sanitizeStorageFileName('relatorio'), 'relatorio.pdf');
    });
  });

  // 3. buildStoragePath - unicidade e formato do caminho no bucket
  group('buildStoragePath - caminho único no bucket', () {
    const patientId = 'patient-uuid-abc';
    const ts = 1717000000000;

    test('formato base: patientId/timestamp_filename', () {
      final path = buildStoragePath(
        patientId: patientId,
        timestamp: ts,
        safeFileName: 'relatorio.pdf',
      );
      expect(path, '$patientId/${ts}_relatorio.pdf');
    });

    test('dois uploads com timestamps diferentes → paths distintos', () {
      final p1 = buildStoragePath(
        patientId: patientId,
        timestamp: ts,
        safeFileName: 'doc.pdf',
      );
      final p2 = buildStoragePath(
        patientId: patientId,
        timestamp: ts + 1,
        safeFileName: 'doc.pdf',
      );
      expect(p1 == p2, false);
    });

    test('dois pacientes com mesmo ficheiro → paths distintos', () {
      final p1 = buildStoragePath(
        patientId: 'patient-A',
        timestamp: ts,
        safeFileName: 'doc.pdf',
      );
      final p2 = buildStoragePath(
        patientId: 'patient-B',
        timestamp: ts,
        safeFileName: 'doc.pdf',
      );
      expect(p1 == p2, false);
    });

    test('path começa com o patientId correcto', () {
      final path = buildStoragePath(
        patientId: patientId,
        timestamp: ts,
        safeFileName: 'x.pdf',
      );
      expect(path.startsWith(patientId), true);
    });
  });

  // 4. novoIdDocumento - UUID v4 válido
  group('novoIdDocumento - UUID v4', () {
    // Regex UUID v4: version nibble = 4, variant nibble = 8/9/a/b
    final uuidV4Re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('formato é UUID v4 válido', () {
      final id = novoIdDocumento();
      expect(uuidV4Re.hasMatch(id), true, reason: 'UUID gerado: $id');
    });

    test('dois IDs consecutivos são diferentes (unicidade)', () {
      final a = novoIdDocumento();
      final b = novoIdDocumento();
      expect(a == b, false);
    });

    test('comprimento total é 36 caracteres (UUID canónico)', () {
      expect(novoIdDocumento().length, 36);
    });

    test('contém exactamente 4 hífenes', () {
      expect(novoIdDocumento().split('-').length, 5); // 4 hífenes - 5 partes
    });
  });
}
