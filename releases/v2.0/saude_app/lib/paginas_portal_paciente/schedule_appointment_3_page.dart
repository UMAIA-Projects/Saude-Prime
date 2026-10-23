import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';
import 'package:uuid/uuid.dart';

const Map<String, String> _tipoParaEnum = {
  'Normal':         'normal',
  'Urgência':       'urgent',
  'Acompanhamento': 'follow_up',
};

class ScheduleAppointment3Page extends StatefulWidget {
  // Novo: doctorId e scheduledDate para o INSERT
  final String   doctorId;
  final DateTime scheduledDate;

  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;
  final String data;
  final String hora;
  final String tipo;
  final String notas;

  const ScheduleAppointment3Page({
    super.key,
    required this.doctorId,
    required this.scheduledDate,
    this.medicoInitials      = 'CF',
    this.medicoNome          = 'Dr. Carlos Ferreira',
    this.medicoEspecialidade = 'Clínica Geral',
    this.data                = 'Qui, 27 de Março',
    this.hora                = '10:30',
    this.tipo                = 'Consulta Geral',
    this.notas               = '-',
  });

  @override
  State<ScheduleAppointment3Page> createState() => _ScheduleAppointment3PageState();
}

class _ScheduleAppointment3PageState extends State<ScheduleAppointment3Page> {
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);

  int  _navIndex    = 1;
  bool _lembrete24h = true;
  bool _saving      = false;
  String? _erro;

  Future<void> _confirmar() async {
    setState(() { _saving = true; _erro = null; });

    try {
      // Obtém o patient_id do utilizador autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utilizador não autenticado.');

      final dateStr = '${widget.scheduledDate.year}-'
          '${widget.scheduledDate.month.toString().padLeft(2, '0')}-'
          '${widget.scheduledDate.day.toString().padLeft(2, '0')}';
      final notas = widget.notas == '-' ? null : widget.notas;
      await Supabase.instance.client.from('appointments').insert({
        'id':             const Uuid().v4(),
        'patient_id':     user.id,
        'doctor_id':      widget.doctorId,
        'scheduled_date': dateStr,
        'scheduled_time': '${widget.hora}:00',
        'type':           _tipoParaEnum[widget.tipo] ?? 'normal',
        'status':         'scheduled',
        'patient_notes':  (notas == null || notas.isEmpty) ? null : notas,
        'created_by':     user.id,
      });

      if (!mounted) return;

      // Navega para MyAppointmentsPage e limpa o stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MyAppointmentsPage(
            novaConsulta: {
              'datetime':  '${widget.data} • ${widget.hora}',
              'doctor':    widget.medicoNome,
              'specialty': widget.medicoEspecialidade,
              'status':    'Agendada',
              'initials':  widget.medicoInitials,
              'telefone':  '-',
              'data':      widget.data,
              'hora':      widget.hora,
              'tipo':      widget.tipo,
              'notas':     widget.notas,
            },
          ),
        ),
        (route) => false,
      );
    } catch (e, stack) {
      print('>>> ERRO: $e');
      setState(() {
        _erro   = e.toString(); // erro real no ecrã
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + progresso
          const Text(
            'Marcar Consulta - Confirmar',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          Row(children: [
            _ProgressBar(color: _accent),
            const SizedBox(width: 4),
            _ProgressBar(color: _accent),
            const SizedBox(width: 4),
            _ProgressBar(color: _accent),
          ]),
          const SizedBox(height: 16),

          // Card resumo
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10)],
            ),
            child: Column(
              children: [
                // Médico
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: _accent, shape: BoxShape.circle, border: Border.all(color: _accentBorder, width: 2)),
                        alignment: Alignment.center,
                        child: Text(widget.medicoInitials, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.medicoNome, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
                          Text(widget.medicoEspecialidade, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _textSub)),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE0F0EE)),

                _DetailRow(icon: Icons.calendar_today_outlined,   label: 'Data',  value: widget.data),
                _DetailRow(icon: Icons.access_time_outlined,      label: 'Hora',  value: widget.hora),
                _DetailRow(icon: Icons.medical_services_outlined, label: 'Tipo',  value: widget.tipo),
                _DetailRow(icon: Icons.edit_outlined,             label: 'Notas', value: widget.notas.isEmpty ? '-' : widget.notas, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Política de cancelamento
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E0),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFFFC107), width: 2),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Política de Cancelamento\n',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7A5000)),
                  ),
                  TextSpan(
                    text: 'Cancelamentos devem ser feitos com pelo menos 24h de antecedência.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF7A5000)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Toggle lembrete 24h
          GestureDetector(
            onTap: () => setState(() => _lembrete24h = !_lembrete24h),
            child: Row(
              children: [
                Icon(_lembrete24h ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, color: _primary, size: 18),
                const SizedBox(width: 8),
                const Text('Lembrete 24h antes', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _primary)),
                const Spacer(),
                Switch(
                  value: _lembrete24h,
                  onChanged: (v) => setState(() => _lembrete24h = v),
                  activeThumbColor: _accent,
                  activeTrackColor: const Color(0xFF3DBDAD),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mensagem de erro (se houver)
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_erro!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.red)),
            ),

          // Botão confirmar
          GestureDetector(
            onTap: _saving ? null : _confirmar,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _saving ? const Color(0xFFB2EAE4) : _accent,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10)],
              ),
              alignment: Alignment.center,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar Marcação',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Voltar atrás
          GestureDetector(
            onTap: _saving ? null : () => Navigator.pop(context),
            child: const Center(
              child: Text(
                '← Voltar atrás',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


class _ProgressBar extends StatelessWidget {
  final Color color;
  const _ProgressBar({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 110, height: 3,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  static const Color _primary   = Color(0xFF1A8070);
  static const Color _textMuted = Color(0xFF6A9890);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: _primary, size: 14),
              const SizedBox(width: 8),
              SizedBox(width: 60, child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary))),
              const SizedBox(width: 8),
              Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _textMuted))),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0F0EE)),
      ],
    );
  }
}
