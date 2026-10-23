import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class AbaConsultasList extends StatelessWidget {
  final List<ConsultaModel> consultas;

  const AbaConsultasList({super.key, required this.consultas});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: consultas.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 0.5,
          color: Color(0xFFEEEEEE),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) => _item(consultas[i]),
      ),
    );
  }

  Widget _item(ConsultaModel c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.tipo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3B8B),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.data}  ·  ${c.medico}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _corFundo(c.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              c.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _corTexto(c.status),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _corTexto(String status) {
    switch (status) {
      case 'Concluída':
        return const Color(0xFF1E8449);
      case 'Faltou':
        return const Color(0xFFE53935);
      case 'Agendada':
        return const Color(0xFF3B6BE0);
      default:
        return Colors.black54;
    }
  }

  Color _corFundo(String status) {
    switch (status) {
      case 'Concluída':
        return const Color(0xFFE8F8F5);
      case 'Faltou':
        return const Color(0xFFFFEBEE);
      case 'Agendada':
        return const Color(0xFFDCEEFD);
      default:
        return Colors.grey.shade100;
    }
  }
}
