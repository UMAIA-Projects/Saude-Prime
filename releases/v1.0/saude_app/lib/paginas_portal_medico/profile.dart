import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_fluxo_publico/login_page.dart';
import 'package:saude_app/paginas_fluxo_publico/change_password.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _notificacoesMarcacao = true;
  bool _alertasFila          = true;
  bool _notifDocumentos      = false;
  bool _modoEdicao           = false;

  // Editáveis
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactoCtrl;

  // Estatísticas mock
  static const int _consultasHoje    = 8;
  static const int _consultasSemana  = 34;
  static const int _pacientesAtivos  = 127;

  @override
  void initState() {
    super.initState();
    _nomeCtrl     = TextEditingController(text: 'Carlos Santos');
    _emailCtrl    = TextEditingController(text: 'carlos@saudeprime.pt');
    _contactoCtrl = TextEditingController(text: '220 000 000');
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
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF3DBDAD), fontWeight: FontWeight.w600)),
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
    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 4,
      onNavTap: (index) {
        if (index == 0) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardMedico()), (r) => false);
        if (index == 1) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Schedule()), (r) => false);
        if (index == 2) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const VirtualQueue()), (r) => false);
        if (index == 3) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Search()), (r) => false);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Avatar + info ────────────────────────────────────────────────
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF46AA9F),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF7CDACF), width: 3),
                    boxShadow: const [
                      BoxShadow(color: Color(0x2246AA9F), blurRadius: 20, offset: Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('CS',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                ),
                if (_modoEdicao)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DBDAD),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 13),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Nome ────────────────────────────────────────────────────────
          _modoEdicao
              ? SizedBox(
                  width: 200,
                  child: _CampoEdicao(
                    controller: _nomeCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: 'Poppins'),
                  ),
                )
              : Text(_nomeCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: 'Poppins', letterSpacing: -0.3)),

          const SizedBox(height: 3),

          // ── Email ───────────────────────────────────────────────────────
          _modoEdicao
              ? SizedBox(
                  width: 240,
                  child: _CampoEdicao(
                    controller: _emailCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6A9890), fontFamily: 'Poppins'),
                  ),
                )
              : Text(_emailCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6A9890), fontFamily: 'Poppins')),

          const SizedBox(height: 10),

          // ── Badges ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(label: 'Médico', bg: const Color(0xFF98D1FF), fg: const Color(0xFF1A3B8B)),
              const SizedBox(width: 8),
              _Badge(label: 'Clínica Geral', bg: const Color(0xFFD8F2EF), fg: const Color(0xFF1A6B62)),
            ],
          ),

          const SizedBox(height: 18),

          // ── Estatísticas ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                _StatCol(valor: '$_consultasHoje', label: 'Hoje'),
                _VertDivider(),
                _StatCol(valor: '$_consultasSemana', label: 'Esta semana'),
                _VertDivider(),
                _StatCol(valor: '$_pacientesAtivos', label: 'Pacientes'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Botão Editar / Guardar ──────────────────────────────────────
          GestureDetector(
            onTap: _toggleEdicao,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _modoEdicao ? const Color(0xFF3DBDAD) : Colors.white,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFF3DBDAD), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modoEdicao ? Icons.check_rounded : Icons.edit_outlined,
                    color: _modoEdicao ? Colors.white : const Color(0xFF3DBDAD),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _modoEdicao ? 'Guardar Alterações' : 'Editar Perfil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _modoEdicao ? Colors.white : const Color(0xFF3DBDAD),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── Dados Pessoais (editáveis) ──────────────────────────────────
          const _SecaoTitulo(label: 'DADOS PESSOAIS'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                _DadoRow(label: 'Nome', controller: _nomeCtrl, modoEdicao: _modoEdicao, editavel: true),
                const _Divider(),
                _DadoRow(label: 'Email', controller: _emailCtrl, modoEdicao: _modoEdicao, editavel: true),
                const _Divider(),
                _DadoRow(label: 'Contacto', controller: _contactoCtrl, modoEdicao: _modoEdicao, editavel: true),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Dados Profissionais (só leitura) ────────────────────────────
          const _SecaoTitulo(label: 'DADOS PROFISSIONAIS'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                _DadoTexto(label: 'Especialidade', valor: 'Clínica Geral'),
                const _Divider(),
                _DadoTexto(label: 'Nº Licença', valor: '12345-OM'),
                const _Divider(),
                _DadoTexto(label: 'Instituição', valor: 'Centro de Saúde Lisboa'),
                const _Divider(),
                _DadoTexto(label: 'Cédula', valor: 'PT-2019-CG-007'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Notificações ────────────────────────────────────────────────
          const _SecaoTitulo(label: 'NOTIFICAÇÕES'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                _ToggleRow(label: 'Notificações de Marcação', value: _notificacoesMarcacao,
                    onChanged: (v) => setState(() => _notificacoesMarcacao = v)),
                const _Divider(),
                _ToggleRow(label: 'Alertas de Fila', value: _alertasFila,
                    onChanged: (v) => setState(() => _alertasFila = v)),
                const _Divider(),
                _ToggleRow(label: 'Novos Documentos', value: _notifDocumentos,
                    onChanged: (v) => setState(() => _notifDocumentos = v)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Segurança ───────────────────────────────────────────────────
          const _SecaoTitulo(label: 'SEGURANÇA'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: _AcaoRow(icon: Icons.lock_outline, label: 'Alterar Palavra-Passe', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword()));
            }),
          ),

          const SizedBox(height: 22),

          // ── Terminar Sessão ─────────────────────────────────────────────
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
                  Text('Terminar Sessão',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC62828), fontFamily: 'Poppins')),
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(25)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, fontFamily: 'Poppins', letterSpacing: 0.2)),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String valor, label;
  const _StatCol({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A8070), fontFamily: 'Poppins', height: 1)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.45), fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String label;
  const _SecaoTitulo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3DBDAD), fontFamily: 'Poppins', letterSpacing: 1.1)),
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
        border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3DBDAD), width: 1.2)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3DBDAD), width: 1.8)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB2DFDB), width: 1.0)),
      ),
    );
  }
}

// Campo editável (nome, email, contacto)
class _DadoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modoEdicao;
  final bool editavel;
  const _DadoRow({required this.label, required this.controller, required this.modoEdicao, this.editavel = true});

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
            child: (editavel && modoEdicao)
                ? _CampoEdicao(controller: controller,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins'))
                : Text(controller.text,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins')),
          ),
          if (editavel && modoEdicao)
            const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF3DBDAD)),
        ],
      ),
    );
  }
}

// Campo só leitura (especialidade, licença...)
class _DadoTexto extends StatelessWidget {
  final String label, valor;
  const _DadoTexto({required this.label, required this.valor});

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
            child: Text(valor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins')),
          ),
          const Icon(Icons.lock_outline, size: 14, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}

class _AcaoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AcaoRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3DBDAD), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins')),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.25), size: 22),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Poppins')),
          ),
          Transform.scale(
            scale: 0.80,
            child: Switch(
              value: value, onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF3DBDAD),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
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
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1, indent: 20, endIndent: 20);
  }
}