import 'package:saude_app/paginas_portal_medico/portal_medico.dart';


//  Modelo
class _QueueEntry {
  final String id;
  final String ticketNumber;
  final int position;
  final String patientName;
  final String status; // 'waiting' | 'called' | 'attended' | 'absent'
  final DateTime issuedAt;

  const _QueueEntry({
    required this.id,
    required this.ticketNumber,
    required this.position,
    required this.patientName,
    required this.status,
    required this.issuedAt,
  });
}


//  Página
class VirtualQueue extends StatefulWidget {
  const VirtualQueue({super.key});

  @override
  State<VirtualQueue> createState() => _VirtualQueueState();
}

class _VirtualQueueState extends State<VirtualQueue> {
  List<_QueueEntry> _waiting = [];
  _QueueEntry? _current; // próxima (posição 1)
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = db.auth.currentUser?.id;
      if (userId == null) throw Exception('Sem sessão ativa');

      final rows = await db
          .from('virtual_queue')
          .select('''
            id,
            ticket_number,
            queue_position,
            status,
            issued_at,
            patients!inner(
              users!inner(name)
            )
          ''')
          .eq('doctor_id', userId)
          .eq('status', 'waiting')
          .order('queue_position', ascending: true);

      final List<_QueueEntry> entries = rows.map<_QueueEntry>((r) {
        return _QueueEntry(
          id: r['id'] as String,
          ticketNumber: r['ticket_number'] as String,
          position: r['queue_position'] as int,
          patientName: r['patients']['users']['name'] as String? ?? 'Desconhecido',
          status: r['status'] as String,
          issuedAt: DateTime.parse(r['issued_at'] as String).toLocal(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _current  = entries.isNotEmpty ? entries.first : null;
        _waiting  = entries.length > 1 ? entries.sublist(1) : [];
        _loading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _callNext() async {
    if (_current == null) return;
    await db
        .from('virtual_queue')
        .update({'status': 'called', 'called_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', _current!.id);
    _load();
  }

  Future<void> _markAttended() async {
    if (_current == null) return;
    await db
        .from('virtual_queue')
        .update({'status': 'attended', 'attended_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', _current!.id);
    _load();
  }

  Future<void> _markAbsent() async {
    if (_current == null) return;
    await db
        .from('virtual_queue')
        .update({'status': 'absent'})
        .eq('id', _current!.id);
    _load();
  }

  String _waitMinutes(_QueueEntry e) {
    final mins = DateTime.now().difference(e.issuedAt).inMinutes;
    return '$mins min espera';
  }

  String _issuedTime(_QueueEntry e) {
    final h = e.issuedAt.hour.toString().padLeft(2, '0');
    final m = e.issuedAt.minute.toString().padLeft(2, '0');
    return 'Chegou $h:$m';
  }

  //  Build
  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      currentIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fila Virtual',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: Colors.black, fontFamily: 'Poppins',
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Color(0xFF3DBDAD)),
                tooltip: 'Atualizar',
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CircularProgressIndicator(color: Color(0xFF3DBDAD)),
              ),
            )
          else if (_error != null)
            _ErrorBanner(message: _error!, onRetry: _load)
          else if (_current == null)
            _EmptyQueue()
          else ...[
            // Card: próxima a atender
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0x233DBDAD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x473DBDAD), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'PRÓXIMA A ATENDER',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF1A6B62), fontFamily: 'Poppins', letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _current!.ticketNumber,
                    style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A6B62), fontFamily: 'Poppins', height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_current!.patientName} • ${_issuedTime(_current!)} • ${_waitMinutes(_current!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.55),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Chamar
                      _QueueActionBtn(
                        label: 'Chamar',
                        icon: Icons.volume_up_outlined,
                        bg: const Color(0xFF3DBDAD),
                        fg: Colors.white,
                        onTap: _callNext,
                      ),
                      const SizedBox(width: 10),
                      // Atendido
                      _QueueActionBtn(
                        label: 'Atendido',
                        icon: Icons.check_circle_outline,
                        bg: const Color(0xFFE8F5E9),
                        fg: const Color(0xFF2E7D32),
                        onTap: _markAttended,
                      ),
                      const SizedBox(width: 10),
                      // Ausente
                      _QueueActionBtn(
                        label: 'Ausente',
                        icon: Icons.person_off_outlined,
                        bg: const Color(0xFFFFF0F0),
                        fg: const Color(0xFFCC3A44),
                        onTap: _markAbsent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Em espera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EM ESPERA',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A8070), fontFamily: 'Poppins', letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${_waiting.length} ${_waiting.length == 1 ? 'pessoa' : 'pessoas'}',
                  style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6A9890), fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_waiting.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Não há mais ninguém em espera.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6A9890), fontFamily: 'Poppins'),
                ),
              )
            else
              ..._waiting.map((e) => _WaitingCard(entry: e)),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


//  Widgets auxiliares
class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 48, color: Color(0xFF3DBDAD)),
            const SizedBox(height: 12),
            const Text(
              'Fila virtual vazia',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.black54, fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Não há pacientes em espera.',
              style: TextStyle(
                fontSize: 13, color: Color(0xFF6A9890), fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, fg;
  final VoidCallback onTap;

  const _QueueActionBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: fg, fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final _QueueEntry entry;
  const _WaitingCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final h = entry.issuedAt.hour.toString().padLeft(2, '0');
    final m = entry.issuedAt.minute.toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // posição
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${entry.position}',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A8070), fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.ticketNumber,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.black, fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '${entry.patientName} • $h:$m',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.45),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE65100), size: 36),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente',
                  style: TextStyle(color: Color(0xFF3DBDAD), fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}