import 'package:flutter/material.dart';
import 'template/template_portal_admin.dart';
import 'package:saude_app/paginas_fluxo_publico/login_page.dart';
//import 'package:saude_app/paginas_fluxo_publico/change_password.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Color palette
  static const Color _accent      = Color(0xFF3DBDAD);
  static const Color _accentLight = Color(0xFF7CDACF);
  static const Color _pink        = Color(0xFFD4537E);
  static const Color _pinkLight   = Color(0xFFE598B2);

  int _navIndex = 4;

  // Toggle state
  bool _notifSistema   = true;
  bool _relatoriosAuto = false;

  // Edit mode
  bool _modoEdicao = false;

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactoCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl     = TextEditingController(text: 'Paula Rita');
    _emailCtrl    = TextEditingController(text: 'paularita@gmail.com');
    _contactoCtrl = TextEditingController(text: '220 000 001');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  void _toggleEdicao() => setState(() => _modoEdicao = !_modoEdicao);

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terminar Sessão',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Tem a certeza que pretende sair?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
              style: TextStyle(fontFamily: 'Poppins', color: _accent, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            child: const Text('Sair',
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFC62828), fontWeight: FontWeight.w700)),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // Avatar
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 93,
                  height: 93,
                  decoration: BoxDecoration(
                    color: _pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _pinkLight, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33D4537E), blurRadius: 20, offset: Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'PR',
                    style: TextStyle(
                      fontSize: 37, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins', height: 1,
                    ),
                  ),
                ),
                if (_modoEdicao)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Name
          _modoEdicao
              ? SizedBox(
                  width: 200,
                  child: _CampoEdicao(
                    controller: _nomeCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: 'Poppins'),
                  ),
                )
              : Text(
                  _nomeCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: 'Poppins'),
                ),

          const SizedBox(height: 3),

          // Email
          _modoEdicao
              ? SizedBox(
                  width: 240,
                  child: _CampoEdicao(
                    controller: _emailCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6A9890), fontFamily: 'Poppins'),
                  ),
                )
              : Opacity(
                  opacity: 0.6,
                  child: Text(
                    _emailCtrl.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black, fontFamily: 'Poppins'),
                  ),
                ),

          const SizedBox(height: 10),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: _pink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Administrador',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
            ),
          ),

          const SizedBox(height: 18),

          // Edit / Save Button
          GestureDetector(
            onTap: _toggleEdicao,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _modoEdicao ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: _accentLight, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modoEdicao ? Icons.check_rounded : Icons.edit_outlined,
                    color: _modoEdicao ? Colors.white : _accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _modoEdicao ? 'Guardar Alterações' : 'Editar Perfil',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _modoEdicao ? Colors.white : _accent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Personal Information
          const _SecaoTitulo(label: 'DADOS PESSOAIS'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                _DadoRow(label: 'Nome',     controller: _nomeCtrl,     modoEdicao: _modoEdicao),
                const _Divider(),
                _DadoRow(label: 'Email',    controller: _emailCtrl,    modoEdicao: _modoEdicao),
                const _Divider(),
                _DadoRow(label: 'Contacto', controller: _contactoCtrl, modoEdicao: _modoEdicao),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // System Administration
          const _SecaoTitulo(label: 'ADMINISTRAÇÃO DO SISTEMA'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                _AcaoRow(label: 'Logs de Auditoria',       onTap: () { /* TODO */ }),
                const _Divider(),
                _AcaoRow(label: 'Configurar Fila Virtual',  onTap: () { /* TODO */ }),
                const _Divider(),
                _AcaoRow(label: 'Configurar Newsletter',    onTap: () { /* TODO */ }),
                const _Divider(),
                _AcaoRow(label: 'Dados da Clínica',         onTap: () { /* TODO */ }),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Notifications
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Notificações do Sistema',
                  value: _notifSistema,
                  onChanged: (v) => setState(() => _notifSistema = v),
                ),
                const _Divider(),
                _ToggleRow(
                  label: 'Relatórios Automáticos',
                  value: _relatoriosAuto,
                  onChanged: (v) => setState(() => _relatoriosAuto = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Security
          const _SecaoTitulo(label: 'SEGURANÇA'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 2))],
            ),
            child: _AcaoRow(
              label: 'Alterar Password',
              icon: Icons.lock_outline,
              onTap: () {
                //Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePassword()));
              },
            ),
          ),

          const SizedBox(height: 22),

          // Logout Button
          GestureDetector(
            onTap: _confirmarLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_outlined, color: Color(0xFFC62828), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Terminar Sessão',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC62828), fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Auxiliary Widgets
class _SecaoTitulo extends StatelessWidget {
  final String label;
  const _SecaoTitulo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: Color(0xFF1A8070), fontFamily: 'Poppins', letterSpacing: 1.1,
        )),
    );
  }
}

class _CampoEdicao extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle style;
  final TextAlign textAlign;
  const _CampoEdicao({required this.controller, required this.style, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      style: style,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        border:        UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3DBDAD), width: 1.2)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3DBDAD), width: 1.8)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB2DFDB), width: 1.0)),
      ),
    );
  }
}

class _DadoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modoEdicao;
  const _DadoRow({required this.label, required this.controller, required this.modoEdicao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8AADA8), fontFamily: 'Poppins')),
          ),
          Expanded(
            child: modoEdicao
                ? _CampoEdicao(
                    controller: controller,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins'),
                  )
                : Text(controller.text,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins')),
          ),
          if (modoEdicao)
            const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF3DBDAD)),
        ],
      ),
    );
  }
}

class _AcaoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AcaoRow({this.icon = Icons.circle, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isCircleDot = icon == Icons.circle;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            isCircleDot
                ? Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7CDACF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF46AA9F), width: 1),
                    ),
                  )
                : Icon(icon, color: const Color(0xFF3DBDAD), size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'Poppins')),
            ),
            Icon(Icons.chevron_right, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'Poppins')),
          ),
          Transform.scale(
            scale: 0.80,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF3DBDAD),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD0D0D0),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1, indent: 20, endIndent: 20);
}