import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class FilaVirtualPage extends StatefulWidget {
  const FilaVirtualPage({super.key});

  @override
  State<FilaVirtualPage> createState() => _FilaVirtualPageState();
}

class _FilaVirtualPageState extends State<FilaVirtualPage> {
  bool _isLoading = true;

  String _senhaAtual = '--';
  int _totalEmEspera = 0;
  String _proximaSenha = '--';

  List<Map<String, dynamic>> _filaHoje = [];

  @override
  void initState() {
    super.initState();
    _carregarFilaVirtual();
  }

  Future<void> _carregarFilaVirtual() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final hoje = DateTime.now();
      final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day).toIso8601String();
      final fimDoDia = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59).toIso8601String();

      final List<dynamic> filaData = await db
          .from('virtual_queue')
          .select('''
            id,
            ticket_number,
            status,
            issued_at,
            patients ( users ( name ) )
          ''')
          .gte('issued_at', inicioDoDia)
          .lte('issued_at', fimDoDia)
          .order('issued_at', ascending: true);

      String atual = '--';
      String proxima = '--';
      int emEspera = 0;
      List<dynamic> listaEspera = [];

      for (var ticket in filaData) {
        final status = ticket['status'];
        if (status == 'called') {
          atual = ticket['ticket_number']?.toString() ?? '--';
        } else if (status == 'waiting') {
          emEspera++;
          listaEspera.add(ticket);
        }
      }

      if (listaEspera.isNotEmpty) {
        proxima = listaEspera.first['ticket_number']?.toString() ?? '--';
      }

      if (mounted) {
        setState(() {
          _senhaAtual = atual;
          _totalEmEspera = emEspera;
          _proximaSenha = proxima;
          _filaHoje = List<Map<String, dynamic>>.from(filaData);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro a carregar Fila Virtual: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _atualizarStatusSenha(String id, String novoStatus) async {
    try {
      final updateData = {'status': novoStatus};
      if (novoStatus == 'called') {
        updateData['called_at'] = DateTime.now().toUtc().toIso8601String();
      }

      await db.from('virtual_queue').update(updateData).eq('id', id);
      await _carregarFilaVirtual();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Senha atualizada para: $novoStatus')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar senha: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _abrirDialogoEmissao() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF2D7BDA))),
    );

    try {
      // Como users tem RLS desativado, conseguimos ler todos para popular as dropdowns
      final pacientes = await db.from('users').select('id, name').eq('role', 'patient').order('name');
      final medicos = await db.from('users').select('id, name').eq('role', 'doctor').order('name');

      if (mounted) Navigator.pop(context);

      if (mounted) {
        _mostrarModalSelecao(pacientes, medicos);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Erro: $e');
    }
  }

  void _mostrarModalSelecao(List<dynamic> pacientes, List<dynamic> medicos) {
    String? selectedPatientId;
    String? selectedDoctorId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Emitir Nova Senha', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              content: isSubmitting
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Color(0xFF2D7BDA))))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Paciente', border: OutlineInputBorder()),
                          value: selectedPatientId,
                          isExpanded: true,
                          items: pacientes.map((p) => DropdownMenuItem<String>(
                            value: p['id'].toString(),
                            child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) => setStateModal(() => selectedPatientId = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Médico', border: OutlineInputBorder()),
                          value: selectedDoctorId,
                          isExpanded: true,
                          items: medicos.map((m) => DropdownMenuItem<String>(
                            value: m['id'].toString(),
                            child: Text(m['name'].toString(), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) => setStateModal(() => selectedDoctorId = val),
                        ),
                      ],
                    ),
              actions: [
                if (!isSubmitting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                if (!isSubmitting)
                  ElevatedButton(
                    onPressed: (selectedPatientId != null && selectedDoctorId != null)
                        ? () async {
                            setStateModal(() => isSubmitting = true);
                            await _processarEmissao(selectedPatientId!, selectedDoctorId!);
                            if (mounted) Navigator.pop(context); // Fecha o modal após inserir
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B9CE8)),
                    child: const Text('Emitir Senha', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _processarEmissao(String patientId, String doctorId) async {
    try {
      final hojeData = DateTime.now().toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
      
      final consultaData = await db
          .from('appointments')
          .select('id')
          .eq('patient_id', patientId)
          .eq('doctor_id', doctorId)
          .eq('scheduled_date', hojeData)
          .eq('status', 'scheduled')
          .maybeSingle(); // maybeSingle retorna null se não houver nada

      String? appointmentId;
      if (consultaData != null) {
        appointmentId = consultaData['id'];
      }

      final novaSenhaUuid = const Uuid().v4();
      final proximaPosicao = _filaHoje.length + 1;

      final numeroSenha = 'S${proximaPosicao.toString().padLeft(3, '0')}';

      final insertPayload = {
        'id': novaSenhaUuid,
        'ticket_number': numeroSenha,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'status': 'waiting',
        'queue_position': proximaPosicao,
      };

      // Injeta o ID da consulta se a tivermos encontrado
      if (appointmentId != null) {
        insertPayload['appointment_id'] = appointmentId;
      }

      await db.from('virtual_queue').insert(insertPayload);
      await _carregarFilaVirtual();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appointmentId != null 
                  ? 'Senha $numeroSenha emitida. Consulta associada automaticamente!' 
                  : 'Senha $numeroSenha emitida (Utente sem consulta hoje).',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao emitir senha: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao emitir senha: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 3,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D7BDA)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fila Virtual',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    ElevatedButton(
                      // Chama o processo de emissão (loading -> modal -> insert)
                      onPressed: () => _abrirDialogoEmissao(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9CE8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Emitir',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

               // --- ESTATÍSTICAS DO TOPO ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFEDFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4A78D6), width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('A ser atendido', style: TextStyle(fontSize: 12, color: Color(0xFF7A97A9), fontFamily: 'Poppins')),
                          const SizedBox(height: 8),
                          Text(_senhaAtual, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A3B8B), fontFamily: 'Poppins')),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Em espera', style: TextStyle(fontSize: 12, color: Color(0xFF7A97A9), fontFamily: 'Poppins')),
                          const SizedBox(height: 8),
                          Text(_totalEmEspera.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A3B8B), fontFamily: 'Poppins')),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Próxima', style: TextStyle(fontSize: 12, color: Color(0xFF7A97A9), fontFamily: 'Poppins')),
                          const SizedBox(height: 8),
                          Text(_proximaSenha, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A3B8B), fontFamily: 'Poppins')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Fila Completa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5BA2E0), fontFamily: 'Poppins')),
                const SizedBox(height: 10),

                // LISTA DE SENHAS DINÂMICA 
                if (_filaHoje.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Não há senhas emitidas hoje.", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                  )
                else
                  ..._filaHoje.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ticket = entry.value;

                    String horaFormatada = '--:--';
                    if (ticket['issued_at'] != null) {
                      final dataCrua = DateTime.parse(ticket['issued_at']).toLocal();
                      horaFormatada = '${dataCrua.hour.toString().padLeft(2, '0')}:${dataCrua.minute.toString().padLeft(2, '0')}';
                    }

                    final pData = ticket['patients'];
                    final nomePaciente = (pData != null && pData['users'] != null) ? pData['users']['name'] : 'Sem Nome Registado';
                    final senha = ticket['ticket_number']?.toString() ?? '---';
                    final status = ticket['status'];
                    final ticketId = ticket['id'];

                    return _buildFilaItem(
                      id: ticketId,
                      pos: (index + 1).toString(),
                      senha: senha,
                      nome: nomePaciente,
                      hora: horaFormatada,
                      status: status,
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildFilaItem({
    required String id,
    required String pos,
    required String senha,
    required String nome,
    required String hora,
    required String status,
  }) {
    final isAtiva = status == 'waiting' || status == 'called';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 1.5))),
      child: Opacity(
        opacity: isAtiva ? 1.0 : 0.4,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(pos, style: const TextStyle(fontSize: 12, color: Color(0xFFB0BEC5), fontFamily: 'Poppins')),
            ),
            Container(
              width: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFB8D4FB), borderRadius: BorderRadius.circular(12)),
              child: Text(senha, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3B8B), fontFamily: 'Poppins')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(nome, style: const TextStyle(fontSize: 12, color: Colors.black87, fontFamily: 'Poppins', overflow: TextOverflow.ellipsis)),
            ),
            SizedBox(
              width: 40,
              child: Text(hora, style: const TextStyle(fontSize: 11, color: Colors.black45, fontFamily: 'Poppins')),
            ),
            if (status == 'waiting') ...[
              GestureDetector(
                onTap: () => _atualizarStatusSenha(id, 'called'),
                child: const Text('Chamar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4BA3E3), fontFamily: 'Poppins')),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _atualizarStatusSenha(id, 'absent'),
                child: const Text('Ausente', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F), fontFamily: 'Poppins')),
              ),
            ] else ...[
              SizedBox(
                width: 80,
                child: Text(
                  status.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
