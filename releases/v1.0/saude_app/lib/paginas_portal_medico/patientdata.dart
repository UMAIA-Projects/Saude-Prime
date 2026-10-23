import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';
import 'package:saude_app/paginas_portal_medico/senddocument.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos
// ─────────────────────────────────────────────────────────────────────────────

enum TipoEntrada { consulta, analise }

class EntradaHistorico {
  final String data;
  final TipoEntrada tipo;
  final String descricao;

  const EntradaHistorico({
    required this.data,
    required this.tipo,
    required this.descricao,
  });
}

class Documento {
  final String nome;
  final String tipo; // 'pdf' | 'imagem' | 'outro'
  final String data;
  final String tamanho;

  const Documento({
    required this.nome,
    required this.tipo,
    required this.data,
    required this.tamanho,
  });
}

class ConsultaItem {
  final String data;
  final String motivo;
  final String medico;
  final String estado; // 'Realizada' | 'Agendada' | 'Cancelada'

  const ConsultaItem({
    required this.data,
    required this.motivo,
    required this.medico,
    required this.estado,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Página principal
// ─────────────────────────────────────────────────────────────────────────────

class PatientData extends StatefulWidget {
  final String nomePaciente;
  final String iniciais;
  final Color avatarColor;
  final Color iniciaisColor;
  final String dataNasc;
  final String nif;
  final String telefone;

  const PatientData({
    super.key,
    this.nomePaciente = '',
    this.iniciais = '',
    this.avatarColor = const Color(0xFFD8F2EF),
    this.iniciaisColor = const Color(0xFF1A6B62),
    this.dataNasc = '',
    this.nif = '',
    this.telefone = '',
  });

  @override
  State<PatientData> createState() => _PatientDataState();
}

class _PatientDataState extends State<PatientData> {
  int _tabIndex = 0; // 0 Histórico | 1 Documentos | 2 Consultas

  static const List<String> _tabs = ['Histórico', 'Documentos', 'Consultas'];

  // Mock de dados
  static const List<EntradaHistorico> _historico = [
    EntradaHistorico(
      data: '15 Mar 2025',
      tipo: TipoEntrada.consulta,
      descricao: 'Gripe - Ibuprofeno + Repouso',
    ),
    EntradaHistorico(
      data: '2 Fev 2025',
      tipo: TipoEntrada.analise,
      descricao: 'Hemograma completo. Valores normais.',
    ),
    EntradaHistorico(
      data: '10 Jan 2025',
      tipo: TipoEntrada.consulta,
      descricao: 'Tensão 125/80. Controlo semestral.',
    ),
  ];

  static const List<Documento> _documentos = [
    Documento(
      nome: 'Hemograma_Fev2025.pdf',
      tipo: 'pdf',
      data: '2 Fev 2025',
      tamanho: '1.2 MB',
    ),
    Documento(
      nome: 'Receita_Ibuprofeno.pdf',
      tipo: 'pdf',
      data: '15 Mar 2025',
      tamanho: '320 KB',
    ),
    Documento(
      nome: 'Radiografia_Torax.jpg',
      tipo: 'imagem',
      data: '10 Jan 2025',
      tamanho: '4.7 MB',
    ),
    Documento(
      nome: 'Relatorio_Cardiologia.pdf',
      tipo: 'pdf',
      data: '5 Nov 2024',
      tamanho: '890 KB',
    ),
  ];

  static const List<ConsultaItem> _consultas = [
    ConsultaItem(
      data: '15 Mar 2025',
      motivo: 'Gripe sazonal',
      medico: 'Dr. Carlos Silva',
      estado: 'Realizada',
    ),
    ConsultaItem(
      data: '10 Jan 2025',
      motivo: 'Controlo tensão arterial',
      medico: 'Dr. Carlos Silva',
      estado: 'Realizada',
    ),
    ConsultaItem(
      data: '2 Fev 2025',
      motivo: 'Análises clínicas',
      medico: 'Dra. Ana Martins',
      estado: 'Realizada',
    ),
    ConsultaItem(
      data: '10 Mai 2025',
      motivo: 'Consulta de seguimento',
      medico: 'Dr. Carlos Silva',
      estado: 'Agendada',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        if (index == 3) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Search()), (r) => false);}
        if (index == 4) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Profile()), (r) => false);}
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Voltar atrás ────────────────────────────────────────────────
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

          // ── Card Paciente ───────────────────────────────────────────────
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
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.iniciais,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.iniciaisColor,
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
                        widget.nomePaciente,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.dataNasc} - NIF: ${widget.nif}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A9890),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: Color(0xFF6A9890)),
                          const SizedBox(width: 4),
                          Text(
                            widget.telefone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6A9890),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tabs ────────────────────────────────────────────────────────
          Row(
            children: List.generate(_tabs.length, (i) {
              final bool isActive = i == _tabIndex;
              return GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: isActive
                        ? const Border(
                            bottom: BorderSide(
                              color: Color(0xFF46AA9F),
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isActive
                          ? const Color(0xFF46AA9F)
                          : const Color(0xFF46AA9F).withValues(alpha: 0.50),
                      decoration: isActive
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: const Color(0xFF46AA9F),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // ── Conteúdo da tab ─────────────────────────────────────────────
          if (_tabIndex == 0) _HistoricoTab(entradas: _historico),
          if (_tabIndex == 1) _DocumentosTab(
            documentos: _documentos,
            nomePaciente: widget.nomePaciente,
            iniciais: widget.iniciais,
            context: context,
          ),
          if (_tabIndex == 2) _ConsultasTab(consultas: _consultas),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Histórico — timeline
// ─────────────────────────────────────────────────────────────────────────────

class _HistoricoTab extends StatelessWidget {
  final List<EntradaHistorico> entradas;

  const _HistoricoTab({required this.entradas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entradas.length, (i) {
        final e = entradas[i];
        final bool isLast = i == entradas.length - 1;
        final Color dotColor = e.tipo == TipoEntrada.consulta
            ? const Color(0xFF3DBDAD)
            : const Color(0xFF1A3B8B);
        final Color tipoColor = e.tipo == TipoEntrada.consulta
            ? const Color(0xFF1A8070)
            : const Color(0xFF1A3B8B);
        final String tipoLabel =
            e.tipo == TipoEntrada.consulta ? 'Consulta' : 'Análise';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline — linha + ponto
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Conteúdo
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Data + Tipo
                      Row(
                        children: [
                          Text(
                            e.data,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            tipoLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tipoColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Descrição
                      Text(
                        e.descricao,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.26),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Ver
                      GestureDetector(
                        onTap: () {/* TODO: ver detalhe */},
                        child: const Text(
                          'Ver',
                          style: TextStyle(
                            fontSize: 12,
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
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Documentos
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentosTab extends StatelessWidget {
  final List<Documento> documentos;
  final String nomePaciente;
  final String iniciais;
  final BuildContext context;

  const _DocumentosTab({
    required this.documentos,
    required this.nomePaciente,
    required this.iniciais,
    required this.context,
  });

  IconData _icon(String tipo) {
    if (tipo == 'imagem') return Icons.image_outlined;
    return Icons.picture_as_pdf_outlined;
  }

  Color _iconColor(String tipo) {
    if (tipo == 'imagem') return const Color(0xFF185FA5);
    return const Color(0xFFD94F3D);
  }

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        ...documentos.map((doc) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 2),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_icon(doc.tipo), color: _iconColor(doc.tipo), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.nome,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.data} · ${doc.tamanho}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.40),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.download_outlined,
                  size: 20, color: Color(0xFF46AA9F)),
            ],
          ),
        )),

        const SizedBox(height: 14),

        // ── Botão Adicionar Documento ────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SendDocument(
              nomePaciente: nomePaciente,
              iniciais: iniciais,
            ))),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF46AA9F),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 33,
                  offset: Offset(0, 3),
                  spreadRadius: -17,
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Adicionar Documento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Consultas
// ─────────────────────────────────────────────────────────────────────────────

class _ConsultasTab extends StatelessWidget {
  final List<ConsultaItem> consultas;

  const _ConsultasTab({required this.consultas});

  Color _estadoCor(String estado) {
    switch (estado) {
      case 'Agendada': return const Color(0xFF185FA5);
      case 'Cancelada': return const Color(0xFFD94F3D);
      default: return const Color(0xFF1A8070);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: consultas.map((c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 2),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 22, color: Color(0xFF46AA9F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.motivo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.data} · ${c.medico}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.40),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _estadoCor(c.estado).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c.estado,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _estadoCor(c.estado),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}