import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_draft.dart';
import '../../../data/repositories/requerimento_repository.dart';
import 'widgets/wizard_progress.dart';

class WizardRevisaoScreen extends StatefulWidget {
  const WizardRevisaoScreen({super.key});

  @override
  State<WizardRevisaoScreen> createState() => _WizardRevisaoScreenState();
}

class _WizardRevisaoScreenState extends State<WizardRevisaoScreen> {
  static const Color _orange = Color(0xFFFF6600);

  final RequerimentoRepository _repository = RequerimentoRepository();

  bool _enviando = false;

  RequerimentoDraft _draftFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoDraft) {
      return args;
    }

    return RequerimentoDraft();
  }

  Widget _buildFotoPreview(String caminho) {
    if (kIsWeb) {
      return Image.network(
        caminho,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(caminho),
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Future<void> _confirmarEnvio() async {
    if (_enviando) return;

    final draft = _draftFromArgs(context);

    setState(() {
      _enviando = true;
    });

    try {
      await _repository.criarRequerimento(draft).timeout(
            const Duration(seconds: 20),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFFF6600),
          content: Text('Requerimento criado com sucesso!'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftFromArgs(context);

    final dataHora = draft.dataHoraOcorrencia == null
        ? 'Não informada'
        : DateFormat('dd/MM/yyyy HH:mm').format(draft.dataHoraOcorrencia!);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Revisão'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                const WizardProgress(
                  currentStep: 6,
                  totalSteps: 6,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Revise os dados',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirme se as informações estão corretas antes de abrir o requerimento.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (draft.caminhoFotoLocal != null &&
                    draft.caminhoFotoLocal!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildFotoPreview(draft.caminhoFotoLocal!),
                  ),
                const SizedBox(height: 18),
                _InfoCard(
                  title: 'Tipo de fluxo',
                  value: draft.tipo == 'PERDA'
                      ? 'Perdi um objeto'
                      : 'Encontrei um objeto',
                  icon: Icons.compare_arrows_rounded,
                  onEdit: () => Navigator.popUntil(
                    context,
                    ModalRoute.withName(AppRoutes.wizardTipo),
                  ),
                ),
                _InfoCard(
                  title: 'Categoria',
                  value: draft.categoria ?? 'Não informada',
                  icon: Icons.category_outlined,
                  onEdit: () => Navigator.popUntil(
                    context,
                    ModalRoute.withName(AppRoutes.wizardCategoria),
                  ),
                ),
                _InfoCard(
                  title: 'Localização',
                  value: draft.localOcorrencia ?? 'Não informada',
                  icon: Icons.location_on_outlined,
                  onEdit: () => Navigator.popUntil(
                    context,
                    ModalRoute.withName(AppRoutes.wizardLocal),
                  ),
                ),
                _InfoCard(
                  title: 'Data e hora',
                  value: dataHora,
                  icon: Icons.access_time_rounded,
                  onEdit: () => Navigator.popUntil(
                    context,
                    ModalRoute.withName(AppRoutes.wizardDataHora),
                  ),
                ),
                _InfoCard(
                  title: 'Características',
                  value:
                      'Cor: ${draft.corPredominante ?? '-'}\n'
                      'Marca: ${(draft.marca == null || draft.marca!.isEmpty) ? '-' : draft.marca}\n'
                      'Descrição: ${draft.descricao ?? '-'}',
                  icon: Icons.notes_rounded,
                  onEdit: () => Navigator.popUntil(
                    context,
                    ModalRoute.withName(AppRoutes.wizardDetalhes),
                  ),
                ),
              ],
            ),
          ),
          if (_enviando)
            Container(
              color: Colors.black.withValues(alpha: 0.42),
              child: const Center(
                child: _LoadingBox(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _enviando ? null : _confirmarEnvio,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirmar e Abrir Requerimento',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onEdit,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE6E0DB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFFFF6600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF6600),
          ),
          SizedBox(height: 18),
          Text(
            'A processar dados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'A IA da UniCatólica está a analisar o teu requerimento...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}