import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

enum TipoConsulta { normal, urgente, bloqueado, analise }

class ConsultaPage extends StatefulWidget {
  final String? appointmentId;
  final String? nomePaciente;
  final String? iniciais;
  final String? nif;
  final String? data;
  final String? hora;
  final TipoConsulta? tipoConsulta;
  final String? motivo;
  final String? notas;

  const ConsultaPage({
    super.key,
    this.appointmentId,
    this.nomePaciente,
    this.iniciais,
    this.nif,
    this.data,
    this.hora,
    this.tipoConsulta,
    this.motivo,
    this.notas,
  }) : assert(
         appointmentId != null ||
             (nomePaciente != null &&
                 iniciais != null &&
                 nif != null &&
                 data != null &&
                 hora != null &&
                 tipoConsulta != null &&
                 motivo != null),
         'ConsultaPage requires either appointmentId or full consultation data',
       );

  @override
  State<ConsultaPage> createState() => _ConsultaPageState();
}

class _ConsultaPageState extends State<ConsultaPage> {
  bool _loading = false;
  bool _saving = false;
  String? _error;

  String? _nomePaciente;
  String? _iniciais;
  String? _nif;
  String? _data;
  String? _hora;
  TipoConsulta? _tipoConsulta;
  String? _motivo;
  String? _notas;
  String? _patientId; // para navegar para PatientData

  // Controller para edição de notas/diagnóstico inline
  late final TextEditingController _notasCtrl;
  bool _editandoNotas = false;

