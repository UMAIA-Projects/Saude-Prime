import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'template/template_portal_recepcao.dart';

class Paciente {
  final String id;
  final String nome;
  final String nif;
  final String iniciais;
  final Color cor;
  final String ultimaConsulta;

  Paciente({
    required this.id,
    required this.nome,
    required this.nif,
    required this.iniciais,
    required this.cor,
    required this.ultimaConsulta,
  });
}

class GestaoPacientesPage extends StatefulWidget {
  const GestaoPacientesPage({super.key});

  @override
  State<GestaoPacientesPage> createState() => _GestaoPacientesPageState();
}

class _GestaoPacientesPageState extends State<GestaoPacientesPage> {
  static const Color _azulBotao = Color(0xFF3B6BE0);

  // Lista (Depois substituir com dados reais da DB)
  final List<Paciente> _todosOsPacientes = [
    Paciente(
      id: '1',
      nome: 'Aníbal Carvalho Oliveira',
      nif: '222 222 222',
      iniciais: 'AO',
      cor: const Color(0xFF3B6BE0),
      ultimaConsulta: '15 Mar',
    ),
    Paciente(
      id: '2',
      nome: 'Mariana Costa Oliveira',
      nif: '333 333 333',
      iniciais: 'MC',
      cor: const Color(0xFF27AE60),
      ultimaConsulta: '15 Mar',
    ),
    Paciente(
      id: '3',
      nome: 'Rui Lima',
      nif: '187 444 444',
      iniciais: 'RL',
      cor: const Color(0xFFE0A020),
      ultimaConsulta: '28 Fev',
    ),
  ];

  List<Paciente> _pacientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _pacientesFiltrados = _todosOsPacientes;
  }

  void _filtrarPacientes(String query) {
    setState(() {
      _pacientesFiltrados = _todosOsPacientes
          .where(
            (p) =>
                p.nome.toLowerCase().contains(query.toLowerCase()) ||
                p.nif.contains(query),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 1,
      userInitials: 'MC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          TextField(
            onChanged: _filtrarPacientes,
            decoration: InputDecoration(
              hintText: 'Pesquisar por nome ou NIF...',
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black38,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  'assets/imagens_portal_recepcao/Search.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    _azulBotao,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _azulBotao, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _azulBotao, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 25),
          ..._pacientesFiltrados.map(
            (paciente) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPacienteCard(paciente),
            ),
          ),
          if (_pacientesFiltrados.isEmpty)
            const Center(
              child: Text(
                "Nenhum paciente encontrado.",
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pacientes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: SvgPicture.asset(
            'assets/imagens_portal_recepcao/Plus.svg',
            width: 14,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          label: const Text("Novo"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _azulBotao,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    final String cleanNif = paciente.nif.replaceAll(' ', '');
    final String maskedNif = cleanNif.length >= 3
        ? "${cleanNif.substring(0, 3)}-***-***"
        : cleanNif;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: paciente.cor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              paciente.iniciais,
              style: TextStyle(
                color: paciente.cor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente.nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF1A3B8B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIF: $maskedNif . Últ: ${paciente.ultimaConsulta}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7FA39F),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {},
                /*{
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerPacientePage(id: paciente.id),
                    ),
                  );
                },*/
                child: const Text(
                  'Ver',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: _azulBotao,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                /*{
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditarPacientePage(id: paciente.id),
                    ),
                  );
                },*/
                child: SvgPicture.asset(
                  'assets/imagens_portal_recepcao/Edit.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    _azulBotao,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
