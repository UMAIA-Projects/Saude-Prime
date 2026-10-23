import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
 
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}
 
class _NotificationScreenState extends State<NotificationScreen> {
  // 0 = todas as notificações, 1 = notificações não lidas
  int _tabIndex = 0;
 
  final List<Map<String, dynamic>> _notifications = [
    {
      'titulo': 'Consulta amanhã às 14:30 confirmada.',
      'tempo': 'Há 2 horas',
      'lida': false,
    },
    {
      'titulo': 'Novo resultado de análise disponível.',
      'tempo': 'Há 1 dia',
      'lida': false,
    },
    {
      'titulo': 'Consulta 15 Mar marcada como realizada.',
      'tempo': 'Hoje',
      'lida': false,
    },
  ];
 
  void _marcarTodasComoLidas() {
    setState(() {
      for (final n in _notifications) {
        n['lida'] = true;
      }
    });
  }
 
  void _marcarComoLida(int index) {
    setState(() {
      _notifications[index]['lida'] = true;
    });
  }
 
  List<Map<String, dynamic>> get _filterednotifications {
    if (_tabIndex == 1) { //não lidas
      return _notifications.asMap().entries
          .where((e) => e.value['lida'] == false)
          .map((e) => {...e.value, '_originalIndex': e.key})
          .toList();
    }
    return _notifications.asMap().entries   //todas
        .map((e) => {...e.value, '_originalIndex': e.key})
        .toList();
  }
 
  int get _naoLidasCount => //contador
      _notifications.where((n) => n['lida'] == false).length;
 
  @override
  Widget build(BuildContext context) {
    final filtered = _filterednotifications;
 
    return TemplatePortalPaciente(
      currentIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Notificações',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
 
          // Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 0),
                  child: Column(
                    children: [
                      Text(
                        'Todas',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _tabIndex == 0
                              ? const Color(0xFF1A8070)
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2,
                        color: _tabIndex == 0
                            ? const Color(0xFF1A8070)
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 1),
                  child: Column(
                    children: [
                      Text(
                        _naoLidasCount > 0
                            ? 'Não Lidas ($_naoLidasCount)'
                            : 'Não Lidas',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _tabIndex == 1
                              ? const Color(0xFF1A8070)
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2,
                        color: _tabIndex == 1
                            ? const Color(0xFF1A8070)
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
 
          // Divisão por baixo das tabs
          Container(
            height: 1,
            color: const Color(0xFFB2DFDB),
          ),
 
          const SizedBox(height: 8),
 
          // Lista de notificações
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Sem notificações não lidas.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Color(0xFFB2DFDB),
              ),
              itemBuilder: (context, i) {
                final notif = filtered[i];
                final originalIndex = notif['_originalIndex'] as int;
                final bool lida = notif['lida'] as bool;
 
                return GestureDetector(
                  onTap: () => _marcarComoLida(originalIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Círculo indicador
                        Padding(
                          padding: const EdgeInsets.only(top: 3, right: 12),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lida
                                  ? Colors.transparent
                                  : const Color(0xFF1A8070),
                            ),
                          ),
                        ),
                        // Texto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['titulo'] as String,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: lida
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notif['tempo'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
 
          const SizedBox(height: 32),
 
          // Botão "Marcar todas como lidas"
          if (_naoLidasCount > 0)
            Center(
              child: GestureDetector(
                onTap: _marcarTodasComoLidas,
                child: const Text(
                  'MARCAR TODAS COMO LIDAS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A8070),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF1A8070),
                    letterSpacing: 0.5,
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
