import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_draft.dart';
import 'widgets/wizard_progress.dart';

class WizardTipoScreen extends StatelessWidget {
  const WizardTipoScreen({super.key});

  static const Color _orange = Color(0xFFFF6600);

  void _selecionarTipo(BuildContext context, String tipo) {
    final draft = RequerimentoDraft(tipo: tipo);

    Navigator.pushNamed(
      context,
      AppRoutes.wizardCategoria,
      arguments: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Novo Requerimento'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const WizardProgress(
              currentStep: 1,
              totalSteps: 6,
            ),
            const SizedBox(height: 28),
            const Text(
              'O que aconteceu no campus?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha abaixo se você perdeu ou encontrou um objeto.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _TipoCard(
              icon: Icons.search_rounded,
              title: 'Perdi um Objeto',
              subtitle: 'Não encontro um pertence meu na faculdade.',
              color: _orange,
              onTap: () => _selecionarTipo(context, 'PERDA'),
            ),
            const SizedBox(height: 16),
            _TipoCard(
              icon: Icons.pan_tool_alt_rounded,
              title: 'Encontrei um Objeto',
              subtitle: 'Achei um pertence perdido e quero entregar.',
              color: _orange,
              onTap: () => _selecionarTipo(context, 'ACHADO'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipoCard extends StatelessWidget {
  const _TipoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFFFD7BD),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}