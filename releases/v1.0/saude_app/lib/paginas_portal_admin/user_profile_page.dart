import 'package:flutter/material.dart';
import 'template/template_portal_admin.dart';
import 'change_permissions_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userInitials;
  final String userName;
  final String userEmail;
  final String userNif;
  final String userDataNasc;
  final String userRegistro;
  final String userUltimoLogin;
  final String userNivel;
  final String userAcessoDesc;

  const UserProfilePage({
    super.key,
    this.userInitials    = 'AO',
    this.userName        = 'Aníbal Oliveira',
    this.userEmail       = 'anibal@gmail.com',
    this.userNif         = '222 222 222',
    this.userDataNasc    = '01/01/1990',
    this.userRegistro    = '01 Jan 2025',
    this.userUltimoLogin = '01 Jan 2025',
    this.userNivel       = 'Paciente',
    this.userAcessoDesc  = 'Acesso básico',
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

  int _navIndex = 1;

  // Mutable nivel/desc — updated when returning from ChangePermissionsPage
  late String _currentNivel;
  late String _currentAcessoDesc;

  @override
  void initState() {
    super.initState();
    _currentNivel      = widget.userNivel;
    _currentAcessoDesc = widget.userAcessoDesc;
  }

  String _descForNivel(String nivel) {
    switch (nivel) {
      case 'Médico':  return 'Acesso clínico';
      case 'Receção': return 'Acesso receção';
      case 'Admin':   return 'Acesso total';
      default:        return 'Acesso básico';
    }
  }

  // Avatar colors — matches UsersListPage logic
  static Color _avatarBgForRole(String role) {
    switch (role) {
      case 'Médico':  return const Color(0xFF64B5F6);
      case 'Receção': return const Color(0xCCBA7517);
      case 'Admin':   return const Color(0xCC6A9890);
      default:        return const Color(0xCC3DBDAD);
    }
  }

  static Color _avatarTextForRole(String role) {
    switch (role) {
      case 'Médico':  return const Color(0xFF1A3B8B);
      case 'Receção': return const Color(0xFF7A5000);
      default:        return const Color(0xFF0F6E56);
    }
  }

  // Open ChangePermissionsPage, await new nivel, update state + propagate back
  Future<void> _goToChangePermissions() async {
    final newNivel = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePermissionsPage(
          userInitials: widget.userInitials,
          userName:     widget.userName,
          userEmail:    widget.userEmail,
          userNivel:    _currentNivel,
        ),
      ),
    );

    if (newNivel != null && newNivel != _currentNivel) {
      setState(() {
        _currentNivel      = newNivel;
        _currentAcessoDesc = _descForNivel(newNivel);
      });
    }
  }

  // Pop back to UsersListPage carrying the current (possibly updated) role.
  // UsersListPage uses this to update its local list without a full rebuild.
  void _goBack() {
    Navigator.pop(context, {'role': _currentNivel});
  }

  // Helpers
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

  Widget _divider() => const Divider(
    height: 1,
    indent: 12,
    endIndent: 12,
    color: Color(0xFFE0ECEB),
  );

  Widget _infoRow(String label, String value) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 90,
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
      _divider(),
    ],
  );

  void _confirmDelete(BuildContext context) {
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
          'Tem a certeza que pretende eliminar a conta de ${widget.userName}? Esta acção é irreversível.',
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
              // Close the dialog, then pop the profile page with deleted=true.
              // UsersListPage receives this and removes the user from its list.
              Navigator.pop(context);
              Navigator.pop(context, {'deleted': true});
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

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back link — pops with current role so list stays in sync
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
          const SizedBox(height: 16),

          // Page title
          const Text(
            'Perfil do Utilizador',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
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
                    color: _avatarBgForRole(_currentNivel),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.userInitials,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _avatarTextForRole(_currentNivel),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
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
                        widget.userEmail,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                _infoRow('NIF',        widget.userNif),
                _infoRow('Data Nasc.', widget.userDataNasc),
                _infoRow('Registro',   widget.userRegistro),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 90,
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
                          widget.userUltimoLogin,
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

          // Permissions section
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
                  onTap: _goToChangePermissions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accentDark,
                      borderRadius: BorderRadius.circular(75),
                    ),
                    child: const Text(
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

          // Delete account button
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _deleteBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _accentLight, width: 1),
              ),
              alignment: Alignment.center,
              child: const Row(
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
      ),
    );
  }
}