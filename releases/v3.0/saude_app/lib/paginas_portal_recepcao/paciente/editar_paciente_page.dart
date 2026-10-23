import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class EditarPacientePage extends StatefulWidget {
  final String pacienteId;
  
  const EditarPacientePage({super.key, required this.pacienteId});

  @override
  State<EditarPacientePage> createState() => _EditarPacientePageState();
}

class _EditarPacientePageState extends State<EditarPacientePage> {
  // Qual aba está ativa? 0 = Dados ou 1 = Consultas
  int _abaAtiva = 0;

  // Se estamos em modo de edição ou leitura
  bool _modoEdicao = false;
  bool _isLoading = true;
  bool _isSaving = false;

  PacienteModel? _pacienteAtual;
  List<ConsultaModel> _consultasAtuais = [];

  // Os controladores começam vazios e são preenchidos na BD
  final _nomeCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();
  final _dataNascCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _snsCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _moradaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosDaBaseDeDados();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _nifCtrl.dispose();
    _dataNascCtrl.dispose();
    _telCtrl.dispose();
    _snsCtrl.dispose();
    _emailCtrl.dispose();
    _moradaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosDaBaseDeDados() async {
    try {
      // Ir buscar os dados do utilizador e paciente
      final userData = await db.from('users').select('''
        name, email, phone, address, nif, date_of_birth,
        patients ( health_number )
      ''').eq('id', widget.pacienteId).single();

      // Ir buscar as consultas e o nome do médico
      final consultasData = await db.from('appointments').select('''
        scheduled_date, type, status,
        doctors ( users ( name ) )
      ''').eq('patient_id', widget.pacienteId).order('scheduled_date', ascending: false);

      if (!mounted) return;

      // Converter data YYYY-MM-DD para DD/MM/YYYY para o UI
      String formatarData(String? isoDate) {
        if (isoDate == null || isoDate.isEmpty) return '';
        try {
          final d = DateTime.parse(isoDate);
          return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
        } catch (_) {
          return isoDate;
        }
      }

      // Traduzir status da BD para o  UI
      String traduzirStatus(String statusBD) {
        switch (statusBD) {
          case 'completed': return 'Concluída';
          case 'no_show': return 'Faltou';
          case 'canceled': return 'Faltou';
          case 'scheduled': return 'Agendada';
          default: return 'Desconhecido';
        }
      }

      setState(() {
        _pacienteAtual = PacienteModel(
          id: widget.pacienteId,
          nome: userData['name'] ?? 'Sem nome',
          email: userData['email'] ?? '',
          nif: userData['nif'] ?? '',
          telemovel: userData['phone'] ?? '',
          morada: userData['address'] ?? '',
          dataNasc: formatarData(userData['date_of_birth']),
          sns: userData['patients']?['health_number'] ?? '',
        );

        // Preencher os Controladores para a Aba de Edição
        _nomeCtrl.text = _pacienteAtual!.nome;
        _emailCtrl.text = _pacienteAtual!.email;
        _nifCtrl.text = _pacienteAtual!.nif;
        _telCtrl.text = _pacienteAtual!.telemovel;
        _moradaCtrl.text = _pacienteAtual!.morada;
        _dataNascCtrl.text = _pacienteAtual!.dataNasc;
        _snsCtrl.text = _pacienteAtual!.sns;

        // Mapear para a tua Lista de ConsultaModel
        _consultasAtuais = (consultasData as List).map((c) {
          return ConsultaModel(
            data: formatarData(c['scheduled_date']),
            medico: c['doctors']?['users']?['name'] ?? 'Médico',
            tipo: c['type'].toString().toUpperCase(),
            status: traduzirStatus(c['status']),
          );
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar paciente: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _isSaving = true);
    
    try {
      // Reverter DD/MM/YYYY para YYYY-MM-DD (formato da base de dados)
      String dbDate = '';
      if (_dataNascCtrl.text.isNotEmpty) {
        final parts = _dataNascCtrl.text.split('/');
        if (parts.length == 3) {
          dbDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      // Atualiza a tabela "users"
      await db.from('users').update({
        'name': _nomeCtrl.text.trim(),
        'nif': _nifCtrl.text.trim(),
        'phone': _telCtrl.text.trim(),
        'address': _moradaCtrl.text.trim(),
        if (dbDate.isNotEmpty) 'date_of_birth': dbDate,
      }).eq('id', widget.pacienteId);

      // Atualiza a tabela "patients"
      await db.from('patients').update({
        'health_number': _snsCtrl.text.trim(),
      }).eq('user_id', widget.pacienteId);

      // Recarregar os dados para atualizar o UI
      await _carregarDadosDaBaseDeDados();
      
      if (mounted) {
        setState(() {
          _modoEdicao = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Erro ao guardar: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelar() {
    if (_pacienteAtual != null) {
      _nomeCtrl.text = _pacienteAtual!.nome;
      _nifCtrl.text = _pacienteAtual!.nif;
      _dataNascCtrl.text = _pacienteAtual!.dataNasc;
      _telCtrl.text = _pacienteAtual!.telemovel;
      _snsCtrl.text = _pacienteAtual!.sns;
      _emailCtrl.text = _pacienteAtual!.email;
      _moradaCtrl.text = _pacienteAtual!.morada;
    }
    setState(() => _modoEdicao = false);
  }

  void _mudarAba(int index) {
    setState(() {
      _abaAtiva = index;
      // Sair do modo de edição ao mudar de aba
      if (_modoEdicao) _cancelar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 1,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B6BE0)))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTitulo(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 20),

            if (_abaAtiva == 0 && !_modoEdicao && _pacienteAtual != null)
              AbaDadosView(
                paciente: _pacienteAtual!,
                onEditarPressed: () => setState(() => _modoEdicao = true),
              ),

            if (_abaAtiva == 0 && _modoEdicao)
              _isSaving 
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF27AE60)),
                  ))
                : AbaDadosForm(
                    nomeCtrl: _nomeCtrl,
                    nifCtrl: _nifCtrl,
                    dataNascCtrl: _dataNascCtrl,
                    telemovelCtrl: _telCtrl,
                    snsCtrl: _snsCtrl,
                    emailCtrl: _emailCtrl,
                    moradaCtrl: _moradaCtrl,
                    onGuardar: _guardar,
                    onCancelar: _cancelar,
                  ),

            if (_abaAtiva == 1) AbaConsultasList(consultas: _consultasAtuais),

            const SizedBox(height: 10),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            '< Voltar atrás',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF3B6BE0),
              fontFamily: 'Poppins',
            ),
          ),
        ),

        if (_abaAtiva == 0 && !_isSaving)
          GestureDetector(
            onTap: () {
              if (_modoEdicao) {
                _cancelar();
              } else {
                setState(() => _modoEdicao = true);
              }
            },
            child: Row(
              children: [
                if (!_modoEdicao) ...[
                  SvgPicture.asset(
                    'assets/imagens_portal_recepcao/Edit.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF3B6BE0),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  _modoEdicao ? 'Cancelar' : 'Editar',
                  style: TextStyle(
                    fontSize: 13,
                    color: _modoEdicao
                        ? Colors.redAccent
                        : const Color(0xFF3B6BE0),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitulo() {
    return const Text(
      'Ficha do Paciente',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3B8B),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(children: [_buildTab('Dados', 0), _buildTab('Consultas', 1)]);
  }

  Widget _buildTab(String label, int index) {
    final bool ativa = _abaAtiva == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _mudarAba(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: ativa ? const Color(0xFF3B6BE0) : Colors.grey.shade300,
                width: 2.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ativa ? const Color(0xFF3B6BE0) : Colors.grey.shade500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}
