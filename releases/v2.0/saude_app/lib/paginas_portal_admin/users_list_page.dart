import 'package:saude_app/paginas_portal_admin/portal_admin.dart';


class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  // Color palette
  static const Color _primary = Color(0xFF1A8070);
  static const Color _pink    = Color(0xFFD4537E);

  // State
  int    _navIndex  = 1;
  int    _activeTab = 0;
  String _pesquisa  = '';
  bool   _loading   = true;
  String? _error;
  String _userInitials = '';

  final List<String> _tabs = ['Todos', 'Pacientes', 'Médicos', 'Admins'];

  // Lista mutável — pode ser alterada por delete / role change
  List<Map<String, dynamic>> _users = [];

  // Lifecycle
  @override
  void initState() {
    super.initState();
    _loadUserInitials();
    _loadUsers();
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

  // Data loading

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Busca todos os utilizadores activos (sem deleted_at)
      // Campos: id, name, email, role, nif, date_of_birth, created_at, last_login
      final res = await db
          .from('users')
          .select('id, name, email, role, nif, date_of_birth, created_at, last_login')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _users  = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Helpers

  // Converte role da BD ('patient', 'doctor'...) para label PT
  String _roleLabel(String role) {
    switch (role) {
      case 'doctor':       return 'Médico';
      case 'receptionist': return 'Receção';
      case 'admin':        return 'Admin';
      default:             return 'Paciente';
    }
  }


  // Iniciais a partir do nome completo
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  // "Jan 2025" a partir de created_at ISO
  String _sinceLabel(String? isoDate) {
    if (isoDate == null) return '-';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '-';
    const months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'doctor':       return const Color(0xFF1A3B8B);
      case 'receptionist': return const Color(0xFFBA7517);
      case 'admin':        return _pink;
      default:             return _primary;
    }
  }

  Color _avatarBg(String role) {
    switch (role) {
      case 'doctor':       return const Color(0xFF64B5F6);
      case 'receptionist': return const Color(0xCCBA7517);
      case 'admin':        return const Color(0xCC6A9890);
      default:             return const Color(0xCC3DBDAD);
    }
  }

  Color _avatarText(String role) {
    switch (role) {
      case 'doctor':       return const Color(0xFF1A3B8B);
      case 'receptionist': return const Color(0xFF7A5000);
      default:             return const Color(0xFF0F6E56);
    }
  }

  // Navegação para UserProfilePage

  Future<void> _openProfile(Map<String, dynamic> u) async {

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userId: u['id'] as String),
      )
    );

    if (result == null || !mounted) return;

    setState(() {
      final idx = _users.indexWhere((user) => user['id'] == u['id']);
      if (idx == -1) return;

      if (result['deleted'] == true) {
        _users.removeAt(idx);
        return;
      }

      // Role alterado — actualiza localmente sem recarregar tudo
      final newRole = result['role'] as String?;
      if (newRole != null && newRole != _users[idx]['role']) {
        _users[idx] = { ..._users[idx], 'role': newRole };
      }
    });
  }

  // Delete local

  Future<void> _deleteUser(Map<String, dynamic> u) async {
    try {
      await db
          .from('users')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', u['id'] as String);

      if (!mounted) return;
      setState(() => _users.removeWhere((user) => user['id'] == u['id']));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao eliminar: $e')),
      );
    }
  }

  // Filter

  List<Map<String, dynamic>> get _filteredUsers {
    final roleFilter = _tabs[_activeTab];
    return _users.where((u) {
      final role = u['role'] as String;
      final matchRole = roleFilter == 'Todos' ||
          (roleFilter == 'Pacientes' && role == 'patient') ||
          (roleFilter == 'Médicos'   && role == 'doctor')  ||
          (roleFilter == 'Admins'    && role == 'admin');
      final name  = (u['name']  as String).toLowerCase();
      final email = (u['email'] as String).toLowerCase();
      final matchSearch = _pesquisa.isEmpty ||
          name.contains(_pesquisa.toLowerCase()) ||
          email.contains(_pesquisa.toLowerCase());
      return matchRole && matchSearch;
    }).toList();
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      userInitials: _userInitials,
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + New button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Utilizadores',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewUserPage()),
                ).then((_) => _loadUsers()), // recarrega ao voltar
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pink,
                    borderRadius: BorderRadius.circular(75),
                  ),
                  child: const Text(
                    '+ Novo',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _pink, width: 1.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black38, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _pesquisa = v),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar por nome ou email...',
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tab filter
          Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = i == _activeTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? _pink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? _pink : Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Content
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A8070), strokeWidth: 2),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Erro ao carregar utilizadores.',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _loadUsers,
                      child: const Text(
                        'Tentar novamente',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A8070),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Nenhum utilizador encontrado.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38),
                ),
              ),
            )
          else
            ..._filteredUsers.map((u) {
              final role    = u['role'] as String;
              final isAdmin = role == 'admin';
              final label   = _roleLabel(role);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _avatarBg(role),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(u['name'] as String),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _avatarText(role),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Name, role badge, email + since
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      u['name'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _roleColor(role),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${u['email']} - ${_sinceLabel(u['created_at'] as String?)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            _ActionBtn(
                              label: 'Ver',
                              onTap: () => _openProfile(u),
                            ),
                            const SizedBox(width: 4),
                            _ActionBtn(
                              icon: Icons.settings_outlined,
                              onTap: () {
                                // TODO: user settings
                              },
                            ),
                            if (!isAdmin) ...[
                              const SizedBox(width: 4),
                              _ActionBtn(
                                icon: Icons.delete_outline,
                                bgColor: const Color(0xFFD9D9D9),
                                onTap: () => _deleteUser(u),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x80B1B1B1)),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// Reusable small action button
class _ActionBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionBtn({
    this.label,
    this.icon,
    this.bgColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 26,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFB1B1B1), width: 1.2),
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(
                label!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.black54,
                ),
              )
            : Icon(icon, size: 15, color: Colors.black54),
      ),
    );
  }
}