import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'template/template_portal_recepcao.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage> {
  // Estado da Página: Controla qual aba está ativa, a data e o médico selecionados
  String _abaAtiva = 'Hoje';
  DateTime _dataSelecionada = DateTime.now();
  String? _medicoSelecionado;

  // Dados para o Dropdown organizado por especialidade (lista estática para simulação)
  final List<Map<String, dynamic>> _medicosPorEspecialidade = [
    {
      'especialidade': 'Clínica Geral',
      'medicos': ['Dr. Menezes', 'Dra. Silva'],
    },
    {
      'especialidade': 'Pediatria',
      'medicos': ['Dra. Mendes', 'Dr. Santos'],
    },
    {
      'especialidade': 'Cardiologia',
      'medicos': ['Dr. Ricardo'],
    },
  ];

  // Função para abrir o calendário nativo do Flutter
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
      setState(() {
        _dataSelecionada = colhido;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 2,
      userInitials: 'MC',
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
                onPressed: () {
                  /* TODO: novo agendamento */
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B9CE8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                        Colors.white,
                        BlendMode.srcIn,
                      ),
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
          if (_abaAtiva == 'Hoje') ...[
            _buildAgendamentoCard(
              hora: '14:30',
              titulo: 'Aníbal Oliveira · Dr. Menezes',
              isUrgente: true,
            ),
            _buildAgendamentoCard(
              hora: '15:00',
              titulo: 'Maria Costa · Dra. Mendes',
              isUrgente: false,
            ),
          ] else if (_abaAtiva == 'Semana') ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Agenda da semana...",
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Todos os registos...",
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
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
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3B6BE0)),
          hint: Row(
            children: [
              SvgPicture.asset(
                'assets/imagens_portal_recepcao/People.svg',
                width: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF3B6BE0),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Médico: Todos',
                style: TextStyle(fontSize: 13, color: Color(0xFF7A97A9)),
              ),
            ],
          ),
          items: _medicosPorEspecialidade.expand<DropdownMenuItem<String>>((
            esp,
          ) {
            final especialidade = esp['especialidade'] as String;
            final medicos = esp['medicos'] as List<String>;

            return [
              DropdownMenuItem<String>(
                enabled: false,
                value: 'header_$especialidade',
                child: Text(
                  especialidade,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
              ...medicos.map<DropdownMenuItem<String>>((medico) {
                return DropdownMenuItem<String>(
                  value: medico,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      medico,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ];
          }).toList(),
          onChanged: (novoValor) {
            setState(() {
              if (novoValor != null && !novoValor.startsWith('header_')) {
                _medicoSelecionado = novoValor;
              }
            });
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
                Color(0xFF3B6BE0),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A97A9),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = _abaAtiva == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _abaAtiva = label),
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
              color: isActive
                  ? const Color(0xFF6B9CE8)
                  : const Color(0xFF90A4AE),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard({
    required String hora,
    required String titulo,
    required bool isUrgente,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFDFEDFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: const Color(0xFF4A78D6)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hora,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A78D6),
                            fontFamily: 'Poppins',
                          ),
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
                    _buildAcoes(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(bool isUrgente) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgente ? const Color(0xFFFDF0D5) : const Color(0xFFCDE2F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isUrgente ? 'Urgente' : 'Normal',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isUrgente ? const Color(0xFFB8860B) : const Color(0xFF1A3B8B),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildAcoes() {
    return Row(
      children: [
        _buildBotaoAcao('Ver'),
        const SizedBox(width: 16),
        _buildBotaoAcao('Alterar'),
        const SizedBox(width: 16),
        _buildBotaoAcao('Cancelar', isRed: true),
      ],
    );
  }

  Widget _buildBotaoAcao(String label, {bool isRed = false}) {
    return GestureDetector(
      onTap: () {},
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
}
