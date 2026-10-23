import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage> {
  String _abaAtiva = 'Hoje';
  DateTime _dataSelecionada = DateTime.now();
  String? _medicoSelecionado;

  List<Map<String, dynamic>> _medicosPorEspecialidade = [];
  List<Map<String, dynamic>> _agendamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final docs = await db
          .from('doctors')
          .select('user_id, users(name, deleted_at), specialties(name)')
          .eq('suspended', false);

      Map<String, List<String>> agrupado = {};
      for (var d in docs) {
        // Excluir médicos cujo user foi soft-deleted
        if (d['users']?['deleted_at'] != null) continue;
        final esp = d['specialties']?['name'] ?? 'Geral';
        final nome = '${d['users']?['name']}';
        agrupado.putIfAbsent(esp, () => []).add(nome);
      }
      _medicosPorEspecialidade = agrupado.entries
          .map((e) => {'especialidade': e.key, 'medicos': e.value})
          .toList();
      var query = db.from('appointments').select(
          'id, scheduled_date, scheduled_time, type, status, doctor_id, '
          'patients(users(name)), doctors(users(name))');

      final dataStr = _dataSelecionada.toIso8601String().split('T')[0];

      if (_abaAtiva == 'Hoje') {
        query = query.eq('scheduled_date', dataStr);
      } else if (_abaAtiva == 'Semana') {
        final fim = _dataSelecionada
            .add(const Duration(days: 6))
            .toIso8601String()
            .split('T')[0];
        query = query.gte('scheduled_date', dataStr).lte('scheduled_date', fim);
      } else {
        query = query.gte('scheduled_date', dataStr);
      }

      final res = await query
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      var filtrados = List<Map<String, dynamic>>.from(res);
      if (_medicoSelecionado != null) {
        filtrados = filtrados
            .where((a) =>
                '${a['doctors']?['users']?['name']}' ==
                _medicoSelecionado)
            .toList();
      }

      if (mounted) {
        setState(() {
          _agendamentos = filtrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro a carregar agendamentos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _atualizarStatus(String id, String novoStatus) async {
    try {
      await db
          .from('appointments')
          .update({'status': novoStatus})
          .eq('id', id);
      _carregarDados();
    } catch (e) {
      debugPrint('Erro ao atualizar estado: $e');
    }
  }

  Future<List<TimeOfDay>> _carregarSlotsDisponiveis(
    String doctorId,
    DateTime data, {
    String? excludeAppointmentId,
  }) async {
    final diaDaSemana = data.weekday; // 1=Segunda … 7=Domingo

    //Disponibilidade do médico para este dia da semana
    final availRes = await db
        .from('doctor_availability')
        .select()
        .eq('doctor_id', doctorId)
        .eq('day_of_week', diaDaSemana);

    if (availRes.isEmpty) return [];

    //Slots bloqueados que intersectam este dia
    final diaInicio =
        DateTime(data.year, data.month, data.day, 0, 0, 0).toUtc();
    final diaFim =
        DateTime(data.year, data.month, data.day, 23, 59, 59).toUtc();

    final blockedRes = await db
        .from('blocked_slots')
        .select()
        .eq('doctor_id', doctorId)
        .lte('start_datetime', diaFim.toIso8601String())
        .gte('end_datetime', diaInicio.toIso8601String());

    //Consultas já marcadas para este médico neste dia (exceto canceladas)
    final dataStr =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    var apptQuery = db
        .from('appointments')
        .select('id, scheduled_time')
        .eq('doctor_id', doctorId)
        .eq('scheduled_date', dataStr)
        .neq('status', 'canceled');

    final apptRes = await apptQuery;

    final Set<String> horasOcupadas = {};
    for (var appt in apptRes) {
      // Ao reagendar, não bloquear o slot da própria consulta
      if (excludeAppointmentId != null &&
          appt['id'].toString() == excludeAppointmentId) continue;
      final t = appt['scheduled_time'].toString().substring(0, 5);
      horasOcupadas.add(t);
    }

    // Gerar slots válidos para cada período de disponibilidade
    final List<TimeOfDay> slotsDisponiveis = [];

    for (var avail in availRes) {
      final startParts = avail['start_time'].toString().split(':');
      final endParts = avail['end_time'].toString().split(':');
      final duracao = avail['slot_duration_min'] as int;

      int minutosAtual =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final minutosFim =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      while (minutosAtual + duracao <= minutosFim) {
        final h = minutosAtual ~/ 60;
        final m = minutosAtual % 60;
        final slotStr =
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

        final slotDt =
            DateTime(data.year, data.month, data.day, h, m).toUtc();
        final slotFimDt = slotDt.add(Duration(minutes: duracao));

        // Verificar sobreposição com blocked_slots
        bool bloqueado = false;
        for (var bl in blockedRes) {
          final blStart = DateTime.parse(bl['start_datetime']);
          final blEnd = DateTime.parse(bl['end_datetime']);
          if (slotDt.isBefore(blEnd) && slotFimDt.isAfter(blStart)) {
            bloqueado = true;
            break;
          }
        }

        if (!bloqueado && !horasOcupadas.contains(slotStr)) {
          slotsDisponiveis.add(TimeOfDay(hour: h, minute: m));
        }

        minutosAtual += duracao;
      }
    }

    return slotsDisponiveis;
  }
  Future<void> _abrirCalendario(BuildContext context) async {
    final DateTime? colhido = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B9CE8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A3B8B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (colhido != null && colhido != _dataSelecionada) {
      setState(() => _dataSelecionada = colhido);
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agendamentos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              ElevatedButton(
                onPressed: _abrirNovoAgendamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B9CE8),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/imagens_portal_recepcao/Plus.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                          Colors.white, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Agendar',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildMedicoDropdown()),
              const SizedBox(width: 20),
              Expanded(child: _buildDateSelector(context)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildTab('Hoje'),
              _buildTab('Semana'),
              _buildTab('Todos'),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF6B9CE8)),
              ),
            )
          else if (_agendamentos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Nenhum agendamento encontrado.',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
            )
          else
            ..._agendamentos.map((appt) {
              final horaCompleta = appt['scheduled_time'].toString();
              final horaF = horaCompleta.length >= 5
                  ? horaCompleta.substring(0, 5)
                  : horaCompleta;

              String infoTemporal = horaF;
              if (_abaAtiva != 'Hoje') {
                final d = DateTime.parse(appt['scheduled_date']);
                infoTemporal =
                    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} · $horaF';
              }

              return _buildAgendamentoCard(
                id: appt['id'],
                hora: infoTemporal,
                titulo:
                    '${appt['patients']?['users']?['name'] ?? 'Utente'} · ${appt['doctors']?['users']?['name'] ?? 'Médico'}',
                isUrgente: appt['type'] == 'urgent',
                status: appt['status'],
              );
            }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMedicoDropdown() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF6B9CE8), width: 1.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _medicoSelecionado,
          isExpanded: true,
          menuMaxHeight: 500, 
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3B6BE0)),
          hint: Row(
            children: [
              SvgPicture.asset(
                'assets/imagens_portal_recepcao/People.svg',
                width: 18,
                colorFilter: const ColorFilter.mode(
                    Color(0xFF3B6BE0), BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              const Text('Médico: Todos',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A97A9))),
            ],
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todos os Médicos',
                  style: TextStyle(fontSize: 13, color: Colors.black87)),
            ),
            ..._medicosPorEspecialidade
                .expand<DropdownMenuItem<String>>((esp) {
              final especialidade = esp['especialidade'] as String;
              final medicos = esp['medicos'] as List<String>;
              return [
                DropdownMenuItem<String>(
                  enabled: false,
                  value: 'header_$especialidade',
                  child: Text(especialidade,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 11)),
                ),
                ...medicos.map<DropdownMenuItem<String>>((medico) =>
                    DropdownMenuItem<String>(
                      value: medico,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(medico,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ),
                    )),
              ];
            }),
          ],
          onChanged: (novoValor) {
            setState(() {
              if (novoValor == null || !novoValor.startsWith('header_')) {
                _medicoSelecionado = novoValor;
              }
            });
            _carregarDados();
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirCalendario(context),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF6B9CE8), width: 1.5),
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/imagens_portal_recepcao/Schedule.svg',
              width: 18,
              colorFilter: const ColorFilter.mode(
                  Color(0xFF3B6BE0), BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            Text(
              '${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A97A9),
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final bool isActive = _abaAtiva == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _abaAtiva = label);
          _carregarDados();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? const Color(0xFF6B9CE8)
                    : const Color(0xFFB0BEC5).withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color:
                  isActive ? const Color(0xFF6B9CE8) : const Color(0xFF90A4AE),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard({
    required String id,
    required String hora,
    required String titulo,
    required bool isUrgente,
    required String status,
  }) {
    final bool inativo = status == 'canceled' || status == 'no_show';
    final bool concluido = status == 'completed';

    return Opacity(
      opacity: inativo ? 0.5 : (concluido ? 0.8 : 1.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFFDFEDFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                  width: 4,
                  color: inativo
                      ? Colors.redAccent
                      : const Color(0xFF4A78D6)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                hora,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: inativo
                                      ? Colors.redAccent
                                      : const Color(0xFF4A78D6),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              if (status != 'scheduled') ...[
                                const SizedBox(width: 8),
                                Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins'),
                                ),
                              ]
                            ],
                          ),
                          _buildTag(isUrgente),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (status == 'scheduled') _buildAcoes(id),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(bool isUrgente) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgente
            ? const Color(0xFFFDF0D5)
            : const Color(0xFFCDE2F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isUrgente ? 'Urgente' : 'Normal',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isUrgente
              ? const Color(0xFFB8860B)
              : const Color(0xFF1A3B8B),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildAcoes(String id) {
    return Row(
      children: [
        _buildBotaoAcao('Ver', () => _mostrarDetalhesConsulta(id)),
        const SizedBox(width: 16),
        _buildBotaoAcao('Alterar', () => _abrirAlterarAgendamento(id)),
        const SizedBox(width: 16),
        _buildBotaoAcao('Cancelar', () => _atualizarStatus(id, 'canceled'),
            isRed: true),
      ],
    );
  }

  Widget _buildBotaoAcao(String label, VoidCallback onTap,
      {bool isRed = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isRed ? const Color(0xFFD32F2F) : const Color(0xFF6B9CE8),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  /// Renderiza os slots disponíveis como chips selecionáveis.
  Widget _buildSlotSelector({
    required List<TimeOfDay> slots,
    required TimeOfDay? slotSelecionado,
    required ValueChanged<TimeOfDay> onSelected,
  }) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: const Row(
          children: [
            Icon(Icons.block, size: 16, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sem horários disponíveis para este dia.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE65100),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final label =
            '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
        final isSelected = slot == slotSelecionado;
        return GestureDetector(
          onTap: () => onSelected(slot),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B6BE0)
                  : const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B6BE0)
                    : const Color(0xFF6B9CE8),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? Colors.white : const Color(0xFF3B6BE0),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _mostrarDetalhesConsulta(String id) {
    final appt = _agendamentos.firstWhere((e) => e['id'] == id);
    final paciente = appt['patients']?['users']?['name'] ?? 'Desconhecido';
    final medico =
        '${appt['doctors']?['users']?['name'] ?? 'Desconhecido'}';
    final dataCrua = DateTime.parse(appt['scheduled_date']);
    final data =
        '${dataCrua.day.toString().padLeft(2, '0')}/${dataCrua.month.toString().padLeft(2, '0')}/${dataCrua.year}';
    final hora = appt['scheduled_time'].toString().substring(0, 5);

    String tipoStr = 'Normal';
    if (appt['type'] == 'urgent') tipoStr = 'Urgente';
    if (appt['type'] == 'follow_up') tipoStr = 'Revisão';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Detalhes da Consulta',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Utente: $paciente',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            const SizedBox(height: 8),
            Text('Médico: $medico',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            const SizedBox(height: 8),
            Text('Data: $data às $hora',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            const SizedBox(height: 8),
            Text('Tipo: $tipoStr',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: const Text(
                'Sem acesso a diagnósticos ou notas médicas.',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB7950B),
                    fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar',
                style: TextStyle(color: Color(0xFF3B6BE0))),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirAlterarAgendamento(String id) async {
    final appt = _agendamentos.firstWhere((e) => e['id'] == id);
    final String doctorId = appt['doctor_id'].toString();

    DateTime dataEscolhida = DateTime.parse(appt['scheduled_date']);
    TimeOfDay? slotSelecionado = TimeOfDay(
      hour: int.parse(appt['scheduled_time'].toString().split(':')[0]),
      minute: int.parse(appt['scheduled_time'].toString().split(':')[1]),
    );

    bool isSaving = false;
    bool isLoadingSlots = true;
    List<TimeOfDay> slots = [];

    slots = await _carregarSlotsDisponiveis(
      doctorId,
      dataEscolhida,
      excludeAppointmentId: id,
    );
    if (!slots.contains(slotSelecionado)) {
      slots.insert(0, slotSelecionado);
    }
    isLoadingSlots = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Reagendar Consulta',
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: isSaving
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seletor de data
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data',
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13)),
                        subtitle: Text(
                          '${dataEscolhida.day}/${dataEscolhida.month}/${dataEscolhida.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_month,
                            color: Color(0xFF3B6BE0)),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: dataEscolhida,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) {
                            setStateModal(() {
                              dataEscolhida = d;
                              slotSelecionado = null;
                              isLoadingSlots = true;
                              slots = [];
                            });
                            final novosSlots =
                                await _carregarSlotsDisponiveis(
                              doctorId,
                              d,
                              excludeAppointmentId: id,
                            );
                            setStateModal(() {
                              slots = novosSlots;
                              isLoadingSlots = false;
                            });
                          }
                        },
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      // Seletor de slot
                      const Text('Horário disponível',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.black54)),
                      const SizedBox(height: 10),
                      if (isLoadingSlots)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Color(0xFF6B9CE8)),
                          ),
                        )
                      else
                        _buildSlotSelector(
                          slots: slots,
                          slotSelecionado: slotSelecionado,
                          onSelected: (s) =>
                              setStateModal(() => slotSelecionado = s),
                        ),
                    ],
                  ),
                ),
          actions: [
            if (!isSaving)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey)),
              ),
            if (!isSaving)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6BE0)),
                onPressed: slotSelecionado != null
                    ? () async {
                        setStateModal(() => isSaving = true);
                        try {
                          final dataStr =
                              '${dataEscolhida.year}-${dataEscolhida.month.toString().padLeft(2, '0')}-${dataEscolhida.day.toString().padLeft(2, '0')}';
                          final horaStr =
                              '${slotSelecionado!.hour.toString().padLeft(2, '0')}:${slotSelecionado!.minute.toString().padLeft(2, '0')}:00';

                          await db.from('appointments').update({
                            'scheduled_date': dataStr,
                            'scheduled_time': horaStr,
                          }).eq('id', id);

                          if (mounted) Navigator.pop(context);
                          _carregarDados();
                        } catch (e) {
                          setStateModal(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro: $e')));
                        }
                      }
                    : null,
                child: const Text('Guardar',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
  Future<void> _abrirNovoAgendamento() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );
    try {
      final pacientes = await db
          .from('users')
          .select('id, name')
          .eq('role', 'patient')
          .order('name');
      final medicosRaw =
          await db.from('doctors').select('user_id, users(name, deleted_at)').eq('suspended', false);
      // Excluir médicos cujo user foi soft-deleted
      final medicos = (medicosRaw as List).where((m) => m['users']?['deleted_at'] == null).toList();

      if (mounted) Navigator.pop(context);
      if (mounted) _mostrarDialogoNovoAgendamento(pacientes, medicos);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Erro ao abrir formulário de agendamento: $e');
    }
  }

  void _mostrarDialogoNovoAgendamento(
    List<dynamic> pacientes,
    List<dynamic> medicos,
  ) {
    String? pId;
    String? mId;
    String tipoConsulta = 'normal';
    DateTime dEscolhida = DateTime.now();
    TimeOfDay? slotSelecionado;
    bool isSaving = false;
    bool isLoadingSlots = false;
    List<TimeOfDay> slots = [];

    // Recarrega slots sempre que médico ou data mudam
    Future<void> recarregarSlots(
        StateSetter setStateModal, String doctorId, DateTime data) async {
      setStateModal(() {
        isLoadingSlots = true;
        slots = [];
        slotSelecionado = null;
      });
      final novosSlots =
          await _carregarSlotsDisponiveis(doctorId, data);
      setStateModal(() {
        slots = novosSlots;
        isLoadingSlots = false;
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Nova Consulta',
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: isSaving
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Utente
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Utente',
                            border: OutlineInputBorder()),
                        isExpanded: true,
                        items: pacientes
                            .map((p) => DropdownMenuItem<String>(
                                  value: p['id'].toString(),
                                  child: Text(p['name'].toString()),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setStateModal(() => pId = v),
                      ),
                      const SizedBox(height: 12),
                      // Médico
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Médico',
                            border: OutlineInputBorder()),
                        isExpanded: true,
                        items: medicos
                            .map((m) => DropdownMenuItem<String>(
                                  value: m['user_id'].toString(),
                                  child: Text(
                                      '${m['users']['name']}'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setStateModal(() => mId = v);
                          if (v != null) {
                            recarregarSlots(
                                setStateModal, v, dEscolhida);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder()),
                        value: tipoConsulta,
                        items: const [
                          DropdownMenuItem(
                              value: 'normal', child: Text('Normal')),
                          DropdownMenuItem(
                              value: 'urgent', child: Text('Urgente')),
                          DropdownMenuItem(
                              value: 'follow_up', child: Text('Revisão')),
                        ],
                        onChanged: (v) =>
                            setStateModal(() => tipoConsulta = v!),
                      ),
                      const SizedBox(height: 12),
                      // Data
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: dEscolhida,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) {
                            setStateModal(() => dEscolhida = d);
                            if (mId != null) {
                              recarregarSlots(
                                  setStateModal, mId!, d);
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Data',
                              border: OutlineInputBorder()),
                          child: Text(
                              '${dEscolhida.day}/${dEscolhida.month}/${dEscolhida.year}'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Slots disponíveis
                      if (mId == null)
                        const Text(
                          'Selecione um médico para ver os horários disponíveis.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'Poppins'),
                        )
                      else ...[
                        const Text(
                          'Horário disponível',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        if (isLoadingSlots)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: Color(0xFF6B9CE8)),
                            ),
                          )
                        else
                          _buildSlotSelector(
                            slots: slots,
                            slotSelecionado: slotSelecionado,
                            onSelected: (s) =>
                                setStateModal(() => slotSelecionado = s),
                          ),
                      ],
                    ],
                  ),
                ),
          actions: [
            if (!isSaving)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey)),
              ),
            if (!isSaving)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6BE0)),
                onPressed:
                    (pId != null && mId != null && slotSelecionado != null)
                        ? () async {
                            setStateModal(() => isSaving = true);
                            try {
                              final dataStr =
                                  '${dEscolhida.year}-${dEscolhida.month.toString().padLeft(2, '0')}-${dEscolhida.day.toString().padLeft(2, '0')}';
                              final horaStr =
                                  '${slotSelecionado!.hour.toString().padLeft(2, '0')}:${slotSelecionado!.minute.toString().padLeft(2, '0')}:00';

                              await db.from('appointments').insert({
                                'id': const Uuid().v4(),
                                'patient_id': pId,
                                'doctor_id': mId,
                                'scheduled_date': dataStr,
                                'scheduled_time': horaStr,
                                'duration_min': 30,
                                'type': tipoConsulta,
                                'status': 'scheduled',
                                'created_by': db.auth.currentUser?.id,
                              });

                              if (mounted) Navigator.pop(context);
                              _carregarDados();
                            } catch (e) {
                              setStateModal(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro: $e')));
                            }
                          }
                        : null,
                child: const Text('Agendar',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}