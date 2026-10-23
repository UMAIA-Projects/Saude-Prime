import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class ChangePermissionsPage extends StatefulWidget {
  final String userInitials;
  final String userName;
  final String userEmail;
  final String userRole;

  const ChangePermissionsPage({
    super.key,
    required this.userInitials,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<ChangePermissionsPage> createState() => _ChangePermissionsPageState();
}

class _ChangePermissionsPageState extends State<ChangePermissionsPage> {
  // Color palette
  static const Color _pink       = Color(0xFFD4537E);
  static const Color _pinkBorder = Color(0xFFD5B7C4);
  static const Color _textMuted  = Color(0xFF888888);
  static const Color _cardBg     = Color(0xFFD5E2E3);
  static const Color _selectedBg = Color(0xFFD5E6E5);

  int _navIndex = 1;

  // Permission levels - 'value' is the DB role string
  final List<Map<String, String>> _levels = [
    {'label': 'Paciente',     'desc': 'Acesso básico a consultas e documentos', 'value': 'patient',      'icon': 'person'},
    {'label': 'Médico',       'desc': 'Agenda, fila e documentos clínicos',     'value': 'doctor',       'icon': 'person'},
    {'label': 'Rececionista', 'desc': 'Pacientes, agendamentos e fila',         'value': 'receptionist', 'icon': 'person'},
    {'label': 'Admin',        'desc': 'Acesso total ao sistema',                'value': 'admin',        'icon': 'settings'},
  ];

  late String _selected; // DB role string
  int? _especialidadeSelecionada;
  List<Map<String, dynamic>> _especialidades = [];
  bool _loadingEspecialidades = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.userRole;
    _carregarEspecialidades();
  }

  Future<void> _carregarEspecialidades() async {
    setState(() => _loadingEspecialidades = true);
    try {
      final res = await db.from('specialties').select('id, name').order('name');
      setState(() {
        _especialidades = List<Map<String, dynamic>>.from(res);
        _loadingEspecialidades = false;
      });
    } catch (e) {
      setState(() => _loadingEspecialidades = false);
    }
  }

  // Avatar colors - based on DB role
  static Color _avatarBgForRole(String role) {
    switch (role) {
      case 'doctor':       return const Color(0xFF64B5F6);
      case 'receptionist': return const Color(0xCCBA7517);
      case 'admin':        return const Color(0xCC6A9890);
      default:             return const Color(0xCC3DBDAD);
    }
  }

  static Color _avatarTextForRole(String role) {
    switch (role) {
      case 'doctor':       return const Color(0xFF1A3B8B);
      case 'receptionist': return const Color(0xFF7A5000);
      default:             return const Color(0xFF0F6E56);
    }
  }

  // Label for display
  String _labelForRole(String role) {
    switch (role) {
      case 'doctor':       return 'Médico';
      case 'receptionist': return 'Rececionista';
      case 'admin':        return 'Admin';
      default:             return 'Paciente';
    }
  }

  IconData _iconForType(String icon) =>
      icon == 'settings' ? Icons.settings_outlined : Icons.person_outline;

  void _guardar() {
    if (_selected == 'doctor' && _especialidadeSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma especialidade para o médico.')),
      );
      return;
    }

    Navigator.pop(context, {
      'role': _selected,
      'specialty_id': _especialidadeSelecionada,
    });
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back link
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '< Voltar Atrás',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _pink,
                decoration: TextDecoration.underline,
                decorationColor: _pink,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Page title
          const Text(
            'Alterar Permissões',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // User card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _pinkBorder, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 55, height: 55,
                  decoration: BoxDecoration(
                    color: _avatarBgForRole(widget.userRole),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.userInitials,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: _avatarTextForRole(widget.userRole)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    Opacity(
                      opacity: 0.5,
                      child: Text(widget.userEmail, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black87)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labelForRole(widget.userRole),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: _pink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          const Text(
            'Seleciona o novo nível de acesso:',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: _textMuted),
          ),
          const SizedBox(height: 12),

          // Permission level options
          ..._levels.map((level) {
            final isSelected = _selected == level['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selected = level['value']!),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? _pink : _pinkBorder, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconForType(level['icon']!), color: isSelected ? _pink : Colors.black54, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(level['label']!, style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? _pink : Colors.black87)),
                            Text(level['desc']!,  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400, color: isSelected ? _pink : Colors.black54)),
                          ],
                        ),
                      ),
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? _pink : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? _pink : _pinkBorder, width: 2),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Seção de especialidade (apenas se 'Médico' estiver selecionado)
          if (_selected == 'doctor') ...[
            const SizedBox(height: 8),
            const Text(
              'Especialidade do Médico:',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _pinkBorder, width: 2),
              ),
              child: _loadingEspecialidades 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _pink))),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _especialidadeSelecionada,
                      hint: const Text('Selecione uma especialidade', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      items: _especialidades.map((esp) {
                        return DropdownMenuItem<int>(
                          value: esp['id'],
                          child: Text(esp['name'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _especialidadeSelecionada = val),
                    ),
                  ),
            ),
          ],

          const SizedBox(height: 24),

          // Save button
          GestureDetector(
            onTap: _guardar,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(24)),
              alignment: Alignment.center,
              child: const Text('Guardar Permissões', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel link
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                'Cancelar',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _pink, decoration: TextDecoration.underline, decorationColor: _pink),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
