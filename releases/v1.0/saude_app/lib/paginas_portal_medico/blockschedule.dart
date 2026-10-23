import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';

class BlockSchedule extends StatefulWidget {
  const BlockSchedule({super.key});

  @override
  State<BlockSchedule> createState() => _BlockScheduleState();
}

class _BlockScheduleState extends State<BlockSchedule> {
  bool _apenasEsteDia = true;

  // valores mock — substituir por DatePicker / TimePicker reais
  final String _dataInicio  = '29/03/2025';
  final String _dataFim     = '30/03/2025';
  final String _horaInicio  = '17:00';
  final String _horaFim     = '20:00';
  final String _motivo      = 'Formação médica';

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

          const SizedBox(height: 14),

          // ── Título ────────────────────────────────────────────────────────
          const Text(
            'Bloquear Horário',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 24),

          // ── Campos ───────────────────────────────────────────────────────
          _CampoData(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF3DBDAD),
            texto: 'Data de início: $_dataInicio',
            onTap: () {/* TODO: DatePicker */},
          ),
          _CampoData(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFFE65100),
            texto: 'Data de fim: $_dataFim',
            onTap: () {/* TODO: DatePicker */},
          ),

          // ── Toggle "Apenas este dia" ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GestureDetector(
              onTap: () => setState(() => _apenasEsteDia = !_apenasEsteDia),
              child: Row(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: _apenasEsteDia
                          ? const Color(0xFF3DBDAD)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3DBDAD),
                        width: 2,
                      ),
                    ),
                    child: _apenasEsteDia
                        ? const Icon(Icons.check,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Apenas este dia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),

          _CampoData(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF3DBDAD),
            texto: 'Hora início: $_horaInicio',
            onTap: () {/* TODO: TimePicker */},
          ),
          _CampoData(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFFE65100),
            texto: 'Hora fim: $_horaFim',
            onTap: () {/* TODO: TimePicker */},
          ),
          _CampoData(
            icon: Icons.edit_document,
            iconColor: const Color(0xFF3DBDAD),
            texto: 'Motivo: $_motivo',
            onTap: () {/* TODO: editar motivo */},
          ),

          const SizedBox(height: 24),

          // ── Pré-visualização ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFC5EDE8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF9FDFD7),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÉ-VISUALIZAÇÃO',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFFA8A8A8),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sex, 28 Mar • $_horaInicio-$_horaFim • $_motivo',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA8A8A8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const Icon(Icons.lock_outline,
                          size: 18, color: Color(0xFFA8A8A8)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Confirmar ─────────────────────────────────────────────────────
          GestureDetector(
            onTap: () {/* TODO: confirmar bloqueio */},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3DBDAD),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 20,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Confirmar Bloqueio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Cancelar ──────────────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
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

class _CampoData extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String texto;
  final VoidCallback onTap;

  const _CampoData({
    required this.icon,
    required this.iconColor,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 16),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withValues(alpha: 0.26),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: const Color(0xFF3DBDAD).withValues(alpha: 0.40),
            height: 1,
          ),
        ],
      ),
    );
  }
}