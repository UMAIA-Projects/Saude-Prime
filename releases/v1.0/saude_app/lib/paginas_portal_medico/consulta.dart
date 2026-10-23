import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';
import 'package:saude_app/paginas_portal_medico/senddocument.dart';

enum TipoConsulta { normal, urgente, bloqueado }

class Consulta extends StatelessWidget {
  final String nomePaciente;
  final String iniciais;
  final String nif;
  final String data;
  final String hora;
  final TipoConsulta tipoConsulta;
  final String motivo;
  final String? notas;

  const Consulta({
    super.key,
    required this.nomePaciente,
    required this.iniciais,
    required this.nif,
    required this.data,
    required this.hora,
    required this.tipoConsulta,
    required this.motivo,
    this.notas,
  });

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 1,
      onNavTap: (index) {
        if (index == 0) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const DashboardMedico()), (r) => false);}
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

          // ── Voltar atrás ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF50C4A5),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF50C4A5),
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Título ────────────────────────────────────────────────────────
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

          // ── Card Paciente ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                // Ver ficha
                GestureDetector(
                  onTap: () {/* TODO: ver ficha */},
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Ver ficha ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF50C4A5),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF50C4A5),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextSpan(
                          text: '→',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF50C4A5),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF50C4A5),
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

          // ── Card Detalhes ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                Divider(color: Colors.black.withValues(alpha: 0.10), height: 1),
                // Tipo
                _DetalheRow(
                  icon: Icons.phone_outlined,
                  label: 'Tipo',
                  child: _TipoChip(tipo: tipoConsulta),
                ),
                Divider(color: Colors.black.withValues(alpha: 0.10), height: 1),
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

          // ── Notas / Diagnóstico ───────────────────────────────────────────
          const Text(
            'NOTAS / DIAGNÓSTICO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A8070),
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEFAF8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF9FDFD7),
                width: 2,
              ),
            ),
            child: Text(
              notas ?? 'Sem notas...',
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

          // ── Botão: Marcar como Realizada ──────────────────────────────────
          _ActionButton(
            label: 'Marcar como Realizada',
            icon: Icons.check_box_outlined,
            backgroundColor: const Color(0xFF3DBDAD),
            foregroundColor: Colors.white,
            borderColor: null,
            onTap: () {/* TODO */},
          ),

          const SizedBox(height: 10),

          // ── Botão: Adicionar Documento ────────────────────────────────────
          _ActionButton(
            label: 'Adicionar Documento',
            icon: Icons.upload_file_outlined,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF66D1D8),
            borderColor: const Color(0xFF66D1D8),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SendDocument(
                nomePaciente: nomePaciente,
                iniciais: iniciais,
              ))),
          ),

          const SizedBox(height: 10),

          // ── Botão: Cancelar Consulta ──────────────────────────────────────
          _ActionButton(
            label: 'Cancelar Consulta',
            icon: Icons.cancel_outlined,
            backgroundColor: const Color(0xFFFFF0F0),
            foregroundColor: const Color(0xFFCC3A44),
            borderColor: const Color(0xFFFAD2D6),
            onTap: () {/* TODO */},
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

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
          Icon(icon, size: 18, color: const Color(0xFF1A8070)),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A8070),
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
      TipoConsulta.urgente   => ('Urgente',   const Color(0xFFFFF2D5), const Color(0xFF8B5000)),
      TipoConsulta.normal    => ('Normal',    const Color(0xFFD8F2EF), const Color(0xFF1A6B62)),
      TipoConsulta.bloqueado => ('Bloqueado', const Color(0xFFF0F0F0), const Color(0xFF6A6A6A)),
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