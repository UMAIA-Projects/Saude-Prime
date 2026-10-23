import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

enum _EntradaTipo { consulta, urgencia, acompanhamento }

class _EntradaHistorico {
  final DateTime data;
  final _EntradaTipo tipo;
  final String tipoLabel;   // label visível ao utilizador
  final String detalhe1;    // linha principal de detalhe
  final String detalhe2;    // linha secundária
  final String? recordId;   // UUID da consulta ou documento

  const _EntradaHistorico({
    required this.data,
    required this.tipo,
    required this.tipoLabel,
    required this.detalhe1,
    required this.detalhe2,
    this.recordId,
  });

  String get dataTexto {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${data.day} ${months[data.month - 1]} ${data.year}';
  }
}

// SUPABASE SERVICE

class _HistoricoService {
  static final _sb = Supabase.instance.client;
  static String get _userId => _sb.auth.currentUser!.id;

  /// Consultas concluídas (status = 'completed') do paciente
  static Future<List<_EntradaHistorico>> fetchHistorico() async {
    final rows = await _sb
        .from('appointments')
        .select('''
          id,
          scheduled_date,
          type,
          diagnosis_notes,
          doctors!inner(
            users!inner(name),
            specialties!inner(name)
          )
        ''')
        .eq('patient_id', _userId)
        .eq('status', 'completed')
        .order('scheduled_date', ascending: false);

    return rows.map((r) {
      final date        = DateTime.parse(r['scheduled_date'] as String);
      final doctorName  = r['doctors']['users']['name'] as String;
      final specialty   = r['doctors']['specialties']['name'] as String;
      final diagNotes   = r['diagnosis_notes'] as String? ?? '';
      final apptType    = r['type'] as String;

      _EntradaTipo tipo;
      String tipoLabel;
      switch (apptType) {
        case 'urgent':
          tipo = _EntradaTipo.urgencia;
          tipoLabel = 'Urgência';
          break;
        case 'follow_up':
          tipo = _EntradaTipo.acompanhamento;
          tipoLabel = 'Acompanhamento';
          break;
        default:
          tipo = _EntradaTipo.consulta;
          tipoLabel = 'Consulta';
      }

      return _EntradaHistorico(
        data:      date,
        tipo:      tipo,
        tipoLabel: tipoLabel,
        detalhe1:  '$doctorName — $specialty',
        detalhe2:  diagNotes.isNotEmpty ? diagNotes : 'Sem notas de diagnóstico',
        recordId:  r['id'] as String,
      );
    }).toList();
  }

}

// WIDGET PRINCIPAL

class ClinicHistoryScreen extends StatefulWidget {
  const ClinicHistoryScreen({super.key});

  @override
  State<ClinicHistoryScreen> createState() => _ClinicHistoryScreenState();
}

class _ClinicHistoryScreenState extends State<ClinicHistoryScreen> {
  static const Color _verde      = Color(0xFF1A8070);
  static const Color _verdeClaro = Color(0xFF80CBC4);
  static const Color _azul       = Color(0xFF1A3A6B);

  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _tipoSelecionado = 'Todos';

  // Alinhado com appointment_type enum da BD: normal | urgent | follow_up
  final List<String> _tipos = [
    'Todos',
    'Consulta',       // appointment_type = 'normal'
    'Urgência',       // appointment_type = 'urgent'
    'Acompanhamento', // appointment_type = 'follow_up'
  ];

  late Future<List<_EntradaHistorico>> _futureHistorico;

  @override
  void initState() {
    super.initState();
    _futureHistorico = _HistoricoService.fetchHistorico();
  }

  List<_EntradaHistorico> _aplicarFiltros(List<_EntradaHistorico> todos) {
    // _dataFim alargado até ao fim do dia selecionado (23:59:59)
    // para incluir entradas com hora (ex: análises com created_at)
    final fimDoDia = _dataFim != null
        ? DateTime(_dataFim!.year, _dataFim!.month, _dataFim!.day, 23, 59, 59)
        : null;

    return todos.where((item) {
      final tipoOk =
          _tipoSelecionado == 'Todos' || item.tipoLabel == _tipoSelecionado;
      final dataInicioOk =
          _dataInicio == null || !item.data.isBefore(_dataInicio!);
      final dataFimOk =
          fimDoDia == null || !item.data.isAfter(fimDoDia);
      return tipoOk && dataInicioOk && dataFimOk;
    }).toList();
  }

  String get _periodoLabel {
    if (_dataInicio == null && _dataFim == null) return 'Tudo';
    final ini = _dataInicio != null
        ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
        : '?';
    final fim = _dataFim != null
        ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
        : '?';
    return '$ini - $fim';
  }

