import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';

class DashboardMedico extends StatelessWidget {
  const DashboardMedico({super.key});

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 0,
      onNavTap: (index) {
        if (index == 1) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Schedule()), (r) => false);}
        if (index == 2) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const VirtualQueue()), (r) => false);}
        if (index == 3) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Search()), (r) => false);}
        if (index == 4) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Profile()), (r) => false);}
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saudação ──────────────────────────────────────────────────────
          const Text(
            'Bom dia, Dr. Santos!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              fontFamily: 'Poppins',
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tens 8 consultas hoje',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6A9890),
              fontFamily: 'Poppins',
            ),
          ),
 
          const SizedBox(height: 22),
 
          // ── Próxima Consulta ──────────────────────────────────────────────
          _SectionLabel(label: 'PRÓXIMA CONSULTA'),
          const SizedBox(height: 10),
          _ProximaConsultaCard(),
 
          const SizedBox(height: 22),
 
          // ── Fila Virtual ──────────────────────────────────────────────────
          _SectionLabel(label: 'FILA  VIRTUAL'),
          const SizedBox(height: 10),
          _FilaVirtualCard(),
 
          const SizedBox(height: 22),
 
          // ── Agenda Hoje ───────────────────────────────────────────────────
          _SectionLabel(label: 'AGENDA HOJE'),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sexta, 28 Mar',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6A9890),
                  fontFamily: 'Poppins',
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Schedule())),
                child: const Text(
                  'Ver completa →',
                  style: TextStyle(
                    fontSize: 12,
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
 
          _ConsultaCard(
            hora: '09:00',
            nome: 'João Ferreira',
            tipo: 'Normal',
            isUrgent: false,
            isDone: true,
          ),
          const SizedBox(height: 10),
          _ConsultaCard(
            hora: '14:30',
            nome: 'Aníbal Oliveira',
            tipo: 'Urgente',
            isUrgent: true,
            isDone: false,
          ),
          const SizedBox(height: 10),
          _ConsultaCard(
            hora: '16:00',
            nome: 'Rui Lima',
            tipo: 'Normal',
            isUrgent: false,
            isDone: false,
          ),
 
          const SizedBox(height: 28),
 
          // ── Ações Rápidas ─────────────────────────────────────────────────
          _SectionLabel(label: 'AÇÕES RÁPIDAS'),
          const SizedBox(height: 12),
          _AcoesRapidasGrid(),
 
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────
 
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A8070),
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
    );
  }
}
 
// ── Próxima Consulta Card ─────────────────────────────────────────────────────
class _ProximaConsultaCard extends StatelessWidget {
  const _ProximaConsultaCard();
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x233DBDAD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFbce6e1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // hora + nome
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '14:30',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A8070),
                        fontFamily: 'Poppins',
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Aníbal Oliveira - NIF 222-***',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A9890),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // badge Normal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5EAFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Normal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A3B8B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // links
          Row(
            children: [
              GestureDetector(
                onTap: () {/* TODO: ver detalhes */},
                child: const Text(
                  'Ver detalhes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.check, size: 15, color: Color(0xFF50C4A5)),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: () {/* TODO: marcar como realizada */},
                child: const Text(
                  'Realizada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
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
 
// ── Fila Virtual Card ─────────────────────────────────────────────────────────
class _FilaVirtualCard extends StatelessWidget {
  const _FilaVirtualCard();
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // número da fila
          const Text(
            'A-43',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A8070),
              fontFamily: 'Poppins',
              height: 1,
            ),
          ),
          const SizedBox(width: 18),
          // detalhes
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Maria Santos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Em espera: 6 pessoas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          // botão Ir
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VirtualQueue())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4DB0A0),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Ir →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Consulta Card ─────────────────────────────────────────────────────────────
class _ConsultaCard extends StatelessWidget {
  final String hora;
  final String nome;
  final String tipo;
  final bool isUrgent;
  final bool isDone;
 
  const _ConsultaCard({
    required this.hora,
    required this.nome,
    required this.tipo,
    required this.isUrgent,
    required this.isDone,
  });
 
  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        isUrgent ? const Color(0xFFE65100) : const Color(0xFF3DBDAD);
    final Color textColor = isUrgent
        ? const Color(0xFFE65100)
        : Colors.black.withValues(alpha: 0.70);
 
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xE5DAFDF9),
        borderRadius: BorderRadius.circular(15),
        border: Border(
          left: BorderSide(color: accentColor, width: 5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // hora + nome/tipo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hora,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      nome,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      tipo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // check se realizada
          if (isDone)
            const Icon(Icons.check, size: 18, color: Color(0xFF3DBDAD)),
        ],
      ),
    );
  }
}
 
// ── Ações Rápidas Grid ────────────────────────────────────────────────────────
class _AcoesRapidasGrid extends StatelessWidget {
  const _AcoesRapidasGrid();
 
  static const List<_AcaoItem> _acoes = [
    _AcaoItem(label: 'Ver Agenda',       icon: Icons.calendar_today_outlined),
    _AcaoItem(label: 'Fila Virtual',     icon: Icons.confirmation_number_outlined),
    _AcaoItem(label: 'Pesquisar Paciente', icon: Icons.person_search_outlined),
    _AcaoItem(label: 'Bloquear Horário', icon: Icons.block_outlined),
  ];
 
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.3,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: _acoes.map((a) => _AcaoCard(item: a)).toList(),
    );
  }
}
 
class _AcaoItem {
  final String label;
  final IconData icon;
  const _AcaoItem({required this.label, required this.icon});
}
 
class _AcaoCard extends StatelessWidget {
  final _AcaoItem item;
  const _AcaoCard({required this.item});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const Schedule())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 26, color: const Color(0xFF3DBDAD)),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A8070),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
