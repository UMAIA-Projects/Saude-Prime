import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class UserProfilePage extends StatefulWidget {
  final String userId; // required — UUID from users table

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Color palette
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accentLight  = Color(0xFFE598B2);
  static const Color _accentDark   = Color(0xFFD4537E);
  static const Color _sectionLabel = Color(0xFFAD094B);
  static const Color _textMuted    = Color(0xFF787878);
  static const Color _deleteRed    = Color(0xFFD12B2B);
  static const Color _deleteBg     = Color(0xFFFFDCDC);
  static const Color _badgeBg      = Color(0xFFD5EAFF);
  static const Color _cardBg       = Color(0xFFD5E2E3);

  // State variables
  int  _navIndex     = 1;
  bool _loading      = true;
  bool _savingRole   = false;
  bool _deletingUser = false;
  String? _error;
  String _userInitials = '';

  // User data loaded from Supabase
  Map<String, dynamic>? _userData;

  // Mutable role — updated when returning from ChangePermissionsPage
  String _currentNivel     = '';
  String _currentAcessoDesc = '';

  @override
  void initState() {
    super.initState();
    _loadUserInitials();
    _loadUser();
  }

  // Load user initials from DB
  Future<void> _loadUserInitials() async {
    try {
      final user = db.auth.currentUser;
      if (user != null) {
        final res = await db
            .from('users')
            .select('name')
            .eq('id', user.id)
            .single();
        final name = res['name'] as String? ?? '';
        final initials = name
            .split(' ')
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join('');
        if (mounted) {
          setState(() => _userInitials = initials.isEmpty ? '?' : initials);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _userInitials = '?');
    }
  }

  // Load user data from Supabase
  Future<void> _loadUser() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await db
          .from('users')
          .select('id, name, email, role, nif, date_of_birth, phone, address, created_at, last_login')
          .eq('id', widget.userId)
          .isFilter('deleted_at', null)
          .single();

      if (!mounted) return;
      final data = Map<String, dynamic>.from(res as Map);
      setState(() {
        _userData         = data;
        _currentNivel     = _roleLabel(data['role'] as String);
        _currentAcessoDesc = _descForNivel(_roleLabel(data['role'] as String));
        _loading          = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Role helpers
  String _roleLabel(String role) {
    switch (role) {
      case 'doctor':       return 'Médico';
      case 'receptionist': return 'Receção';
      case 'admin':        return 'Admin';
      default:             return 'Paciente';
    }
  }


  String _descForNivel(String nivel) {
    switch (nivel) {
      case 'Médico':  return 'Acesso clínico';
      case 'Receção': return 'Acesso receção';
      case 'Admin':   return 'Acesso total';
      default:        return 'Acesso básico';
    }
  }

  // Format helpers
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
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
    const months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _loginLabel(String? isoDate) {
    if (isoDate == null) return 'Nunca';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '-';
    const months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  // Avatar colors
  Color _avatarBg(String nivel) {
    switch (nivel) {
      case 'Médico':  return const Color(0xFF64B5F6);
      case 'Receção': return const Color(0xCCBA7517);
      case 'Admin':   return const Color(0xCC6A9890);
      default:        return const Color(0xCC3DBDAD);
    }
  }

  Color _avatarText(String nivel) {
    switch (nivel) {
      case 'Médico':  return const Color(0xFF1A3B8B);
      case 'Receção': return const Color(0xFF7A5000);
      default:        return const Color(0xFF0F6E56);
    }
  }

  // Navigate back — return updated role to UsersListPage
  // Navigate back — return updated DB role to UsersListPage
  void _goBack() => Navigator.pop(context, {'role': _userData?['role'] ?? ''});

  // Change permissions
  Future<void> _goToChangePermissions() async {
    final u = _userData!;
    final newDbRole = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePermissionsPage(
          userInitials: _initials(u['name'] as String),
          userName:     u['name'] as String,
          userEmail:    u['email'] as String,
          userRole:     u['role'] as String, // DB role directly
        ),
      ),
    );

    if (newDbRole == null || newDbRole == u['role']) return;

    setState(() => _savingRole = true);
    try {
      await db
          .from('users')
          .update({'role': newDbRole})
          .eq('id', widget.userId);

      if (!mounted) return;
      setState(() {
        _userData!['role'] = newDbRole;
        _currentNivel      = _roleLabel(newDbRole);
        _currentAcessoDesc = _descForNivel(_roleLabel(newDbRole));
        _savingRole        = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingRole = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar permissão: $e')),
      );
    }
  }

  // Delete user
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Conta', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: _deleteRed)),
        content: Text(
          'Tem a certeza que pretende eliminar a conta de ${_userData!['name']}? Esta acção é irreversível.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: _primary)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteUser(); },
            child: const Text('Eliminar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: _deleteRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    setState(() => _deletingUser = true);
    try {
      await db
          .from('users')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', widget.userId);

      if (!mounted) return;
      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingUser = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao eliminar conta: $e')),
      );
    }
  }

  // Widget helpers
  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _sectionLabel)),
  );

  Widget _divider() => const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0ECEB));

  Widget _infoRow(String label, String value) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w300, color: _textMuted)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
          ],
        ),
      ),
      _divider(),
    ],
  );

  // Build
  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      userInitials: _userInitials,
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2)),
            )
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('Erro ao carregar perfil.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _loadUser,
                          child: const Text('Tentar novamente', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final u        = _userData!;
    final name     = u['name'] as String;
    final email    = u['email'] as String;
    final nif      = u['nif'] as String? ?? '-';
    final phone    = u['phone'] as String? ?? '-';
    final dob      = _formatDate(u['date_of_birth'] as String?);
    final registro = _sinceLabel(u['created_at'] as String?);
    final login    = _loginLabel(u['last_login'] as String?);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back link
        GestureDetector(
          onTap: _goBack,
          child: const Text(
            '< Voltar Atrás',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _accentDark, decoration: TextDecoration.underline, decorationColor: _accentDark),
          ),
        ),
        const SizedBox(height: 16),

        // Page title
        const Text('Perfil do Utilizador', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87)),
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
                width: 70, height: 70,
                decoration: BoxDecoration(color: _avatarBg(_currentNivel), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initials(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: _avatarText(_currentNivel))),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Opacity(opacity: 0.5, child: Text(email, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black87))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(75)),
                    child: Text(_currentNivel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w600, color: _primary)),
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
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -8)],
          ),
          child: Column(
            children: [
              _infoRow('NIF',        nif),
              _infoRow('Telefone',   phone),
              _infoRow('Data Nasc.', dob),
              _infoRow('Registro',   registro),
              // Last row — no divider after
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    const SizedBox(width: 90, child: Text('Último login', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w300, color: _textMuted))),
                    Expanded(child: Text(login, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Permissions section
        _sectionTitle('PERMISSÕES'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -8)],
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
                          const TextSpan(text: 'Nível:  ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                          TextSpan(text: _currentNivel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_currentAcessoDesc, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: _textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _savingRole ? null : _goToChangePermissions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: _savingRole ? _accentDark.withValues(alpha: 0.5) : _accentDark,
                    borderRadius: BorderRadius.circular(75),
                  ),
                  child: _savingRole
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Alterar', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Delete button
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
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _deleteRed))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, color: _deleteRed, size: 22),
                      SizedBox(width: 8),
                      Text('Eliminar Conta', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: _deleteRed)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}