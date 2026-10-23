import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Paleta
  static const Color _primary = Color(0xFF1A8070);
  static const Color _accentLight = Color(0xFFE598B2);
  static const Color _accentDark = Color(0xFFD4537E);
  static const Color _sectionLabel = Color(0xFFAD094B);
  static const Color _textMuted = Color(0xFF787878);
  static const Color _deleteRed = Color(0xFFD12B2B);
  static const Color _deleteBg = Color(0xFFFFDCDC);
  static const Color _badgeBg = Color(0xFFD5EAFF);
  static const Color _cardBg = Color(0xFFD5E2E3);

  // Estado
  int _navIndex = 1;
  bool _loading = true;
  bool _savingRole = false;
  bool _deletingUser = false;
  bool _editing = false; // modo edição activo
  bool _saving = false; // a gravar edições
  String? _error;

  Map<String, dynamic>? _userData;
  String _currentNivel = '';
  String _currentAcessoDesc = '';

  // Controladores de edição
  late TextEditingController _ctrlName;
  late TextEditingController _ctrlPhone;
  late TextEditingController _ctrlAddress;

  @override
  void initState() {
    super.initState();
    _ctrlName = TextEditingController();
    _ctrlPhone = TextEditingController();
    _ctrlAddress = TextEditingController();
    _loadUser();
  }

  @override
  void dispose() {
    _ctrlName.dispose();
    _ctrlPhone.dispose();
    _ctrlAddress.dispose();
    super.dispose();
  }

  // Carregar dados do utilizador
  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await db
          .from('users')
          .select(
            'id, name, email, role, nif, date_of_birth, phone, address, created_at, last_login',
          )
          .eq('id', widget.userId)
          .isFilter('deleted_at', null)
          .single();

      if (!mounted) return;
      final data = Map<String, dynamic>.from(res as Map);
      _fillControllers(data);
      setState(() {
        _userData = data;
        _currentNivel = _roleLabel(data['role'] as String);
        _currentAcessoDesc = _descForNivel(_roleLabel(data['role'] as String));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _fillControllers(Map<String, dynamic> data) {
    _ctrlName.text = data['name'] as String? ?? '';
    _ctrlPhone.text = data['phone'] as String? ?? '';
    _ctrlAddress.text = data['address'] as String? ?? '';
  }

  // Guardar edições
  Future<void> _saveEdits() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });

    try {
      final updates = {
        'name': _ctrlName.text.trim(),
        'phone': _ctrlPhone.text.trim(),
        'address': _ctrlAddress.text.trim(),
      };

      await db.from('users').update(updates).eq('id', widget.userId);

      if (!mounted) return;
      setState(() {
        _userData!['name'] = updates['name'];
        _userData!['phone'] = updates['phone'];
        _userData!['address'] = updates['address'];
        _editing = false;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
    }
  }

  void _cancelEdit() {
    _fillControllers(_userData!); // repõe valores originais
    setState(() => _editing = false);
  }

  // Helpers de role
  String _roleLabel(String role) {
    switch (role) {
      case 'doctor':
        return 'Médico';
      case 'receptionist':
        return 'Receção';
      case 'admin':
        return 'Admin';
      default:
        return 'Paciente';
    }
  }

  String _descForNivel(String nivel) {
    switch (nivel) {
      case 'Médico':
        return 'Acesso clínico';
      case 'Receção':
        return 'Acesso receção';
      case 'Admin':
        return 'Acesso total';
      default:
        return 'Acesso básico';
    }
  }

  // Helpers de formatação
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (name.isNotEmpty)
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    return '??';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _sinceLabel(String? isoDate) {
    if (isoDate == null) return '-';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '-';
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _loginLabel(String? isoDate) {
    if (isoDate == null) return 'Nunca';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '-';
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  // Avatar
  Color _avatarBg(String nivel) {
    switch (nivel) {
      case 'Médico':
        return const Color(0xFF64B5F6);
      case 'Receção':
        return const Color(0xCCBA7517);
      case 'Admin':
        return const Color(0xCC6A9890);
      default:
        return const Color(0xCC3DBDAD);
    }
  }

  Color _avatarText(String nivel) {
    switch (nivel) {
      case 'Médico':
        return const Color(0xFF1A3B8B);
      case 'Receção':
        return const Color(0xFF7A5000);
      default:
        return const Color(0xFF0F6E56);
    }
  }

  // Navegação
  void _goBack() => Navigator.pop(context, {'role': _userData?['role'] ?? ''});

  Future<void> _goToChangePermissions() async {
    final u = _userData!;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePermissionsPage(
          userInitials: _initials(u['name'] as String),
          userName: u['name'] as String,
          userEmail: u['email'] as String,
          userRole: u['role'] as String,
        ),
      ),
    );

    if (result == null) return;

    final newDbRole = result['role'] as String;
    final specialtyId = result['specialty_id'] as int?;
    final oldDbRole = u['role'] as String;

    if (newDbRole == oldDbRole && newDbRole != 'doctor') return;

    setState(() => _savingRole = true);
    try {
      // 1. Atualizar o role na tabela users
      await db
          .from('users')
          .update({'role': newDbRole})
          .eq('id', widget.userId);

      // 2. Lógica de suspensão/ativação na tabela doctors
      if (newDbRole == 'doctor' && specialtyId != null) {
        // Se agora é médico, ativamos ou criamos o registo (suspended = false)
        await db.from('doctors').upsert({
          'user_id': widget.userId,
          'specialty_id': specialtyId,
          'license_number':
              'OM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          'default_slot_duration_min': 30,
          'suspended': false, // Garantir que não está suspenso
        });
      } else if (oldDbRole == 'doctor' && newDbRole != 'doctor') {
        // Se era médico e deixou de ser, marcamos como suspenso para não aparecer em novas marcações
        await db
            .from('doctors')
            .update({'suspended': true})
            .eq('user_id', widget.userId);
      }

      if (!mounted) return;
      setState(() {
        _userData!['role'] = newDbRole;
        _currentNivel = _roleLabel(newDbRole);
        _currentAcessoDesc = _descForNivel(_roleLabel(newDbRole));
        _savingRole = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissões atualizadas com sucesso!'),
          backgroundColor: _primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingRole = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar permissão: $e'),
          backgroundColor: _deleteRed,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Conta',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: _deleteRed,
          ),
        ),
        content: Text(
          'Tem a certeza que pretende eliminar a conta de ${_userData!['name']}? Esta acção é irreversível.',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _deleteRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    setState(() => _deletingUser = true);
    try {
      await db.rpc(
        'admin_soft_delete_user',
        params: {'p_user_id': widget.userId},
      );

      if (!mounted) return;
      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingUser = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao eliminar conta: $e')));
    }
  }

  // Widget helpers
  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _sectionLabel,
      ),
    ),
  );

  Widget _dividerLine() => const Divider(
    height: 1,
    indent: 12,
    endIndent: 12,
    color: Color(0xFFE0ECEB),
  );

  // Linha estática (modo visualização)
  Widget _infoRow(String label, String value) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: _textMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
      _dividerLine(),
    ],
  );

  // Linha editável (modo edição)
  Widget _editRow(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
  }) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: _textMuted,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: keyboardType,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD5B7C4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _accentDark,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD5B7C4)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      _dividerLine(),
    ],
  );

  // Build
  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 2,
                ),
              ),
            )
          : _error != null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'Erro ao carregar perfil.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _loadUser,
                      child: const Text(
                        'Tentar novamente',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final u = _userData!;
    final name = u['name'] as String;
    final email = u['email'] as String;
    final nif = u['nif'] as String? ?? '-';
    final dob = _formatDate(u['date_of_birth'] as String?);
    final registro = _sinceLabel(u['created_at'] as String?);
    final login = _loginLabel(u['last_login'] as String?);
    final phone = u['phone'] as String? ?? '-';
    final address = u['address'] as String? ?? '-';

    final isOwnProfile = db.auth.currentUser?.id == widget.userId;
    final isAdmin = _userData!['role'] == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _goBack,
              child: const Text(
                '< Voltar Atrás',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _accentDark,
                  decoration: TextDecoration.underline,
                  decorationColor: _accentDark,
                ),
              ),
            ),
            if (!isOwnProfile)
              GestureDetector(
                onTap: _saving
                    ? null
                    : (_editing
                          ? _saveEdits
                          : () => setState(() => _editing = true)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _editing ? _accentDark : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _editing ? Icons.check : Icons.edit_outlined,
                          size: 18,
                          color: _editing ? Colors.white : Colors.black54,
                        ),
                ),
              ),
          ],
        ),

        // Aviso de cancelamento (só no modo edição)
        if (_editing) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _cancelEdit,
            child: const Text(
              'Cancelar edição',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _accentDark,
                decoration: TextDecoration.underline,
                decorationColor: _accentDark,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Avatar card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _accentLight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _avatarBg(_currentNivel),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _avatarText(_currentNivel),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: 0.5,
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      borderRadius: BorderRadius.circular(75),
                    ),
                    child: Text(
                      _currentNivel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            children: [
              // Nome - editável
              _editing ? _editRow('Nome', _ctrlName) : _infoRow('Nome', name),

              // NIF - sempre só-leitura
              _infoRow('NIF', nif),

              // Data Nascimento - sempre só-leitura
              _infoRow('Data Nasc.', dob),

              // Telemóvel - editável
              _editing
                  ? _editRow(
                      'Telemóvel',
                      _ctrlPhone,
                      keyboardType: TextInputType.phone,
                    )
                  : _infoRow('Telemóvel', phone),

              // Morada - editável (última linha, sem divider final)
              _editing
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text(
                              'Morada',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: _textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _ctrlAddress,
                              keyboardType: TextInputType.streetAddress,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD5B7C4),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: _accentDark,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD5B7C4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text(
                              'Morada',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: _textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

              // Linha extra de metadados (Registro + Last login) - sempre só-leitura
              _dividerLine(),
              _infoRow('Registro', registro),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text(
                        'Último login',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        login,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Permissões
        _sectionTitle('PERMISSÕES'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Poppins'),
                        children: [
                          const TextSpan(
                            text: 'Nível:  ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: _currentNivel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentAcessoDesc,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _savingRole ? null : _goToChangePermissions,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _savingRole
                        ? _accentDark.withOpacity(0.5)
                        : _accentDark,
                    borderRadius: BorderRadius.circular(75),
                  ),
                  child: _savingRole
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Alterar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Eliminar (oculto para outros admins; próprio admin pode eliminar-se)
        if (!isAdmin || isOwnProfile)
          GestureDetector(
            onTap: _deletingUser ? null : _confirmDelete,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _deleteBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _accentLight, width: 1),
              ),
              alignment: Alignment.center,
              child: _deletingUser
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _deleteRed,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: _deleteRed, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar Conta',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _deleteRed,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