  @override
  void initState() {
    super.initState();
    _notasCtrl = TextEditingController();
    if (widget.appointmentId != null) {
      _loadAppointment(widget.appointmentId!);
    } else {
      _populateFromWidget();
    }
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  void _populateFromWidget() {
    _nomePaciente = widget.nomePaciente;
    _iniciais = widget.iniciais;
    _nif = widget.nif;
    _data = widget.data;
    _hora = widget.hora;
    _tipoConsulta = widget.tipoConsulta;
    _motivo = widget.motivo;
    _notas = widget.notas;
    _notasCtrl.text = widget.notas ?? '';
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  TipoConsulta _mapTipo(String? type) {
    switch (type) {
      case 'urgent':
        return TipoConsulta.urgente;
      case 'follow_up':
        return TipoConsulta.analise;
      default:
        return TipoConsulta.normal;
    }
  }

  Future<void> _loadAppointment(String appointmentId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final row = await db
          .from('appointments')
          .select('''
            scheduled_date,
            scheduled_time,
            type,
            patient_notes,
            diagnosis_notes,
            patients!inner(
              user_id,
              users!inner(name, nif)
            )
          ''')
          .eq('id', appointmentId)
          .isFilter('deleted_at', null)
          .single();

      final patient = row['patients'];
      final userInfo = patient['users'];
      final name = userInfo['name'] as String? ?? 'Paciente Desconhecido';
      final nif = userInfo['nif'] as String? ?? '---';
      final date = row['scheduled_date'] as String? ?? '';
      final time = row['scheduled_time'] as String? ?? '';
      final type = row['type'] as String? ?? 'normal';
      final motive = row['patient_notes'] as String? ?? 'Consulta agendada';
      final notes = row['diagnosis_notes'] as String? ?? '';

      if (!mounted) return;
      setState(() {
        _nomePaciente = name;
        _iniciais = _initials(name);
        _nif = nif;
        _data = date;
        _hora = time.length >= 5 ? time.substring(0, 5) : time;
        _tipoConsulta = _mapTipo(type);
        _motivo = motive;
        _notas = notes;
        _patientId = patient['user_id'] as String?;
        _notasCtrl.text = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Guardar notas/diagnóstico 
  Future<void> _guardarNotas() async {
    if (widget.appointmentId == null) return;
    setState(() => _saving = true);
    try {
      await db
          .from('appointments')
          .update({'diagnosis_notes': _notasCtrl.text})
          .eq('id', widget.appointmentId!);
      if (!mounted) return;
      setState(() {
        _notas = _notasCtrl.text;
        _editandoNotas = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notas guardadas com sucesso.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Color(0xFFD4537E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao guardar notas: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: const Color(0xFFCC3A44),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Marcar como Realizada
  Future<void> _marcarRealizada() async {
    if (widget.appointmentId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Marcar esta consulta como realizada?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFD4537E)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFD4537E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      // Guardar notas pendentes e atualizar status
      await db
          .from('appointments')
          .update({
            'status': 'completed',
            if (_notasCtrl.text.isNotEmpty) 'diagnosis_notes': _notasCtrl.text,
          })
          .eq('id', widget.appointmentId!);

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Consulta marcada como realizada.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Color(0xFFD4537E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // sinaliza atualização ao ecrã anterior
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: const Color(0xFFCC3A44),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Cancelar Consulta 
  Future<void> _cancelarConsulta() async {
    if (widget.appointmentId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar Consulta',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Tem a certeza que pretende cancelar esta consulta? Esta ação não pode ser desfeita.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Não',
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFD4537E)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancelar consulta',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFCC3A44),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await db
          .from('appointments')
          .update({'status': 'canceled'})
          .eq('id', widget.appointmentId!);

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Consulta cancelada.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Color(0xFFCC3A44),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: const Color(0xFFCC3A44),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appointmentId != null && _loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: Color(0xFFD4537E)),
        ),
      );
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: () {
          if (widget.appointmentId != null) {
            _loadAppointment(widget.appointmentId!);
          }
        },
      );
    }

    final nomePaciente = _nomePaciente ?? widget.nomePaciente ?? 'Paciente';
    final iniciais = _iniciais ?? widget.iniciais ?? _initials(nomePaciente);
    final nif = _nif ?? widget.nif ?? '---';
    final data = _data ?? widget.data ?? '';
    final hora = _hora ?? widget.hora ?? '';
    final tipoConsulta =
        _tipoConsulta ?? widget.tipoConsulta ?? TipoConsulta.normal;
    final motivo = _motivo ?? widget.motivo ?? 'Consulta agendada';

    return TemplatePortalAdmin(
      currentIndex: 2,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voltar atrás
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  '< Voltar atrás',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4537E),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFD4537E),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Título
              const Text(
                'Consulta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              // Card Paciente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8F2EF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        iniciais,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A6B62),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nome + NIF
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomePaciente,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NIF: $nif',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6A9890),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ver ficha - navega para PatientData se tivermos patientId
                    GestureDetector(
                      onTap: () {
                        final patientId = _patientId;
                        if (patientId == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(userId: patientId),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Ver ficha ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD4537E),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFD4537E),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextSpan(
                              text: '→',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4537E),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFD4537E),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card Detalhes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Column(
                  children: [
                    // Data
                    _DetalheRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Data',
                      child: Text(
                        '$data • $hora',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.black.withValues(alpha: 0.10),
                      height: 1,
                    ),
                    // Tipo
                    _DetalheRow(
                      icon: Icons.phone_outlined,
                      label: 'Tipo',
                      child: _TipoChip(tipo: tipoConsulta),
                    ),
                    Divider(
                      color: Colors.black.withValues(alpha: 0.10),
                      height: 1,
                    ),
                    // Motivo
                    _DetalheRow(
                      icon: Icons.edit_outlined,
                      label: 'Motivo',
                      child: Text(
                        motivo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Notas / Diagnóstico - header com botão editar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NOTAS / DIAGNÓSTICO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB9124A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (widget.appointmentId != null)
                    GestureDetector(
                      onTap: () {
                        if (_editandoNotas) {
                          _guardarNotas();
                        } else {
                          setState(() => _editandoNotas = true);
                        }
                      },
                      child: Text(
                        _editandoNotas ? 'Guardar' : 'Editar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4537E),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFD4537E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEFAF8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9FDFD7), width: 2),
                ),
                child: _editandoNotas
                    ? TextField(
                        controller: _notasCtrl,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.54,
                          fontFamily: 'Poppins',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Escrever notas / diagnóstico...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA8A8A8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : Text(
                        (_notas != null && _notas!.isNotEmpty)
                            ? _notas!
                            : 'Sem notas...',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA8A8A8),
                          height: 1.54,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Botão: Marcar como Realizada
              _ActionButton(
                label: 'Marcar como Realizada',
                icon: Icons.check_box_outlined,
                backgroundColor: const Color(0xFFD4537E),
                foregroundColor: Colors.white,
                borderColor: null,
                onTap: _marcarRealizada,
              ),

              const SizedBox(height: 10),

              // Botão: Cancelar Consulta
              _ActionButton(
                label: 'Cancelar Consulta',
                icon: Icons.cancel_outlined,
                backgroundColor: const Color(0xFFFFF0F0),
                foregroundColor: const Color(0xFFCC3A44),
                borderColor: const Color(0xFFFAD2D6),
                onTap: _cancelarConsulta,
              ),

              const SizedBox(height: 10),
            ],
          ),

          // Overlay de loading durante save
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.70),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: Color(0xFFD4537E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE65100), size: 40),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar consulta:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4537E),
              ),
              child: const Text(
                'Tentar novamente',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widgets auxiliares

class _DetalheRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DetalheRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB9124A)),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB9124A),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  final TipoConsulta tipo;

  const _TipoChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (tipo) {
      TipoConsulta.urgente => (
        'Urgente',
        const Color(0xFFFFF2D5),
        const Color(0xFF8B5000),
      ),
      TipoConsulta.normal => (
        'Normal',
        const Color(0xFFD8F2EF),
        const Color(0xFF1A6B62),
      ),
      TipoConsulta.bloqueado => (
        'Bloqueado',
        const Color(0xFFF0F0F0),
        const Color(0xFF6A6A6A),
      ),
      TipoConsulta.analise => (
        'Análise',
        const Color(0xFFD5E6FF),
        const Color(0xFF1A3B8B),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 28,
            offset: Offset(0, 2.8),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 33,
              offset: Offset(0, 3),
              spreadRadius: -17,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
