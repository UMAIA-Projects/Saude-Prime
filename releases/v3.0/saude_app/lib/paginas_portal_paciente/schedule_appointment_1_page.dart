import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class ScheduleAppointment1Page extends StatefulWidget {
  const ScheduleAppointment1Page({super.key});

  @override
  State<ScheduleAppointment1Page> createState() => _ScheduleAppointment1PageState();
}

class _ScheduleAppointment1PageState extends State<ScheduleAppointment1Page> {
  // Colors
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  // Nav
  int _navIndex = 1;

  // Filtros
  int?   _especialidadeIdx;
  String _pesquisa         = '';
  final GlobalKey _especialidadeFieldKey = GlobalKey();

  // Dados vindos da BD
  List<Map<String, dynamic>> _especialidades = [];
  List<Map<String, dynamic>> _medicos        = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final db = Supabase.instance.client;

      final espResponse = await db
          .from('specialties')
          .select('id, name')
          .order('name');
      final especialidades =
          List<Map<String, dynamic>>.from(espResponse as List);

      final doctors = await db
          .from('doctors')
          .select('user_id, specialty_id, specialties ( id, name )')
          .eq('suspended', false)
          .order('user_id');

      List<Map<String, dynamic>> medicos = [];
      if ((doctors as List).isNotEmpty) {
        final userIds =
            doctors.map((d) => d['user_id'] as String).toList();
        final users = await db
            .from('users')
            .select('id, name')
            .inFilter('id', userIds)
            .isFilter('deleted_at', null);
        final usersMap = {
          for (final u in users as List) u['id'] as String: u,
        };
        medicos = doctors
            .where((d) => usersMap.containsKey(d['user_id'] as String))
            .map((d) {
          return {
            ...Map<String, dynamic>.from(d as Map),
            'users': usersMap[d['user_id'] as String],
          };
        }).toList();
      }

      setState(() {
        _especialidades    = especialidades;
        _medicos           = medicos;
        _loading           = false;
      });
    } catch (e) {
      setState(() {
        _erro    = 'Erro ao carregar dados. Tenta novamente.';
        _loading = false;
      });
    }
  }

  String get _especialidadeLabel {
    if (_especialidadeIdx == null) return '- - - - -';
    return _especialidades[_especialidadeIdx!]['name'] as String;
  }

  // Filtra os médicos pela especialidade e pesquisa
  List<Map<String, dynamic>> get _medicosFiltrados {
    return _medicos.where((m) {
      final especialidadeDoMedico =
          (m['specialties'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      final nomeDoMedico =
          (m['users'] as Map<String, dynamic>?)?['name'] as String? ?? '';

      final matchEsp = _especialidadeIdx == null ||
          especialidadeDoMedico ==
              (_especialidades[_especialidadeIdx!]['name'] as String);
      final matchPesq = _pesquisa.isEmpty ||
          nomeDoMedico.toLowerCase().contains(_pesquisa.toLowerCase()) ||
          especialidadeDoMedico.toLowerCase().contains(_pesquisa.toLowerCase());

      return matchEsp && matchPesq;
    }).toList();
  }

  Future<void> _abrirPickerEspecialidade() async {
    if (_especialidades.isEmpty) return;

    final box = _especialidadeFieldKey.currentContext?.findRenderObject()
        as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final fieldW = box.size.width;

    final selected = await showMenu<int>(
      context: context,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + fieldW,
        offset.dy,
      ),
      constraints: BoxConstraints(
        minWidth: fieldW,
        maxWidth: fieldW,
        maxHeight: 280,
      ),
      items: [
        PopupMenuItem<int>(
          value: -1,
          height: 44,
          child: Text(
            '- - - - -',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _especialidadeIdx == null ? _primary : _textMuted,
            ),
          ),
        ),
        const PopupMenuDivider(),
        ...List.generate(_especialidades.length, (i) {
          final nome = _especialidades[i]['name'] as String;
          final isSelected = _especialidadeIdx == i;
          return PopupMenuItem<int>(
            value: i,
            height: 48,
            child: Text(
              nome,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _primary : const Color(0xFF1A1A1A),
              ),
            ),
          );
        }),
      ],
    );

    if (!mounted || selected == null) return;
    setState(() => _especialidadeIdx = selected == -1 ? null : selected);
  }

  // Extrai as iniciais do nome completo (ex: "Carlos Ferreira" - "CF")
  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A8070)))
          : _erro != null
              ? _ErroView(mensagem: _erro!, onRetry: () {
                  setState(() { _loading = true; _erro = null; });
                  _carregarDados();
                })
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título + barra de progresso
                    const Text(
                      'Marcar Consulta - Médico',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        _ProgressBar(color: _accent),
                        const SizedBox(width: 4),
                        _ProgressBar(color: Colors.white),
                        const SizedBox(width: 4),
                        _ProgressBar(color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de pesquisa
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _pesquisa = v),
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _primary,
                          height: 1.0,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Pesquisar médico...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _textMuted,
                            height: 1.0,
                          ),
                          prefixIcon: Icon(Icons.search, color: _textMuted, size: 18),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 40,
                            minHeight: 38,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 8, bottom: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtro de especialidade
                    const Text(
                      'FILTRAR ESPECIALIDADE',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      key: _especialidadeFieldKey,
                      onTap: _abrirPickerEspecialidade,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primary, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 10,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services_outlined,
                                size: 20, color: _primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _especialidadeLabel,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: _especialidadeIdx == null
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  color: _especialidadeIdx == null
                                      ? _textMuted
                                      : _primary,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: _primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lista de médicos
                    if (_medicosFiltrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'Nenhum médico encontrado.',
                            style: TextStyle(fontFamily: 'Poppins', color: _textMuted),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_medicosFiltrados.length, (i) {
                        final m         = _medicosFiltrados[i];
                        final doctorId  = m['user_id'] as String;
                        final nomeCompleto =
                            (m['users'] as Map<String, dynamic>?)?['name'] as String? ?? 'Médico';
                        final nomeMedico   = '$nomeCompleto';
                        final especialidade =
                            (m['specialties'] as Map<String, dynamic>?)?['name'] as String? ?? '';
                        final initials = _initials(nomeCompleto);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: _accent, shape: BoxShape.circle,
                                      border: Border.all(color: _accentBorder, width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(nomeMedico, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
                                        Text(especialidade, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _textSub)),
                                      ],
                                    ),
                                  ),

                                  // Botão Agendar
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ScheduleAppointment2Page(
                                            doctorId:            doctorId,
                                            medicoInitials:      initials,
                                            medicoNome:          nomeMedico,
                                            medicoEspecialidade: especialidade,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 80, height: 40,
                                      decoration: BoxDecoration(
                                        color: _accent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Agendar',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}


class _ProgressBar extends StatelessWidget {
  final Color color;
  const _ProgressBar({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 110, height: 3,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErroView({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensagem, style: const TextStyle(fontFamily: 'Poppins', color: Colors.red)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: const Text('Tentar novamente', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF1A8070), decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}