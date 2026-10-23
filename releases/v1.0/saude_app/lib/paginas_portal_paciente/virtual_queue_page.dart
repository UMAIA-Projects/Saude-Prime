import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_paciente/dashboard_page.dart';
import 'template/template_portal_paciente.dart';

class VirtualQueueScreen extends StatelessWidget {
  const VirtualQueueScreen({super.key});

  void _mostrarConfirmacaoAbandonar(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Abandonar Fila',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'Tem a certeza que deseja abandonar a fila?\nA sua senha A-67 será cancelada.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF555555),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              // Cancelar
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A8070)),
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
                      color: Color(0xFF1A8070),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sim, abandonar
              Expanded(
                child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardPage()));
                },             
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A8070),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sim',
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 2, // ticket/fila
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Fila Virtual',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),

          // Label "A TUA SENHA"
          const Text(
            'A TUA SENHA',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A8070),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Card da senha
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Número da senha
                const Text(
                  'A-67',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A8070),
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 12),
                // Info abaixo
                const Text(
                  'A ser atendido: A-60',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1A8070),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '~12 min',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      '7 à frente',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card de estatísticas da fila
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _FilaInfoRow(
                  svgIcon: Icons.bar_chart_rounded,
                  label: 'Total Fila',
                  valor: '12 pessoas',
                  mostrarDivisor: true,
                ),
                _FilaInfoRow(
                  svgIcon: Icons.timer_outlined,
                  label: 'Média',
                  valor: '4 min / pessoa',
                  mostrarDivisor: true,
                ),
                _FilaInfoRow(
                  svgIcon: Icons.access_time_rounded,
                  label: 'Aberta',
                  valor: 'desde 09:00',
                  mostrarDivisor: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Botão Abandonar Fila
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _mostrarConfirmacaoAbandonar(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF0F0),
                side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Abandonar Fila',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FilaInfoRow extends StatelessWidget {
  final IconData svgIcon;
  final String label;
  final String valor;
  final bool mostrarDivisor;

  const _FilaInfoRow({
    required this.svgIcon,
    required this.label,
    required this.valor,
    required this.mostrarDivisor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(svgIcon, size: 20, color: const Color(0xFF1A8070)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                valor,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
        if (mostrarDivisor)
          const Divider(height: 1, color: Color(0xFFB2DFDB)),
      ],
    );
  }
}