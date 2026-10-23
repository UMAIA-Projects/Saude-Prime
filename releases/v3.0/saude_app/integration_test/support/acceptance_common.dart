import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Utilizadores seed (password comum). Coincidem com seed_auth.js + seed sql.

const kSeedPassword = '12345678';

const kMedicoEmail = 'medico1@saudeprime.pt';
const kMedicoId = '11111111-1111-1111-1111-111111111111';

const kPacienteEmail = 'paciente1@saudeprime.pt';
const kPacienteId = '22222222-2222-2222-2222-222222222221';
const kPacienteNome = 'Maria Santos';

// Um 2.º paciente, útil quando o 1.º já está envolvido no cenário.
const kPaciente2Email = 'paciente2@saudeprime.pt';
const kPaciente2Id = '22222222-2222-2222-2222-222222222222';
const kPaciente2Nome = 'António Rodrigues';

const kRecepcaoEmail = 'recepcao@saudeprime.pt';
const kRecepcaoId = '33333333-3333-3333-3333-333333333333';

const kAdminEmail = 'admin@saudeprime.pt';
const kAdminId = '44444444-4444-4444-4444-444444444444';

// Arranque da app / Supabase
bool _appStarted = false;


Future<SupabaseClient> ensureAppStarted() async {
  if (_appStarted) return Supabase.instance.client;

  // Só inicializa se ainda não estiver inicializado neste processo.
  bool jaIniciado;
  try {
    Supabase.instance;
    jaIniciado = true;
  } catch (_) {
    jaIniciado = false;
  }

  if (!jaIniciado) {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  _appStarted = true;
  return Supabase.instance.client;
}

/// Login programático com um utilizador seed. Devolve o cliente Supabase.
Future<SupabaseClient> loginComo(String email, {String? expectId}) async {
  final db = await ensureAppStarted();
  await db.auth.signOut();
  await db.auth.signInWithPassword(email: email, password: kSeedPassword);

  if (expectId != null) {
    expect(
      db.auth.currentUser?.id,
      expectId,
      reason:
          'A sessão de aceitação devia pertencer ao utilizador seed ($email).',
    );
  }
  return db;
}

// MaterialApp mínimo para envolver as páginas em teste
class AcceptanceApp extends StatelessWidget {
  final Widget home;
  const AcceptanceApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

// Espera limitada - alternativa segura ao pumpAndSettle
// Bombeia frames em passos curtos até `finder` aparecer ou esgotar `timeout`.
Future<bool> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

// Aumenta a "janela" lógica do teste para os formulários compridos caberem
// sem precisar de scroll.
Future<void> usarJanelaAlta(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2600));
}

// Toca num widget de texto garantindo primeiro que está visível (faz scroll
// se necessário). O `label` tem de ser único no ecrã.
Future<void> tapTexto(WidgetTester tester, String label) async {
  final alvo = find.text(label);
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
}

const kAbrirHostKey = Key('acc_abrir_host');

// Host com um botão que empurra [builder] numa rota nova. Útil para páginas que
// fazem `Navigator.pop` no fim (ex.: após guardar) - assim há para onde voltar.
class HostAbrir extends StatelessWidget {
  final WidgetBuilder builder;
  const HostAbrir({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        key: kAbrirHostKey,
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: builder)),
        child: const Text('abrir'),
      ),
    ),
  );
}

// Abre [builder] a partir de um host (ver [HostAbrir]) e espera a navegação.
Future<void> abrirPagina(WidgetTester tester, WidgetBuilder builder) async {
  await usarJanelaAlta(tester);
  await tester.pumpWidget(AcceptanceApp(home: HostAbrir(builder: builder)));
  await pumpUntilFound(tester, find.byKey(kAbrirHostKey));
  await tester.tap(find.byKey(kAbrirHostKey));
  await tester.pump(const Duration(milliseconds: 300));
}

// Bombeia frames até `finder` DESAPARECER ou esgotar `timeout`.
Future<bool> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) return true;
  }
  return false;
}

// Helpers de data / hora / id

// Data futura (só dia, sem hora) a `offsetDias` de hoje.
DateTime dataFutura({required int offsetDias}) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(days: offsetDias));
}

// Hora por omissão das páginas de marcação
// Usada para prever o slot que o formulário vai escolher.
TimeOfDay horaInicial() {
  final now = DateTime.now();
  return TimeOfDay(hour: now.hour + 1, minute: 0);
}

DateTime slotStart(DateTime data, TimeOfDay hora) =>
    DateTime(data.year, data.month, data.day, hora.hour, hora.minute);

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

// UUID v4 (as tabelas usam UUID na coluna id).
String uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
}
