import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class DashboardRecepcao extends StatefulWidget {
  const DashboardRecepcao({super.key});

  @override
  State<DashboardRecepcao> createState() => _DashboardRecepcaoState();
}

class _DashboardRecepcaoState extends State<DashboardRecepcao> {
  static const Color _azulDestaque = Color(0xFF2D7BDA);
  static const Color _azulBotao = Color(0xFF6DA0E0);

  bool _isLoading = true;
  String _primeiroNome = '';
  String _dataHoje = '';
  
  List<Map<String, dynamic>> _consultasHoje = [];
  int _totalConsultasHoje = 0;
  
  int _senhasEmitidas = 0;
  int _senhasEmEspera = 0;
  int _senhasChamadas = 0;
  int _senhasAtendidas = 0;

  @override
  void initState() {
    super.initState();
    _configurarDataAtual();
    _carregarDadosDashboard();
  }

  void _configurarDataAtual() {
    final hoje = DateTime.now();
    final diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

    final diaSemana = diasSemana[hoje.weekday - 1];
    final mes = meses[hoje.month - 1];

    setState(() {
      _dataHoje = '$diaSemana, ${hoje.day} $mes';
    });
  }

  Future<void> _carregarDadosDashboard() async {
    try {
      //Perfil da Rececionista (Apenas precisamos do Primeiro Nome para a saudação)
      final userId = db.auth.currentUser!.id;
      final userData = await db.from('users').select('name').eq('id', userId).single();
      
      final nomeCompleto = userData['name'] as String;
      final partesDoNome = nomeCompleto.split(' ');
      final primeiroNome = partesDoNome.first;

      //Datas formatadas para as Queries
      final hoje = DateTime.now();
      final hojeString = "${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}";
      
      final inicioDoDiaTimestamptz = DateTime(hoje.year, hoje.month, hoje.day).toIso8601String();
      final fimDoDiaTimestamptz = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59).toIso8601String();

      //Ir buscar as consultas 
      final List<dynamic> todasConsultasHoje = await db
          .from('appointments')
          .select('''
            id,
            scheduled_date,
            scheduled_time,
            type,
            patients ( users ( name ) ),
            doctors ( users ( name ) )
          ''')
          .eq('scheduled_date', hojeString)
          .order('scheduled_time', ascending: true);

      final totalConsultas = todasConsultasHoje.length;
      final consultasParaMostrar = todasConsultasHoje.take(5).toList();

      //Ir buscar cenas da fila virtual
      int emitidas = 0, emEspera = 0, chamadas = 0, atendidas = 0;
      
      try {
        final List<dynamic> filaData = await db
            .from('virtual_queue')
            .select('status')
            .gte('issued_at', inicioDoDiaTimestamptz)
            .lte('issued_at', fimDoDiaTimestamptz);

        emitidas = filaData.length;
        for (var ticket in filaData) {
          final status = ticket['status'];
          if (status == 'waiting') emEspera++;
          else if (status == 'called') chamadas++;
          else if (status == 'attended') atendidas++;
        }
      } catch (e) {
        debugPrint('Aviso da Fila Virtual: $e');
      }

      if (mounted) {
        setState(() {
          _primeiroNome = primeiroNome;
          
          _totalConsultasHoje = totalConsultas;
          _consultasHoje = List<Map<String, dynamic>>.from(consultasParaMostrar);
          
          _senhasEmitidas = emitidas;
          _senhasEmEspera = emEspera;
          _senhasChamadas = chamadas;
          _senhasAtendidas = atendidas;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro a carregar dashboard: $e');
      if (mounted) {
        setState(() {
          _primeiroNome = 'Receção';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 0,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _azulDestaque))
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $_primeiroNome!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3B8B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$_dataHoje · $_totalConsultasHoje consultas hoje',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Fila de Hoje",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _azulDestaque,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(value: _senhasEmitidas.toString(), label: "Emitidas"),
                    _StatItem(value: _senhasEmEspera.toString(),  label: "Em espera"),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(value: _senhasChamadas.toString(), label: "Chamadas"),
                    _StatItem(value: _senhasAtendidas.toString(), label: "Atendidas"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          
          Center(
            child: SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FilaVirtualPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _azulBotao,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Gerir Fila",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 35),
          const Text(
            "Próximas Consultas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _azulDestaque,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 15),
          
          // --- LISTA DE CONSULTAS DINÂMICA ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: _consultasHoje.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: Text(
                        "Sem consultas agendadas para hoje.",
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                      ),
                    ),
                  )
                : Column(
                    children: _consultasHoje.asMap().entries.map((entry) {
                      final index = entry.key;
                      final consulta = entry.value;

                      // Formatar hora
                      final horaCompleta = consulta['scheduled_time']?.toString() ?? '00:00';
                      final horaFormatada = horaCompleta.length >= 5 ? horaCompleta.substring(0, 5) : horaCompleta;
                      
                      // Extrair Nomes (com segurança para RLS barrado)
                      final pData = consulta['patients'];
                      final nomePaciente = (pData != null && pData['users'] != null) ? pData['users']['name'] : 'Paciente';
                      
                      final dData = consulta['doctors'];
                      final nomeMedico = 'Dr(a). ${(dData != null && dData['users'] != null) ? dData['users']['name'] : 'Médico'}';
                      
                      // Tipo de Consulta
                      final tipoEnum = consulta['type'];
                      final isUrgente = tipoEnum == 'urgent';
                      final tipoConsulta = isUrgente ? 'Urgente' : (tipoEnum == 'follow_up' ? 'Revisão' : 'Normal');

                      return Column(
                        children: [
                          _AppointmentTile(
                            time: horaFormatada,
                            name: nomePaciente,
                            doctor: nomeMedico,
                            tag: tipoConsulta,
                            isUrgente: isUrgente,
                          ),
                          if (index < _consultasHoje.length - 1)
                            const Divider(height: 1, indent: 20, endIndent: 20),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 35),

          // --- Quick actions ---
          Row(
            children: [
              _buildAcaoRapida(
                context,
                'assets/imagens_portal_recepcao/People.svg',
                'Gerir\nPacientes',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GestaoPacientesPage()),
                ),
              ),
              const SizedBox(width: 10),
              _buildAcaoRapida(
                context,
                'assets/imagens_portal_recepcao/Schedule.svg',
                'Agendamentos',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgendamentosPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAcaoRapida(
                context,
                'assets/imagens_portal_recepcao/Ticket.svg',
                'Emitir\nSenha',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FilaVirtualPage()),
                ),
              ),
              const SizedBox(width: 10),
              _buildAcaoRapida(
                context,
                'assets/imagens_portal_recepcao/Plus.svg',
                'Novo\nPaciente',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NovoPacientePage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAcaoRapida(BuildContext context, String svgAsset, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(Color(0xFF3B6BE0), BlendMode.srcIn),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A3B8B),
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A8070),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A8070)),
        ),
      ],
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final String time;
  final String name;
  final String doctor;
  final String tag;
  final bool isUrgente;

  const _AppointmentTile({
    required this.time,
    required this.name,
    required this.doctor,
    required this.tag,
    required this.isUrgente,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D7BDA),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(doctor, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgente ? const Color(0xFFFDEFD3) : const Color(0xFFE1F0FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: isUrgente ? const Color(0xFFE5A000) : const Color(0xFF2D7BDA),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}