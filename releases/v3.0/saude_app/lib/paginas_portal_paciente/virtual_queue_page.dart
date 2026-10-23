import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class _QueueTicket {
  final String id;
  final String ticketNumber;
  final int    queuePosition;
  final String status;
  final String doctorId;

  const _QueueTicket({
    required this.id,
    required this.ticketNumber,
    required this.queuePosition,
    required this.status,
    required this.doctorId,
  });

  factory _QueueTicket.fromRow(Map<String, dynamic> row) {
    return _QueueTicket(
      id:            row['id']             as String,
      ticketNumber:  row['ticket_number']  as String,
      queuePosition: row['queue_position'] as int,
      status:        row['status']         as String,
      doctorId:      row['doctor_id']      as String,
    );
  }
}

class _QueueStats {
  final String? currentlyServing;
  final int totalWaiting;
  final int ahead;
  final int estimatedMinutes;

  const _QueueStats({
    required this.currentlyServing,
    required this.totalWaiting,
    required this.ahead,
    required this.estimatedMinutes,
  });
}

class VirtualQueueScreen extends StatefulWidget {
  const VirtualQueueScreen({super.key});

  @override
  State<VirtualQueueScreen> createState() => _VirtualQueueScreenState();
}

class _VirtualQueueScreenState extends State<VirtualQueueScreen> {
  _QueueTicket? _ticket;
  _QueueStats?  _stats;
  String?      _openSince;
  bool         _loading     = true;
  bool         _leaving     = false;
  String?      _errorMsg;

  /// Polling automático a cada 30 s para manter os dados atualizados.
  Timer? _pollingTimer;


  @override
  void initState() {
    super.initState();
    _loadData();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(silent: true),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }


