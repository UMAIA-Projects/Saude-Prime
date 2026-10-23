import 'package:saude_app/core/document_download.dart';
import 'package:saude_app/paginas_portal_medico/portal_medico.dart';


// ─────────────────────────────────────────────
//  Modelos
// ─────────────────────────────────────────────
enum TipoEntrada { consulta, analise }

class EntradaHistorico {
  final String appointmentId;
  final String data;
  final TipoEntrada tipo;
  final String descricao;
  final String hora;

  const EntradaHistorico({
    required this.appointmentId,
    required this.data,
    required this.tipo,
    required this.descricao,
    required this.hora,
  });
}

class Documento {
  final String id;
  final String nome;
  final String tipo; // 'pdf' | 'imagem' | 'outro'
  final String data;
  final String tamanho;
  final String filePath;

  const Documento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.data,
    required this.tamanho,
    required this.filePath,
  });
}

class ConsultaItem {
  final String id;
  final String data;
  final String motivo;
  final String medico;
  final String estado; // 'Realizada' | 'Agendada' | 'Cancelada' | 'Não compareceu'
  final String hora;

  const ConsultaItem({
    required this.id,
    required this.data,
    required this.motivo,
    required this.medico,
    required this.estado,
    required this.hora,
  });
}


// ─────────────────────────────────────────────
//  Página principal
// ─────────────────────────────────────────────
class PatientData extends StatefulWidget {
  // Identificador do paciente — obrigatório para carregar dados
  final String patientId;

  // Dados já disponíveis desde a pesquisa (evitam um fetch extra)
  final String nomePaciente;
  final String iniciais;
  final Color avatarBg;
  final Color avatarFg;
  final String dataNasc;
  final String nif;
  final String telefone;

