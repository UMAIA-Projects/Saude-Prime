import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'template/template_portal_recepcao.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  static const Color _azulDestaque = Color(0xFF2D7BDA);
  static const Color _azulBotao = Color(0xFF6DA0E0);

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 0,
      userInitials: 'MC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olá, Mariana!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3B8B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Sexta, 28 Mar · 34 consultas hoje',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Fila de Hoje",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _azulDestaque,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(value: "89", label: "Emitidas"),
                    _StatItem(value: "6", label: "Em espera"),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(value: "43", label: "Chamadas"),
                    _StatItem(value: "40", label: "Atendidas"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  // Redirect para a página de gestão da fila
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _azulBotao,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Gerir Fila",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 35),
          const Text(
            "Próximas Consultas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _azulDestaque,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Column(
              children: [
                _AppointmentTile(
                  time: "10:00",
                  name: "Aníbal Oliveira",
                  doctor: "Dr. Antunes",
                  tag: "Urgente",
                  isUrgente: true,
                ),
                Divider(height: 1, indent: 20, endIndent: 20),
                _AppointmentTile(
                  time: "10:30",
                  name: "Maria Costa",
                  doctor: "Dr. Mendes",
                  tag: "Normal",
                  isUrgente: false,
                ),
                Divider(height: 1, indent: 20, endIndent: 20),
                _AppointmentTile(
                  time: "11:00",
                  name: "Rui Lima",
                  doctor: "Dr. Antunes",
                  tag: "Normal",
                  isUrgente: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),

          Row(
            children: [
              _buildAcaoRapida(
                'assets/imagens_portal_recepcao/People.svg',
                'Gerir\nPacientes',
                () {
                  // TODO: Navigator.push para Gestão de Pacientes
                },
              ),
              const SizedBox(width: 10),
              _buildAcaoRapida(
                'assets/imagens_portal_recepcao/Schedule.svg',
                'Agendamentos',
                () {
                  // TODO: Navigator.push para Agendamentos
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAcaoRapida(
                'assets/imagens_portal_recepcao/Ticket.svg',
                'Emitir\nSenha',
                () {
                  // TODO: Navigator.push para Emitir Senha
                },
              ),
              const SizedBox(width: 10),
              _buildAcaoRapida(
                'assets/imagens_portal_recepcao/Plus.svg',
                'Novo\nPaciente',
                () {
                  // TODO: Navigator.push para Novo Paciente
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAcaoRapida(String svgAsset, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF3B6BE0),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A3B8B),
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A8070),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A8070)),
        ),
      ],
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final String time;
  final String name;
  final String doctor;
  final String tag;
  final bool isUrgente;

  const _AppointmentTile({
    required this.time,
    required this.name,
    required this.doctor,
    required this.tag,
    required this.isUrgente,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D7BDA),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  doctor,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgente
                  ? const Color(0xFFFDEFD3)
                  : const Color(0xFFE1F0FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: isUrgente
                    ? const Color(0xFFE5A000)
                    : const Color(0xFF2D7BDA),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