  Future<_QueueTicket?> _fetchMyTicket() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null) throw Exception('Utilizador não autenticado.');

    final data = await db
        .from('virtual_queue')
        .select('id, ticket_number, queue_position, status, doctor_id')
        .eq('patient_id', user.id)
        .inFilter('status', ['waiting', 'called'])
        .order('issued_at', ascending: false)
        .limit(1);

    final rows = data as List<dynamic>;
    if (rows.isEmpty) return null;
    return _QueueTicket.fromRow(rows.first as Map<String, dynamic>);
  }

  Future<_QueueStats> _fetchStats({
    required String doctorId,
    required int myPosition,
  }) async {
    final data = await Supabase.instance.client
        .from('virtual_queue')
        .select('ticket_number, queue_position, status')
        .eq('doctor_id', doctorId)
        .inFilter('status', ['waiting', 'called'])
        .order('queue_position');

    final rows = List<Map<String, dynamic>>.from(data as List);
    final called = rows.where((r) => r['status'] == 'called').toList();
    String? currentlyServing;
    if (called.isNotEmpty) {
      currentlyServing = called.first['ticket_number'] as String;
    } else if (rows.isNotEmpty) {
      currentlyServing = rows.first['ticket_number'] as String;
    }

    final ahead = rows
    .where((r) =>
        (r['queue_position'] as int) < myPosition &&
        r['status'] != 'called' &&
        r['status'] != 'absent')
    .length;

    return _QueueStats(
      currentlyServing: currentlyServing,
      totalWaiting:     rows.length,
      ahead:            ahead,
      estimatedMinutes: ahead * 4,
    );
  }

  Future<String?> _fetchQueueOpenSince(String doctorId) async {
    final data = await Supabase.instance.client
        .from('virtual_queue')
        .select('issued_at')
        .eq('doctor_id', doctorId)
        .order('issued_at')
        .limit(1);

    final rows = data as List<dynamic>;
    if (rows.isEmpty) return null;

    try {
      final dt = DateTime.parse(rows.first['issued_at'] as String).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _errorMsg = null; });

    try {
      final ticket = await _fetchMyTicket();

      if (ticket == null) {
        if (mounted) setState(() { _ticket = null; _loading = false; });
        return;
      }

      final stats = await _fetchStats(
        doctorId:   ticket.doctorId,
        myPosition: ticket.queuePosition,
      );

      final openSince = await _fetchQueueOpenSince(ticket.doctorId);

      if (mounted) {
        setState(() {
          _ticket    = ticket;
          _stats     = stats;
          _openSince = openSince;
          _loading   = false;
          _errorMsg  = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading  = false;
          _errorMsg = e.toString();
        });
      }
    }
  }


  void _mostrarConfirmacaoAbandonar() {
    final ticket = _ticket;
    if (ticket == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Abandonar Fila',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Tem a certeza que deseja abandonar a fila?\nA sua senha ${ticket.ticketNumber} será cancelada.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF555555),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              // Cancelar
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A8070)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A8070),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sim, abandonar
              Expanded(
                child: ElevatedButton(
                  onPressed: _leaving
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          await _leaveQueue(ticket.id);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A8070),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sim',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _leaveQueue(String ticketId) async {
    setState(() => _leaving = true);
    try {
      await Supabase.instance.client
          .from('virtual_queue')
          .update({'status': 'absent'})
          .eq('id', ticketId);
      if (mounted) {
        // Volta ao dashboard após abandonar
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPaciente()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _leaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abandonar fila: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Fila Virtual',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),

          // Conteúdo principal
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(color: Color(0xFF1A8070)),
              ),
            )
          else if (_errorMsg != null)
            _buildError()
          else if (_ticket == null)
            _buildSemFila()
          else
            _buildFila(),
        ],
      ),
    );
  }


  Widget _buildSemFila() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue, size: 56, color: Color(0xFFB2DFDB)),
            const SizedBox(height: 16),
            const Text(
              'Não está em nenhuma fila.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dirija-se à recepção ou agende\numa consulta para entrar na fila.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF9E9E9E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh, color: Color(0xFF1A8070)),
              label: const Text(
                'Atualizar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF1A8070),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar a fila:\n$_errorMsg',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadData,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF1A8070),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF1A8070),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFila() {
    final ticket = _ticket!;
    final stats  = _stats!;

    final currentlyServing = stats.currentlyServing ?? '–';
    final estimatedLabel   = stats.estimatedMinutes == 0
        ? 'A ser chamado'
        : '~${stats.estimatedMinutes} min';
    final aheadLabel       = stats.ahead == 0
        ? 'É o próximo!'
        : '${stats.ahead} à frente';
    final openSinceLabel   = _openSince != null ? 'desde $_openSince' : '–';

    return Column(
      children: [
        // Label "A TUA SENHA"
        const Text(
          'A TUA SENHA',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A8070),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // Card da senha
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Número da senha
              Text(
                ticket.ticketNumber,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A8070),
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              // A ser atendido agora
              Text(
                'A ser atendido: $currentlyServing',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 4),
              // Tempo estimado + pessoas à frente
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stats.ahead == 0
                          ? Colors.orange
                          : const Color(0xFF1A8070),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    estimatedLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    aheadLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: stats.ahead == 0
                          ? Colors.orange
                          : const Color(0xFF555555),
                      fontWeight: stats.ahead == 0
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card de estatísticas da fila
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _FilaInfoRow(
                svgIcon:       Icons.bar_chart_rounded,
                label:         'Total Fila',
                valor:         '${stats.totalWaiting} pessoas',
                mostrarDivisor: true,
              ),
              _FilaInfoRow(
                svgIcon:       Icons.timer_outlined,
                label:         'Média',
                valor:         '4 min / pessoa',
                mostrarDivisor: true,
              ),
              _FilaInfoRow(
                svgIcon:       Icons.access_time_rounded,
                label:         'Aberta',
                valor:         openSinceLabel,
                mostrarDivisor: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Botão Abandonar Fila
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _leaving ? null : _mostrarConfirmacaoAbandonar,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF0F0),
              side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: _leaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFFE53935),
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Abandonar Fila',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFFE53935),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}


class _FilaInfoRow extends StatelessWidget {
  final IconData svgIcon;
  final String   label;
  final String   valor;
  final bool     mostrarDivisor;

  const _FilaInfoRow({
    required this.svgIcon,
    required this.label,
    required this.valor,
    required this.mostrarDivisor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(svgIcon, size: 20, color: const Color(0xFF1A8070)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                valor,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
        if (mostrarDivisor)
          const Divider(height: 1, color: Color(0xFFB2DFDB)),
      ],
    );
  }
}
