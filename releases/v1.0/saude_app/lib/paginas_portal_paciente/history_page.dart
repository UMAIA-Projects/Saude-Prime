import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'template/template_portal_paciente.dart';
import 'dashboard_page.dart';

class ClinicHistoryScreen extends StatefulWidget {
  const ClinicHistoryScreen({super.key});

  @override
  State<ClinicHistoryScreen> createState() =>
      _ClinicHistoryScreenState();
}

class _ClinicHistoryScreenState extends State<ClinicHistoryScreen> {
  static const Color _verde = Color(0xFF1A8070);
  static const Color _verdeClaro = Color(0xFF80CBC4);
  static const Color _azul = Color(0xFF1A3A6B);

  // Filtros
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _tipoSelecionado = 'Todos';

  final List<String> _tipos = [
    'Todos',
    'Consulta Geral',
    'Análise',
    'Urgência',
    'Pediatria',
    'Acompanhamento',
  ];

  final List<Map<String, dynamic>> _historico = [
    {
      'data': DateTime(2025, 3, 15),
      'dataTexto': '15 Mar 2025',
      'tipo': 'Consulta Geral',
      'tipoLabel': 'Consulta',
      'detalhe1': 'Dr. Carlos Santos - Gripe',
      'detalhe2': 'Prescrição...',
    },
    {
      'data': DateTime(2025, 2, 2),
      'dataTexto': '2 Fev 2025',
      'tipo': 'Análise',
      'tipoLabel': 'Análise',
      'detalhe1': 'Lab. Central - Hemograma Completo',
      'detalhe2': 'Valores...',
    },
    {
      'data': DateTime(2025, 1, 10),
      'dataTexto': '10 Jan 2025',
      'tipo': 'Consulta Geral',
      'tipoLabel': 'Consulta',
      'detalhe1': 'Dra. Ana Mendes - Tensão 125/80',
      'detalhe2': 'Controlo...',
    },
  ];

  List<Map<String, dynamic>> get _historicoFiltrado {
    return _historico.where((item) {
      final data = item['data'] as DateTime;
      final tipoOk = _tipoSelecionado == 'Todos' ||
          item['tipo'] == _tipoSelecionado;
      final dataInicioOk =
          _dataInicio == null || !data.isBefore(_dataInicio!);
      final dataFimOk =
          _dataFim == null || !data.isAfter(_dataFim!);
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

  // ── Picker de período ──────────────────────────────────────────────────────
  Future<void> _abrirPeriodoPicker() async {
    // Lista local com exatamente 2 posições para o range
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
            final temFim = _selectedRange[1] != null;

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
                  // Handle
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
                  // Guia de estado visual
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
                    // CORRECÇÃO: passa sempre lista de 2 elementos
                    // O widget range precisa de [inicio, fim] para funcionar
                    value: [_selectedRange[0], _selectedRange[1]],
                    onValueChanged: (dates) {
                      setModal(() {
                        if (dates.isEmpty) {
                          _selectedRange = [null, null];
                        } else if (dates.length == 1) {
                          // Primeiro toque: só início seleccionado
                          _selectedRange = [dates[0], null];
                        } else {
                          // Segundo toque: início + fim seleccionados
                          _selectedRange = [dates[0], dates[1]];
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Tudo (reset)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _dataInicio = null;
                              _dataFim = null;
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
                      // Cancelar
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
                      // Aplicar — desativado até ambos os dias estarem escolhidos
                      Expanded(
                        child: ElevatedButton(
                          onPressed: temInicio && temFim
                              ? () {
                                  setState(() {
                                    _dataInicio = _selectedRange[0];
                                    _dataFim = _selectedRange[1];
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

  // ── Picker de tipo ─────────────────────────────────────────────────────────
  Future<void> _abrirTipoPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // CORRECÇÃO overflow: DraggableScrollableSheet + ListView
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
                  // Handle
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

  // ── Cor do círculo da timeline ─────────────────────────────────────────────
  Color _corCirculo(String tipo) {
    switch (tipo) {
      case 'Análise':
        return _azul;
      default:
        return _verde;
    }
  }

  Color _corTipoLabel(String tipo) {
    switch (tipo) {
      case 'Análise':
        return _azul;
      default:
        return _verde;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrado = _historicoFiltrado;

    return TemplatePortalPaciente(
      currentIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voltar atrás
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage()),
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

          // Filtros — Período e Tipo
          Row(
            children: [
              // Período
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

              // Tipo
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

          // Timeline
          if (filtrado.isEmpty)
            const Padding(
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
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtrado.length,
              itemBuilder: (context, i) {
                final item = filtrado[i];
                final isLast = i == filtrado.length - 1;
                final cor = _corCirculo(item['tipo'] as String);
                final corLabel = _corTipoLabel(item['tipo'] as String);

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
                          padding: EdgeInsets.only(
                              bottom: isLast ? 0 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item['dataTexto'] as String,
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
                                    item['tipoLabel'] as String,
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
                                item['detalhe1'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              Text(
                                item['detalhe2'] as String,
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
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}