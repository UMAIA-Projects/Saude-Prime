import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'template/template_portal_paciente.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════

const Color _kPrimary      = Color(0xFF1A8070);
const Color _kSubtitle     = Color(0xFF6A9890);
const Color _kCardBg       = Colors.white;
const Color _kSenhaBg      = Color(0x233DBDAD);
const Color _kSenhaBorder  = Color(0x473DBDAD);

const TextStyle _kSectionTitle = TextStyle(
  color: _kPrimary,
  fontSize: 12,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
);

const TextStyle _kSubtitleStyle = TextStyle(
  color: _kSubtitle,
  fontSize: 12,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w400,
);

// ═══════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 0, // Home ativo na nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _DashboardHeader(),
          SizedBox(height: 20),
          _ProximaConsulta(),
          SizedBox(height: 20),
          _TuaSenha(),
          SizedBox(height: 20),
          _AcessoRapido(),
          SizedBox(height: 20),
          _NotificacoesRecentes(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER — Saudação e data
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Olá, Ricardo!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text('Terça, 31 de Março 2026', style: _kSubtitleStyle),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRÓXIMA CONSULTA
// ═══════════════════════════════════════════════════════════════════════════

class _ProximaConsulta extends StatelessWidget {
  const _ProximaConsulta();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRÓXIMA CONSULTA', style: _kSectionTitle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: _kPrimary, width: 4),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Qui, 3 Abr • 14:30',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusBadge(
                    label: 'Agendada',
                    bgColor: Color(0xFFD5EAFF),
                    textColor: Color(0xFF1A3B8B),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Dr. Carlos Menezes • Clínica Geral',
                style: _kSubtitleStyle,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LinkText(label: 'Ver detalhes', onTap: () {}),
                  const SizedBox(width: 16),
                  _LinkText(label: 'Desmarcar consulta', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// A TUA SENHA
// ═══════════════════════════════════════════════════════════════════════════

class _TuaSenha extends StatelessWidget {
  const _TuaSenha();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('A TUA SENHA', style: _kSectionTitle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kSenhaBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kSenhaBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A-67',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 28,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const _StatusBadge(
                    label: 'À espera',
                    bgColor: Color(0xFFFFFAD5),
                    textColor: Color(0xFF6B5A00),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('A ser atendido: A-60', style: _kSubtitleStyle),
              const SizedBox(height: 2),
              const Text('~12 min • 7 à frente', style: _kSubtitleStyle),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACESSO RÁPIDO
// ═══════════════════════════════════════════════════════════════════════════

class _AcessoRapido extends StatelessWidget {
  const _AcessoRapido();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACESSO RÁPIDO', style: _kSectionTitle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                svgAsset: 'assets/imagens_portal_paciente/calendar.svg',
                label: 'Marcar Consulta',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                svgAsset: 'assets/imagens_portal_paciente/documents.svg',
                label: 'Consultar Documentos',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                // Substituir pelo SVG correto quando disponível nos assets
                fallbackIcon: Icons.menu_book_outlined,
                label: 'Histórico Clínico',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                // Substituir pelo SVG correto quando disponível nos assets
                fallbackIcon: Icons.notifications_outlined,
                label: 'Notificações',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICAÇÕES RECENTES
// ═══════════════════════════════════════════════════════════════════════════

class _NotificacoesRecentes extends StatelessWidget {
  const _NotificacoesRecentes();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NOTIFICAÇÕES RECENTES', style: _kSectionTitle),
        const SizedBox(height: 10),
        const _NotificacaoItem(
          texto: 'Novo resultado de análise disponível.',
          tempo: '5h',
        ),
        const Divider(color: _kPrimary, thickness: 0.5, height: 16),
        _NotificacaoItem(
          tempo: '2d',
          textoRich: TextSpan(
            style: _kSubtitleStyle,
            children: [
              const TextSpan(text: 'Promoção nova! Usa o código '),
              TextSpan(
                text: 'SIXSEVEN',
                style: _kSubtitleStyle.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: _kSubtitle,
                ),
              ),
              const TextSpan(text: ' para...'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Badge de estado (ex: "Agendada", "À espera")
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Texto com underline e ação de toque
class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: _kPrimary,
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: _kPrimary,
        ),
      ),
    );
  }
}

/// Card do Acesso Rápido — aceita SVG ou ícone Material como fallback
class _QuickAccessCard extends StatelessWidget {
  final String? svgAsset;
  final IconData? fallbackIcon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessCard({
    this.svgAsset,
    this.fallbackIcon,
    required this.label,
    required this.onTap,
  }) : assert(svgAsset != null || fallbackIcon != null,
            'Fornece svgAsset ou fallbackIcon');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 2),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: 34,
                height: 34,
                colorFilter: const ColorFilter.mode(_kPrimary, BlendMode.srcIn),
              )
            else
              Icon(fallbackIcon, color: _kPrimary, size: 34),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de notificação com bullet point teal
class _NotificacaoItem extends StatelessWidget {
  final String? texto;
  final TextSpan? textoRich;
  final String tempo;

  const _NotificacaoItem({
    this.texto,
    this.textoRich,
    required this.tempo,
  }) : assert(texto != null || textoRich != null,
            'Fornece texto ou textoRich');

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bullet point
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Texto (expansível)
        Expanded(
          child: textoRich != null
              ? Text.rich(textoRich!)
              : Text(texto!, style: _kSubtitleStyle),
        ),
        const SizedBox(width: 8),
        // Timestamp
        Text(tempo, style: _kSubtitleStyle),
      ],
    );
  }
}