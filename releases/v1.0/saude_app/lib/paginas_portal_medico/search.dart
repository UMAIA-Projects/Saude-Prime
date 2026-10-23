import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';
import 'package:saude_app/paginas_portal_medico/patientdata.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  // Lista mock de pacientes
  static const List<Map<String, dynamic>> _pacientes = [
    {
      'nome': 'Aníbal Oliveira',
      'iniciais': 'AO',
      'nif': '222-***-***',
      'dataNasc': '01/01/1990',
      'telefone': '+351 912 345 678',
      'ultimaConsulta': '15 Mar de 2025',
      'avatarColor': Color(0xFFD8F2EF),
      'iniciaisColor': Color(0xFF1A6B62),
      'ativo': true,
    },
    {
      'nome': 'Aníbal Sousa',
      'iniciais': 'AS',
      'nif': '312-***-***',
      'dataNasc': '15/06/1978',
      'telefone': '+351 933 210 987',
      'ultimaConsulta': '2 Fev de 2024',
      'avatarColor': Color(0xFF185FA5),
      'iniciaisColor': Colors.white,
      'ativo': true,
    },
    {
      'nome': 'Aníbal Lima',
      'iniciais': 'AL',
      'nif': '187-***-***',
      'dataNasc': '22/11/1985',
      'telefone': '+351 964 111 222',
      'ultimaConsulta': null,
      'avatarColor': Color(0xFFAEBDBB),
      'iniciaisColor': Colors.white,
      'ativo': false,
    },
    {
      'nome': 'João Ferreira',
      'iniciais': 'JF',
      'nif': '100-***-***',
      'dataNasc': '10/03/1985',
      'telefone': '+351 926 543 210',
      'ultimaConsulta': '10 Abr de 2025',
      'avatarColor': Color(0xFFD8F2EF),
      'iniciaisColor': Color(0xFF1A6B62),
      'ativo': true,
    },
    {
      'nome': 'Ana Costa',
      'iniciais': 'AC',
      'nif': '200-***-***',
      'dataNasc': '22/07/1992',
      'telefone': '+351 917 888 333',
      'ultimaConsulta': '5 Mar de 2025',
      'avatarColor': Color(0xFFD8F2EF),
      'iniciaisColor': Color(0xFF1A6B62),
      'ativo': true,
    },
  ];

  List<Map<String, dynamic>> get _resultados {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _pacientes.where((p) =>
      (p['nome'] as String).toLowerCase().contains(q) ||
      (p['nif'] as String).toLowerCase().contains(q)
    ).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _resultados;

    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 3,
      onNavTap: (index) {
        if (index == 0) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const DashboardMedico()), (r) => false);}
        if (index == 1) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Schedule()), (r) => false);}
        if (index == 2) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const VirtualQueue()), (r) => false);}
        if (index == 4) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Profile()), (r) => false);}
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Título ────────────────────────────────────────────────────────
          const Text(
            'Pesquisar Paciente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 16),

          // ── Caixa de pesquisa + resultados ────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF66D1D8), width: 1.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF66D1D8), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Pesquisar por nome ou NIF...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.black.withValues(alpha: 0.40),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() {
                            _query = '';
                            _controller.clear();
                          }),
                          child: const Icon(Icons.close, size: 18,
                            color: Color(0xFF66D1D8)),
                        ),
                    ],
                  ),
                ),

                // Resultados
                if (_query.isNotEmpty) ...[
                  Divider(
                    color: const Color(0xFF66D1D8).withValues(alpha: 0.40),
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Resultados para "$_query"',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.45),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  if (resultados.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Nenhum paciente encontrado.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.40),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      itemCount: resultados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = resultados[i];
                        return _PacienteCard(paciente: p);
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de paciente
// ─────────────────────────────────────────────────────────────────────────────

class _PacienteCard extends StatelessWidget {
  final Map<String, dynamic> paciente;

  const _PacienteCard({required this.paciente});

  @override
  Widget build(BuildContext context) {
    final bool ativo = paciente['ativo'] as bool;
    final double opacidade = ativo ? 1.0 : 0.50;

    return GestureDetector(
      onTap: ativo ? () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => PatientData(
          nomePaciente: paciente['nome'] as String,
          iniciais: paciente['iniciais'] as String,
          avatarColor: paciente['avatarColor'] as Color,
          iniciaisColor: paciente['iniciaisColor'] as Color,
          dataNasc: paciente['dataNasc'] as String,
          nif: paciente['nif'] as String,
          telefone: paciente['telefone'] as String,
        ))) : null,
      child: Opacity(
        opacity: opacidade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: ativo ? Colors.white : Colors.white.withValues(alpha: 0.50),
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
                decoration: BoxDecoration(
                  color: paciente['avatarColor'] as Color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  paciente['iniciais'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: paciente['iniciaisColor'] as Color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente['nome'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ativo ? Colors.black : Colors.black.withValues(alpha: 0.50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'NIF: ${paciente['nif']} '),
                          const TextSpan(text: '• '),
                          TextSpan(text: paciente['dataNasc'] as String),
                        ],
                        style: TextStyle(
                          fontSize: 11,
                          color: ativo
                              ? const Color(0xFF6A9890)
                              : const Color(0xFF6A9890).withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (paciente['ultimaConsulta'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Última consulta: ${paciente['ultimaConsulta']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ativo
                              ? const Color(0xFF6A9890)
                              : const Color(0xFF6A9890).withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron
              Text(
                '>',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ativo
                      ? const Color(0xFFDDD5CE)
                      : const Color(0xFFDDD5CE).withValues(alpha: 0.50),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}