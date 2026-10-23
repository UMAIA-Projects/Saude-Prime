import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class Paciente {
  final String id;
  final String nome;
  final String nif;
  final String iniciais;
  final Color cor;
  final String ultimaConsulta;

  const Paciente({
    required this.id,
    required this.nome,
    required this.nif,
    required this.iniciais,
    required this.cor,
    required this.ultimaConsulta,
  });
}

class GestaoPacientesPage extends StatefulWidget {
  const GestaoPacientesPage({super.key});

  @override
  State<GestaoPacientesPage> createState() => _GestaoPacientesPageState();
}

class _GestaoPacientesPageState extends State<GestaoPacientesPage> {
  static const Color _azulBotao = Color(0xFF3B6BE0);

  static const List<Color> _paleta = [
    Color(0xFF3B6BE0),
    Color(0xFF27AE60),
    Color(0xFFE0A020),
    Color(0xFFE05050),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF2980B9),
  ];

  bool _isLoading = true;
  List<Paciente> _todosOsPacientes = [];
  List<Paciente> _pacientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
  }

  // Helpers

  String _iniciais(String nome) {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '??';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    // Ignora prefixos como "Dr." / "Dra."
    final uteis = partes.where((p) => !p.endsWith('.')).toList();
    if (uteis.length >= 2)
      return '${uteis.first[0]}${uteis.last[0]}'.toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  String _formatarData(String isoDate) {
    const meses = [
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
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day} ${meses[d.month - 1]}';
    } catch (_) {
      return '-';
    }
  }

  // -- Data loading ----------------------------------------------------------

  Future<void> _carregarPacientes() async {
    setState(() => _isLoading = true);

    try {
      // 1. Todos os utilizadores com role = 'patient' e não eliminados
      final patientsRaw = await db
          .from('users')
          .select('id, name, nif')
          .eq('role', 'patient')
          .isFilter('deleted_at', null)
          .order('name');

      // 2. Última consulta por paciente (scheduled ou completed)
      final appointmentsRaw = await db
          .from('appointments')
          .select('patient_id, scheduled_date')
          .inFilter('status', ['scheduled', 'completed'])
          .order('scheduled_date', ascending: false);

      // Mapa: patient_id - data da última consulta
      final Map<String, String> ultimaConsulta = {};
      for (final appt in appointmentsRaw as List) {
        final pid = appt['patient_id'] as String;
        if (!ultimaConsulta.containsKey(pid)) {
          ultimaConsulta[pid] = _formatarData(appt['scheduled_date'] as String);
        }
      }

      // Construir lista de Paciente
      final lista = (patientsRaw as List).asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value as Map<String, dynamic>;
        final nome = (p['name'] as String?) ?? 'Sem nome';
        return Paciente(
          id: p['id'] as String,
          nome: nome,
          nif: (p['nif'] as String?) ?? '-',
          iniciais: _iniciais(nome),
          cor: _paleta[i % _paleta.length],
          ultimaConsulta: ultimaConsulta[p['id']] ?? '-',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _todosOsPacientes = lista;
        _pacientesFiltrados = lista;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar pacientes: $e')));
    }
  }

  void _filtrarPacientes(String query) {
    final q = query.toLowerCase();
    setState(() {
      _pacientesFiltrados = _todosOsPacientes
          .where(
            (p) =>
                p.nome.toLowerCase().contains(q) ||
                p.nif.replaceAll(' ', '').contains(q.replaceAll(' ', '')),
          )
          .toList();
    });
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          TextField(
            onChanged: _filtrarPacientes,
            decoration: InputDecoration(
              hintText: 'Pesquisar por nome ou NIF...',
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black38,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  'assets/imagens_portal_recepcao/Search.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    _azulBotao,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _azulBotao, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _azulBotao, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 25),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_pacientesFiltrados.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'Nenhum paciente encontrado.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          else
            ..._pacientesFiltrados.map(
              (paciente) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPacienteCard(paciente),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pacientes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NovoPacientePage()),
            );
            // Recarregar lista ao voltar
            _carregarPacientes();
          },
          icon: SvgPicture.asset(
            'assets/imagens_portal_recepcao/Plus.svg',
            width: 14,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          label: const Text('Novo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _azulBotao,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    final cleanNif = paciente.nif.replaceAll(' ', '');
    final maskedNif = cleanNif.length >= 3
        ? '${cleanNif.substring(0, 3)}-***-***'
        : cleanNif;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: paciente.cor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              paciente.iniciais,
              style: TextStyle(
                color: paciente.cor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente.nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF1A3B8B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIF: $maskedNif  ·  Últ: ${paciente.ultimaConsulta}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7FA39F),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Ações
          // Ações
          GestureDetector(
            onTap: () async {
              // Navega para a página híbrida (Ver/Editar) e espera pelo regresso
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditarPacientePage(pacienteId: paciente.id),
                ),
              );
              // Quando a página for fechada, recarrega a lista
              // para atualizar imediatamente nomes ou NIFs alterados!
              _carregarPacientes();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _azulBotao.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Ver',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: _azulBotao,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
