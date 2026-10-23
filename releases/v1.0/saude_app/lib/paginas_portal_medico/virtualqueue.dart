import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';

class VirtualQueue extends StatelessWidget {
  const VirtualQueue({super.key});

  static const List<Map<String, String>> _emEspera = [
    {'pos': '2', 'ticket': 'A-44', 'nome': 'João Oliveira',  'hora': '10:02'},
    {'pos': '3', 'ticket': 'A-45', 'nome': 'Rui Figueiredo', 'hora': '10:15'},
    {'pos': '4', 'ticket': 'A-46', 'nome': 'Ana Lima',       'hora': '10:23'},
  ];

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 2,
      onNavTap: (index) {
              if (index == 0) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const DashboardMedico()), (r) => false);}
              if (index == 1) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Schedule()), (r) => false);}
              if (index == 3) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Search()), (r) => false);}
              if (index == 4) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Profile()), (r) => false);}
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Título ────────────────────────────────────────────────────────
          const Text(
            'Fila Virtual',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 18),

          // ── Card próxima a atender ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0x233DBDAD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x473DBDAD), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // label
                const Text(
                  'PRÓXIMA A ATENDER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A6B62),
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // número
                const Text(
                  'A-43',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A6B62),
                    fontFamily: 'Poppins',
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),

                // info paciente
                Text(
                  'Maria Santos • Chegou 09:47 • 23 min espera',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // botão chamar
                GestureDetector(
                  onTap: () {/* TODO: chamar paciente */},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DBDAD),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 20,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Chamar Paciente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // botão ausente
                GestureDetector(
                  onTap: () {/* TODO: marcar ausente */},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFFFCDD2),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 20,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Marcar como Ausente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC62828),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Em espera ─────────────────────────────────────────────────────
          const Text(
            'EM ESPERA (6)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A6B62),
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          ..._emEspera.map((p) => _FilaItem(
                posicao: p['pos']!,
                ticket: p['ticket']!,
                nome: p['nome']!,
                hora: p['hora']!,
              )),

          const SizedBox(height: 16),

          // ── Rodapé: atendidos + fechar fila ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Atendidos hoje: 8',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6A9890),
                  fontFamily: 'Poppins',
                ),
              ),
              GestureDetector(
                onTap: () {/* TODO: fechar fila */},
                child: const Text(
                  'Fechar fila',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget auxiliar — linha da fila
// ─────────────────────────────────────────────────────────────────────────────

class _FilaItem extends StatelessWidget {
  final String posicao;
  final String ticket;
  final String nome;
  final String hora;

  const _FilaItem({
    required this.posicao,
    required this.ticket,
    required this.nome,
    required this.hora,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              // posição
              SizedBox(
                width: 20,
                child: Text(
                  posicao,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.26),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // badge ticket
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBAE9E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ticket,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A6B62),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // nome
              Expanded(
                child: Text(
                  nome,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.70),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              // hora
              Text(
                hora,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.26),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 12),

              // ausente
              GestureDetector(
                onTap: () {/* TODO: marcar ausente */},
                child: const Text(
                  'Ausente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Colors.black.withValues(alpha: 0.10),
          height: 1,
        ),
      ],
    );
  }
}