  Color _corCirculo(_EntradaTipo tipo) =>
      tipo == _EntradaTipo.urgencia ? _azul : _verde;

  Color _corTipoLabel(_EntradaTipo tipo) =>
      tipo == _EntradaTipo.urgencia ? _azul : _verde;

  Future<void> _abrirPeriodoPicker() async {
    List<DateTime?> _selectedRange = [_dataInicio, _dataFim];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final temInicio = _selectedRange[0] != null;
            final temFim    = _selectedRange[1] != null;

            String instrucao;
            if (!temInicio) {
              instrucao = 'Toque no dia de início';
            } else if (!temFim) {
              instrucao = 'Agora toque no dia de fim';
            } else {
              final i = _selectedRange[0]!;
              final f = _selectedRange[1]!;
              instrucao =
                  '${i.day}/${i.month}/${i.year}  →  ${f.day}/${f.month}/${f.year}';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2DFDB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecionar Período',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instrucao,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: temInicio && temFim
                          ? _verde
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.range,
                      selectedDayHighlightColor: _verde,
                      selectedRangeHighlightColor:
                          _verdeClaro.withValues(alpha: 0.3),
                      weekdayLabels: const [
                        'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'
                      ],
                      firstDayOfWeek: 1,
                      controlsTextStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A8070),
                      ),
                      dayTextStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                    value: [_selectedRange[0], _selectedRange[1]],
                    onValueChanged: (dates) {
                      setModal(() {
                        if (dates.isEmpty) {
                          _selectedRange = [null, null];
                        } else if (dates.length == 1) {
                          _selectedRange = [dates[0], null];
                        } else {
                          _selectedRange = [dates[0], dates[1]];
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _dataInicio = null;
                              _dataFim    = null;
                            });
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A8070)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A8070),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF9E9E9E)),
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
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: temInicio && temFim
                              ? () {
                                  setState(() {
                                    _dataInicio = _selectedRange[0];
                                    _dataFim    = _selectedRange[1];
                                  });
                                  Navigator.pop(ctx);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A8070),
                            disabledBackgroundColor:
                                const Color(0xFF1A8070).withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Aplicar',
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
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _abrirTipoPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB2DFDB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TIPO DE CONSULTA',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A8070),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Consulta · Urgência · Acompanhamento',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView(
                      controller: scrollController,
                      shrinkWrap: true,
                      children: _tipos.map((tipo) {
                        final selecionado = tipo == _tipoSelecionado;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _tipoSelecionado = tipo);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: selecionado
                                  ? const Color(0xFF1A8070)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tipo,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selecionado
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 0,
      child: FutureBuilder<List<_EntradaHistorico>>(
        future: _futureHistorico,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voltar atrás
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPaciente()),
                ),
                child: const Text(
                  '< Voltar atrás',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A8070),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Título
              const Text(
                'Histórico Clínico',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              // Filtros
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _abrirPeriodoPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF1A8070), width: 1.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 16, color: Color(0xFF1A8070)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Período: $_periodoLabel',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF555555),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _abrirTipoPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF1A8070), width: 1.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sell_outlined,
                                size: 16, color: Color(0xFF1A8070)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tipo: $_tipoSelecionado',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF555555),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A8070),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Color(0xFF9E9E9E), size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Erro ao carregar histórico.\nVerifica a tua ligação.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() {
                            _futureHistorico =
                                _HistoricoService.fetchHistorico();
                          }),
                          child: const Text(
                            'Tentar novamente',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF1A8070),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _TimelineHistorico(
                  entradas: _aplicarFiltros(snapshot.data!),
                  corCirculo: _corCirculo,
                  corTipoLabel: _corTipoLabel,
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// TIMELINE

class _TimelineHistorico extends StatelessWidget {
  final List<_EntradaHistorico> entradas;
  final Color Function(_EntradaTipo) corCirculo;
  final Color Function(_EntradaTipo) corTipoLabel;

  const _TimelineHistorico({
    required this.entradas,
    required this.corCirculo,
    required this.corTipoLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (entradas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Sem registos para os filtros selecionados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entradas.length,
      itemBuilder: (context, i) {
        final item   = entradas[i];
        final isLast = i == entradas.length - 1;
        final cor      = corCirculo(item.tipo);
        final corLabel = corTipoLabel(item.tipo);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha da timeline
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFB2DFDB),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Data + tipo
                      Row(
                        children: [
                          Text(
                            item.dataTexto,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            item.tipoLabel,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: corLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.detalhe1,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF555555),
                        ),
                      ),
                      Text(
                        item.detalhe2,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ver detalhes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A8070),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF1A8070),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
