import 'package:flutter/material.dart';
import 'package:saude_app/paginas_fluxo_publico/template/template_fluxo_publico.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  late final TextEditingController _atualCtrl;
  late final TextEditingController _novaCtrl;
  bool _obscureAtual = true;
  bool _obscureNova  = true;

  @override
  void initState() {
    super.initState();
    _atualCtrl = TextEditingController();
    _novaCtrl  = TextEditingController();
  }

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 32),

            // ── Voltar ───────────────────────────────────────────────────
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

            const SizedBox(height: 24),

            // ── Título ───────────────────────────────────────────────────
            const Text(
              'Alterar\nPalavra-Passe',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Poppins',
                height: 1.1,
              ),
            ),

            const SizedBox(height: 36),

            // ── Campo: Palavra-passe Atual ────────────────────────────────
            const Text(
              'Palavra-passe Atual',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            _CampoPassword(
              controller: _atualCtrl,
              obscure: _obscureAtual,
              onToggle: () => setState(() => _obscureAtual = !_obscureAtual),
            ),

            const SizedBox(height: 24),

            // ── Campo: Nova Palavra-passe ─────────────────────────────────
            const Text(
              'Nova Palavra-passe',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            _CampoPassword(
              controller: _novaCtrl,
              obscure: _obscureNova,
              onToggle: () => setState(() => _obscureNova = !_obscureNova),
            ),

            const SizedBox(height: 40),

            // ── Botão Alterar ─────────────────────────────────────────────
            GestureDetector(
              onTap: () {/* TODO: lógica de alterar password */},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF64D68A),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3364D68A),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Alterar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de password com toggle visibilidade
// ─────────────────────────────────────────────────────────────────────────────

class _CampoPassword extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _CampoPassword({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: Colors.black,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64D68A), size: 20),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.black26,
            size: 20,
          ),
        ),
        hintText: '••••••••••••••••••',
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.30),
          fontFamily: 'Poppins',
          letterSpacing: 2,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF64D68A), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF64D68A), width: 2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}