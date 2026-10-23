import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:saude_app/paginas_portal_medico/portal_medico.dart';

const _kRecentSearchKey = 'medico_recent_patient_search';
const _kMaxRecentes = 5;
const _kMaxSugestoes = 8;

// ─────────────────────────────────────────────
//  Modelo
// ─────────────────────────────────────────────
class _PacienteResult {
  final String userId;
  final String nome;
  final String iniciais;
  final String nif;
  final String dataNasc; // formatada "DD/MM/AAAA"
  final String telefone;
  final String? ultimaConsulta; // formatada "D Mmm de AAAA"
  final bool ativo; // deleted_at == null

  const _PacienteResult({
    required this.userId,
    required this.nome,
    required this.iniciais,
    required this.nif,
    required this.dataNasc,
    required this.telefone,
    this.ultimaConsulta,
    required this.ativo,
  });
}

// ─────────────────────────────────────────────
//  Página
// ─────────────────────────────────────────────
class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();

  List<_PacienteResult> _resultados = [];
  List<_PacienteResult> _sugestoes = [];
  List<_PacienteResult> _recentes = [];

  bool _loading = false;
  bool _loadingSugestoes = false;
  String? _error;
  String? _erroSugestoes;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSugestoes();
    _loadRecentes();
  }

  // Helpers de formatação
  static const List<String> _meses = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtConsulta(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_meses[d.month - 1]} de ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _toInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  _PacienteResult _fromUserRow(
    Map<String, dynamic> row, {
    String? ultimaConsulta,
  }) {
    final deletedAt = row['deleted_at'];
    return _PacienteResult(
      userId: row['id'] as String,
      nome: row['name'] as String? ?? '',
      iniciais: _toInitials(row['name'] as String? ?? ''),
      nif: row['nif'] as String? ?? '---',
      dataNasc: _fmtDate(row['date_of_birth'] as String?),
      telefone: row['phone'] as String? ?? '---',
      ultimaConsulta: ultimaConsulta,
      ativo: deletedAt == null,
    );
  }

  // ── Sugestões: pacientes com consultas deste médico ─────────────────────
  Future<void> _loadSugestoes() async {
    setState(() {
      _loadingSugestoes = true;
      _erroSugestoes = null;
    });
    try {
      final doctorId = db.auth.currentUser?.id;
      if (doctorId == null) throw Exception('Sem sessão ativa');

      final appts = await db
          .from('appointments')
          .select('patient_id, scheduled_date')
          .eq('doctor_id', doctorId)
          .isFilter('deleted_at', null)
          .order('scheduled_date', ascending: false)
          .limit(40);

      final Map<String, String> ultimaPorPaciente = {};
      final List<String> patientIds = [];
      for (final a in appts as List) {
        final pid = a['patient_id'] as String;
        if (ultimaPorPaciente.containsKey(pid)) continue;
        ultimaPorPaciente[pid] =
            _fmtConsulta(a['scheduled_date'] as String?);
        patientIds.add(pid);
        if (patientIds.length >= _kMaxSugestoes) break;
      }

      if (patientIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _sugestoes = [];
          _loadingSugestoes = false;
        });
        return;
      }

      final users = await db
          .from('users')
          .select('id, name, nif, date_of_birth, phone, deleted_at')
          .inFilter('id', patientIds)
          .eq('role', 'patient');

      final byId = {
        for (final u in users as List) u['id'] as String: u,
      };

      final lista = <_PacienteResult>[];
      for (final pid in patientIds) {
        final row = byId[pid];
        if (row == null) continue;
        lista.add(_fromUserRow(
          row,
          ultimaConsulta: ultimaPorPaciente[pid],
        ));
      }

      if (!mounted) return;
      setState(() {
        _sugestoes = lista;
        _loadingSugestoes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroSugestoes = e.toString();
        _loadingSugestoes = false;
      });
    }
  }

  // ── Recentes (local) ──────────────────────────────────────────────────────
  Future<void> _loadRecentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRecentSearchKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => _PacienteResult(
                userId: e['userId'] as String,
                nome: e['nome'] as String? ?? '',
                iniciais: e['iniciais'] as String? ?? '?',
                nif: e['nif'] as String? ?? '---',
                dataNasc: e['dataNasc'] as String? ?? '',
                telefone: e['telefone'] as String? ?? '---',
                ultimaConsulta: e['ultimaConsulta'] as String?,
                ativo: e['ativo'] as bool? ?? true,
              ))
          .toList();
      if (!mounted) return;
      setState(() => _recentes = list);
    } catch (_) {}
  }

  Future<void> _guardarRecente(_PacienteResult p) async {
    final updated = [
      p,
      ..._recentes.where((r) => r.userId != p.userId),
    ].take(_kMaxRecentes).toList();
    setState(() => _recentes = updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(updated
          .map((r) => {
                'userId': r.userId,
                'nome': r.nome,
                'iniciais': r.iniciais,
                'nif': r.nif,
                'dataNasc': r.dataNasc,
                'telefone': r.telefone,
                'ultimaConsulta': r.ultimaConsulta,
                'ativo': r.ativo,
              })
          .toList());
      await prefs.setString(_kRecentSearchKey, json);
    } catch (_) {}
  }

  // ── pesquisa no Supabase ──────────────────────
  Future<void> _buscar(String q) async {
    if (q.trim().length < 2) {
      setState(() {
        _resultados = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doctorId = db.auth.currentUser?.id;
      if (doctorId == null) throw Exception('Sem sessão ativa');

      // Busca todos os pacientes cujo nome contenha a query (ilike)
      // ou cujo NIF contenha a query
      // Juntamos também a última consulta via appointments
      final rows = await db
          .from('users')
          .select('''
            id,
            name,
            nif,
            date_of_birth,
            phone,
            deleted_at,
            patients!inner(
              health_number
            )
          ''')
          .eq('role', 'patient')
          .ilike('name', '%$q%')
          .order('name');

      final List<_PacienteResult> lista = [];
      for (final row in rows as List) {
        final userId = row['id'] as String;
        String? ultimaConsulta;
        try {
          final appt = await db
              .from('appointments')
              .select('scheduled_date')
              .eq('patient_id', userId)
              .eq('doctor_id', doctorId)
              .eq('status', 'completed')
              .order('scheduled_date', ascending: false)
              .limit(1)
              .maybeSingle();
          if (appt != null) {
            ultimaConsulta = _fmtConsulta(appt['scheduled_date'] as String?);
          }
        } catch (_) {}

        lista.add(_fromUserRow(row, ultimaConsulta: ultimaConsulta));
      }

      // Também pesquisa por NIF se a query parecer um número
      if (RegExp(r'\d').hasMatch(q)) {
        final rowsNif = await db
            .from('users')
            .select('''
              id,
              name,
              nif,
              date_of_birth,
              phone,
              deleted_at,
              patients!inner(
                health_number
              )
            ''')
            .eq('role', 'patient')
            .ilike('nif', '%$q%')
            .order('name');

        for (final row in rowsNif as List) {
          final userId = row['id'] as String;
          if (lista.any((p) => p.userId == userId)) continue;

          String? ultimaConsulta;
          try {
            final appt = await db
                .from('appointments')
                .select('scheduled_date')
                .eq('patient_id', userId)
                .eq('doctor_id', doctorId)
                .eq('status', 'completed')
                .order('scheduled_date', ascending: false)
                .limit(1)
                .maybeSingle();
            if (appt != null) {
              ultimaConsulta = _fmtConsulta(appt['scheduled_date'] as String?);
            }
          } catch (_) {}

          lista.add(_fromUserRow(row, ultimaConsulta: ultimaConsulta));
        }
      }

      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao pesquisar: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Debounce simples — dispara após pausa de 400ms
  DateTime _lastType = DateTime.now();

  void _onChanged(String v) {
    setState(() => _query = v);
    _lastType = DateTime.now();
    final typed = _lastType;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_lastType == typed) {
        _buscar(v);
      }
    });
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A8070),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _listaPacientes(List<_PacienteResult> lista) {
    return Column(
      children: [
        for (var i = 0; i < lista.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _PacienteCard(
            paciente: lista[i],
            onOpen: () => _guardarRecente(lista[i]),
          ),
        ],
      ],
    );
  }

  Widget _conteudoInicial() {
    if (_loadingSugestoes && _recentes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF66D1D8)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pesquise por nome ou NIF (mínimo 2 caracteres)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.40),
            fontFamily: 'Poppins',
          ),
        ),
        if (_recentes.isNotEmpty) ...[
          _sectionTitle('Pesquisados recentemente'),
          _listaPacientes(_recentes),
        ],
        if (_erroSugestoes != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _erroSugestoes!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD94F3D),
                fontFamily: 'Poppins',
              ),
            ),
          )
        else if (_sugestoes.isNotEmpty) ...[
          _sectionTitle('Pacientes com consultas consigo'),
          _listaPacientes(_sugestoes),
        ] else if (!_loadingSugestoes)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Ainda sem pacientes na sua agenda. Marque uma consulta para aparecerem aqui.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.40),
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      currentIndex: 3,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          const Text(
            'Pesquisar Paciente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF66D1D8), width: 1.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF66D1D8),
                              ),
                            )
                          : const Icon(
                              Icons.search,
                              color: Color(0xFF66D1D8),
                              size: 22,
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: _onChanged,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Pesquisar por nome ou NIF...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.black.withValues(alpha: 0.40),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() {
                            _query = '';
                            _controller.clear();
                            _resultados = [];
                            _error = null;
                          }),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF66D1D8),
                          ),
                        ),
                    ],
                  ),
                ),

                // Resultados
                if (_query.isNotEmpty) ...[
                  Divider(
                    color: const Color(0xFF66D1D8).withValues(alpha: 0.40),
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Resultados para "$_query"',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.45),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD94F3D),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  else if (!_loading && _resultados.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        _query.length < 2
                            ? 'Introduza pelo menos 2 caracteres.'
                            : 'Nenhum paciente encontrado.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.40),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      itemCount: _resultados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        return _PacienteCard(
                          paciente: _resultados[i],
                          onOpen: () => _guardarRecente(_resultados[i]),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),

          if (_query.isEmpty) ...[
            const SizedBox(height: 20),
            _conteudoInicial(),
          ],

          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
//  Card de paciente
// ─────────────────────────────────────────────
class _PacienteCard extends StatelessWidget {
  final _PacienteResult paciente;
  final VoidCallback? onOpen;

  const _PacienteCard({required this.paciente, this.onOpen});

  // Cores do avatar baseadas no índice da inicial
  static Color _avatarBg(String iniciais) {
    const cores = [
      Color(0xFFD8F2EF),
      Color(0xFF185FA5),
      Color(0xFFAEBDBB),
      Color(0xFFFFE0B2),
    ];
    return cores[iniciais.codeUnitAt(0) % cores.length];
  }

  static Color _avatarFg(String iniciais) {
    const cores = [
      Color(0xFF1A6B62),
      Colors.white,
      Colors.white,
      Color(0xFF6D4C1F),
    ];
    return cores[iniciais.codeUnitAt(0) % cores.length];
  }

  @override
  Widget build(BuildContext context) {
    final bool ativo = paciente.ativo;
    final double opacidade = ativo ? 1.0 : 0.50;
    final Color bg = _avatarBg(paciente.iniciais);
    final Color fg = _avatarFg(paciente.iniciais);

    return GestureDetector(
      onTap: ativo
          ? () {
              onOpen?.call();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientData(
                    patientId: paciente.userId,
                    nomePaciente: paciente.nome,
                    iniciais: paciente.iniciais,
                    avatarBg: bg,
                    avatarFg: fg,
                    dataNasc: paciente.dataNasc,
                    nif: paciente.nif,
                    telefone: paciente.telefone,
                  ),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: opacidade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: ativo ? Colors.white : Colors.white.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  paciente.iniciais,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ativo
                            ? Colors.black
                            : Colors.black.withValues(alpha: 0.50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'NIF: ${paciente.nif} '),
                          const TextSpan(text: '• '),
                          TextSpan(text: paciente.dataNasc),
                        ],
                        style: TextStyle(
                          fontSize: 11,
                          color: ativo
                              ? const Color(0xFF6A9890)
                              : const Color(0xFF6A9890).withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (paciente.ultimaConsulta != null &&
                        paciente.ultimaConsulta!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Última consulta: ${paciente.ultimaConsulta}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ativo
                              ? const Color(0xFF6A9890)
                              : const Color(0xFF6A9890).withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                    if (!ativo) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Conta desativada',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFFD94F3D).withValues(alpha: 0.70),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron
              Text(
                '>',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ativo
                      ? const Color(0xFFDDD5CE)
                      : const Color(0xFFDDD5CE).withValues(alpha: 0.50),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}