import 'package:flutter/material.dart';
import 'template/template_portal_admin.dart';
import 'user_profile_page.dart';

class UsersListPage extends StatefulWidget {
  final String? deletedUserEmail;

  const UsersListPage({super.key, this.deletedUserEmail});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  // Color palette
  static const Color _primary = Color(0xFF1A8070);
  static const Color _pink    = Color(0xFFD4537E);

  // State variables
  int    _navIndex  = 1;
  int    _activeTab = 0;
  String _pesquisa  = '';

  // Tab labels
  final List<String> _tabs = ['Todos', 'Pacientes', 'Médicos', 'Admins'];

  // Role colors and avatar colors
  Color _roleColor(String role) {
    switch (role) {
      case 'Médico':   return const Color(0xFF1A3B8B);
      case 'Receção':  return const Color(0xFFBA7517);
      case 'Admin':    return _pink;
      default:         return _primary;
    }
  }

  Color _avatarBg(String role) {
    switch (role) {
      case 'Médico':   return const Color(0xFF64B5F6);
      case 'Receção':  return const Color(0xCCBA7517);
      case 'Admin':    return const Color(0xCC6A9890);
      default:         return const Color(0xCC3DBDAD);
    }
  }

  Color _avatarText(String role) {
    switch (role) {
      case 'Médico':   return const Color(0xFF1A3B8B);
      case 'Receção':  return const Color(0xFF7A5000);
      default:         return const Color(0xFF0F6E56);
    }
  }

  String _descForRole(String role) {
    switch (role) {
      case 'Médico':  return 'Acesso clínico';
      case 'Receção': return 'Acesso receção';
      case 'Admin':   return 'Acesso total';
      default:        return 'Acesso básico';
    }
  }

  // Users data — includes all fields required by UserProfilePage
  late final List<Map<String, String>> _users;

  @override
  void initState() {
    super.initState();
    final allUsers = [
      {
        'initials':    'AO',
        'name':        'Aníbal Oliveira',
        'role':        'Paciente',
        'email':       'anibal@gmail.com',
        'since':       'Jan 2025',
        'nif':         '222 222 222',
        'dataNasc':    '01/01/1990',
        'registro':    '01 Jan 2025',
        'ultimoLogin': '01 Jan 2025',
        'acessoDesc':  'Acesso básico',
      },
      {
        'initials':    'CS',
        'name':        'Dr. Carlos Santos',
        'role':        'Médico',
        'email':       'carlos@gmail.com',
        'since':       'Set 2023',
        'nif':         '333 333 333',
        'dataNasc':    '15/06/1975',
        'registro':    '01 Set 2023',
        'ultimoLogin': '20 Abr 2026',
        'acessoDesc':  'Acesso clínico',
      },
      {
        'initials':    'MC',
        'name':        'Maria Costa',
        'role':        'Receção',
        'email':       'maria@gmail.com',
        'since':       'Mar 2024',
        'nif':         '444 444 444',
        'dataNasc':    '22/03/1988',
        'registro':    '01 Mar 2024',
        'ultimoLogin': '25 Abr 2026',
        'acessoDesc':  'Acesso receção',
      },
      {
        'initials':    'JP',
        'name':        'João Pinto',
        'role':        'Admin',
        'email':       'joao@gmail.com',
        'since':       'Jan 2023',
        'nif':         '555 555 555',
        'dataNasc':    '10/11/1982',
        'registro':    '01 Jan 2023',
        'ultimoLogin': '26 Abr 2026',
        'acessoDesc':  'Acesso total',
      },
      {
        'initials':    'AS',
        'name':        'Ana Souza',
        'role':        'Paciente',
        'email':       'ana@gmail.com',
        'since':       'Fev 2025',
        'nif':         '666 666 666',
        'dataNasc':    '05/07/1995',
        'registro':    '01 Fev 2025',
        'ultimoLogin': '10 Abr 2026',
        'acessoDesc':  'Acesso básico',
      },
      {
        'initials':    'LR',
        'name':        'Luís Rodrigues',
        'role':        'Médico',
        'email':       'luis@gmail.com',
        'since':       'Out 2022',
        'nif':         '777 777 777',
        'dataNasc':    '30/09/1970',
        'registro':    '01 Out 2022',
        'ultimoLogin': '22 Abr 2026',
        'acessoDesc':  'Acesso clínico',
      },
    ];

    _users = allUsers
        .where((u) => u['email'] != widget.deletedUserEmail)
        .toList();
  }

  // Navigate to UserProfilePage and await result {role, deleted}
  Future<void> _openProfile(Map<String, String> u) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          userInitials:    u['initials']!,
          userName:        u['name']!,
          userEmail:       u['email']!,
          userNif:         u['nif']!,
          userDataNasc:    u['dataNasc']!,
          userRegistro:    u['registro']!,
          userUltimoLogin: u['ultimoLogin']!,
          userNivel:       u['role']!,
          userAcessoDesc:  u['acessoDesc']!,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final idx = _users.indexWhere((user) => user['email'] == u['email']);
      if (idx == -1) return;

      // User was deleted from profile page
      if (result['deleted'] == true) {
        _users.removeAt(idx);
        return;
      }

      // Role was changed — update role and acessoDesc in list
      final newRole = result['role'] as String?;
      if (newRole != null && newRole != _users[idx]['role']) {
        _users[idx] = {
          ..._users[idx],
          'role':       newRole,
          'acessoDesc': _descForRole(newRole),
        };
      }
    });
  }

  // Filtered users based on tab and search
  List<Map<String, String>> get _filteredUsers {
    final roleFilter = _tabs[_activeTab];
    return _users.where((u) {
      final matchRole = roleFilter == 'Todos' ||
          (roleFilter == 'Pacientes' && u['role'] == 'Paciente') ||
          (roleFilter == 'Médicos'   && u['role'] == 'Médico')   ||
          (roleFilter == 'Admins'    && u['role'] == 'Admin');
      final matchSearch = _pesquisa.isEmpty ||
          u['name']!.toLowerCase().contains(_pesquisa.toLowerCase()) ||
          u['email']!.toLowerCase().contains(_pesquisa.toLowerCase());
      return matchRole && matchSearch;
    }).toList();
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return TemplatePortalAdmin(
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
                onTap: () {
                  // TODO: navigate to create user page
                },
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
              border: Border(
                bottom: BorderSide(color: _pink, width: 1.5),
              ),
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

          // Users list
          if (users.isEmpty)
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
            ...users.map((u) {
              final isAdmin = u['role'] == 'Admin';
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
                            color: _avatarBg(u['role']!),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            u['initials']!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _avatarText(u['role']!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Name, role, email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    u['name']!,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    u['role']!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _roleColor(u['role']!),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${u['email']} - ${u['since']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action buttons: Ver + Settings + (Delete if not Admin)
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
                                // TODO: navigate to user settings
                              },
                            ),
                            if (!isAdmin) ...[
                              const SizedBox(width: 4),
                              _ActionBtn(
                                icon: Icons.delete_outline,
                                bgColor: const Color(0xFFD9D9D9),
                                onTap: () {
                                  setState(() {
                                    _users.removeWhere((user) => user['email'] == u['email']);
                                  });
                                },
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