  const PatientData({
    super.key,
    required this.patientId,
    this.nomePaciente = '',
    this.iniciais = '',
    this.avatarBg = const Color(0xFFD8F2EF),
    this.avatarFg = const Color(0xFF1A6B62),
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

  // Dados dinâmicos
  List<EntradaHistorico> _historico = [];
  List<Documento> _documentos = [];
  List<ConsultaItem> _consultas = [];

  bool _loadingHistorico = true;
  bool _loadingDocs = true;
  bool _loadingConsultas = true;

  String? _erroHistorico;
  String? _erroDocs;
  String? _erroConsultas;

  // Helpers de formatação
  static const List<String> _meses = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_meses[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtTime(String? t) {
    if (t == null || t.length < 5) return '';
    return t.substring(0, 5);
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'completed':
        return 'Realizada';
      case 'canceled':
        return 'Cancelada';
      case 'no_show':
        return 'Não compareceu';
      default:
        return 'Agendada';
    }
  }

  TipoConsulta _mapTipo(String t) {
    switch (t) {
      case 'urgent':
        return TipoConsulta.urgente;
      case 'follow_up':
        return TipoConsulta.normal;
      default:
        return TipoConsulta.normal;
    }
  }

  String _tipoDocLabel(String t) {
    switch (t) {
      case 'analysis':
        return 'analise'; // trigger para ícone de imagem
      case 'prescription':
        return 'pdf';
      case 'invoice':
        return 'pdf';
      default:
        return 'outro';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistorico();
    _loadDocumentos();
    _loadConsultas();
  }

  // ── Histórico (consultas completadas deste paciente com qualquer médico) ──
  Future<void> _loadHistorico() async {
    setState(() {
      _loadingHistorico = true;
      _erroHistorico = null;
    });
    try {
      final rows = await db
          .from('appointments')
          .select('''
            id,
            scheduled_date,
            scheduled_time,
            type,
            status,
            patient_notes,
            diagnosis_notes,
            doctors!inner(
              users!inner( name )
            )
          ''')
          .eq('patient_id', widget.patientId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null)
          .order('scheduled_date', ascending: false)
          .limit(30);

      final List<EntradaHistorico> lista = [];
      for (final row in rows) {
        final tipo = (row['type'] as String?) == 'analysis'
            ? TipoEntrada.analise
            : TipoEntrada.consulta;
        final desc = (row['diagnosis_notes'] as String?)?.isNotEmpty == true
            ? row['diagnosis_notes'] as String
            : (row['patient_notes'] as String? ?? 'Sem notas registadas.');
        lista.add(EntradaHistorico(
          appointmentId: row['id'] as String,
          data: _fmtDate(row['scheduled_date'] as String?),
          hora: _fmtTime(row['scheduled_time'] as String?),
          tipo: tipo,
          descricao: desc,
        ));
      }

      if (!mounted) return;
      setState(() {
        _historico = lista;
        _loadingHistorico = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroHistorico = 'Erro ao carregar histórico: $e';
        _loadingHistorico = false;
      });
    }
  }

  // ── Documentos ────────────────────────────────────────────────────────────
  Future<void> _loadDocumentos() async {
    setState(() {
      _loadingDocs = true;
      _erroDocs = null;
    });
    try {
      final rows = await db
          .from('documents')
          .select('id, name, type, file_path, file_size_bytes, created_at')
          .eq('patient_id', widget.patientId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final List<Documento> lista = rows
          .map((row) => Documento(
                id: row['id'] as String,
                nome: row['name'] as String? ?? 'Documento',
                tipo: _tipoDocLabel(row['type'] as String? ?? 'other'),
                data: _fmtDate(row['created_at'] as String?),
                tamanho: _fmtBytes(
                    (row['file_size_bytes'] as num?)?.toInt() ?? 0),
                filePath: row['file_path'] as String? ?? '',
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _documentos = lista;
        _loadingDocs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroDocs = 'Erro ao carregar documentos: $e';
        _loadingDocs = false;
      });
    }
  }

  // ── Consultas (todas) ──────────────────────────────────────────────────────
  Future<void> _loadConsultas() async {
    setState(() {
      _loadingConsultas = true;
      _erroConsultas = null;
    });
    try {
      final rows = await db
          .from('appointments')
          .select('''
            id,
            scheduled_date,
            scheduled_time,
            type,
            status,
            patient_notes,
            doctors!inner(
              users!inner( name )
            )
          ''')
          .eq('patient_id', widget.patientId)
          .isFilter('deleted_at', null)
          .order('scheduled_date', ascending: false);

      final List<ConsultaItem> lista = rows
          .map((row) {
            final drName = (row['doctors']?['users']?['name'] as String?) ??
                'Médico desconhecido';
            return ConsultaItem(
              id: row['id'] as String,
              data: _fmtDate(row['scheduled_date'] as String?),
              hora: _fmtTime(row['scheduled_time'] as String?),
              motivo: (row['patient_notes'] as String?)?.isNotEmpty == true
                  ? row['patient_notes'] as String
                  : 'Consulta',
              medico: drName,
              estado: _statusLabel(row['status'] as String? ?? 'scheduled'),
            );
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _consultas = lista;
        _loadingConsultas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroConsultas = 'Erro ao carregar consultas: $e';
        _loadingConsultas = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      currentIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Voltar atrás
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

          // Card Paciente
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
                    color: widget.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.iniciais,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.avatarFg,
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
                        '${widget.dataNasc} · NIF: ${widget.nif}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A9890),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: Color(0xFF6A9890),
                          ),
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

          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MarcarConsulta(
                  patientId: widget.patientId,
                  nomePaciente: widget.nomePaciente,
                ),
              ),
            ).then((ok) {
              if (ok == true) {
                _loadConsultas();
                _loadHistorico();
              }
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A8070),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Marcar Consulta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tabs
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

          // Conteúdo da tab
          if (_tabIndex == 0)
            _HistoricoTab(
              entradas: _historico,
              loading: _loadingHistorico,
              erro: _erroHistorico,
              nomePaciente: widget.nomePaciente,
              iniciais: widget.iniciais,
              nif: widget.nif,
            ),
          if (_tabIndex == 1)
            _DocumentosTab(
              documentos: _documentos,
              loading: _loadingDocs,
              erro: _erroDocs,
              nomePaciente: widget.nomePaciente,
              iniciais: widget.iniciais,
              patientId: widget.patientId,
              onUploaded: _loadDocumentos,
            ),
          if (_tabIndex == 2)
            _ConsultasTab(
              consultas: _consultas,
              loading: _loadingConsultas,
              erro: _erroConsultas,
              nomePaciente: widget.nomePaciente,
              iniciais: widget.iniciais,
              nif: widget.nif,
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────
//  Tab Histórico — timeline
// ─────────────────────────────────────────────
class _HistoricoTab extends StatelessWidget {
  final List<EntradaHistorico> entradas;
  final bool loading;
  final String? erro;
  final String nomePaciente;
  final String iniciais;
  final String nif;

  const _HistoricoTab({
    required this.entradas,
    required this.loading,
    required this.erro,
    required this.nomePaciente,
    required this.iniciais,
    required this.nif,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF46AA9F)),
        ),
      );
    }
    if (erro != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          erro!,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFD94F3D),
            fontFamily: 'Poppins',
          ),
        ),
      );
    }
    if (entradas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Sem histórico clínico registado.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.40),
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

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
                          color: Colors.black.withValues(alpha: 0.55),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Ver
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Consulta(
                              appointmentId: e.appointmentId,
                            ),
                          ),
                        ),
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


// ─────────────────────────────────────────────
//  Tab Documentos
// ─────────────────────────────────────────────
class _DocumentosTab extends StatefulWidget {
  final List<Documento> documentos;
  final bool loading;
  final String? erro;
  final String nomePaciente;
  final String iniciais;
  final String patientId;
  final VoidCallback onUploaded;

  const _DocumentosTab({
    required this.documentos,
    required this.loading,
    required this.erro,
    required this.nomePaciente,
    required this.iniciais,
    required this.patientId,
    required this.onUploaded,
  });

  @override
  State<_DocumentosTab> createState() => _DocumentosTabState();
}

class _DocumentosTabState extends State<_DocumentosTab> {
  String? _downloadingId;

  IconData _icon(String tipo) {
    if (tipo == 'imagem' || tipo == 'analise') return Icons.image_outlined;
    return Icons.picture_as_pdf_outlined;
  }

  Color _iconColor(String tipo) {
    if (tipo == 'imagem' || tipo == 'analise') return const Color(0xFF185FA5);
    return const Color(0xFFD94F3D);
  }

  Future<void> _onDownload(Documento doc) async {
    setState(() => _downloadingId = doc.id);
    await downloadPatientDocument(
      context,
      filePath: doc.filePath,
      displayName: doc.nome,
    );
    if (mounted) setState(() => _downloadingId = null);
  }

  @override
  Widget build(BuildContext ctx) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF46AA9F)),
        ),
      );
    }
    if (widget.erro != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.erro!,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFD94F3D),
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.documentos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Sem documentos associados.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.40),
                fontFamily: 'Poppins',
              ),
            ),
          )
        else
          ...widget.documentos.map(
            (doc) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  GestureDetector(
                    onTap: _downloadingId == doc.id
                        ? null
                        : () => _onDownload(doc),
                    child: _downloadingId == doc.id
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF46AA9F),
                            ),
                          )
                        : const Icon(
                            Icons.download_outlined,
                            size: 20,
                            color: Color(0xFF46AA9F),
                          ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 14),

        // Botão Adicionar Documento
        GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => SendDocument(
                nomePaciente: widget.nomePaciente,
                iniciais: widget.iniciais,
                patientId: widget.patientId,
              ),
            ),
          ).then((_) => widget.onUploaded()),
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


// ─────────────────────────────────────────────
//  Tab Consultas
// ─────────────────────────────────────────────
class _ConsultasTab extends StatelessWidget {
  final List<ConsultaItem> consultas;
  final bool loading;
  final String? erro;
  final String nomePaciente;
  final String iniciais;
  final String nif;

  const _ConsultasTab({
    required this.consultas,
    required this.loading,
    required this.erro,
    required this.nomePaciente,
    required this.iniciais,
    required this.nif,
  });

  Color _estadoCor(String estado) {
    switch (estado) {
      case 'Agendada':
        return const Color(0xFF185FA5);
      case 'Cancelada':
        return const Color(0xFFD94F3D);
      case 'Não compareceu':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1A8070);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF46AA9F)),
        ),
      );
    }
    if (erro != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          erro!,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFD94F3D),
            fontFamily: 'Poppins',
          ),
        ),
      );
    }
    if (consultas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Sem consultas registadas.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.40),
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return Column(
      children: consultas
          .map(
            (c) => GestureDetector(
              onTap: c.estado == 'Realizada'
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Consulta(appointmentId: c.id),
                        ),
                      )
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
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
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 22,
                      color: Color(0xFF46AA9F),
                    ),
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
                            '${c.data}${c.hora.isNotEmpty ? ' às ${c.hora}' : ''} · ${c.medico}',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
              ),
            ),
          )
          .toList(),
    );
  }
}