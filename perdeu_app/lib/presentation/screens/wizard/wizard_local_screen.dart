import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_draft.dart';
import 'widgets/wizard_progress.dart';

class WizardLocalScreen extends StatefulWidget {
  const WizardLocalScreen({super.key});

  @override
  State<WizardLocalScreen> createState() => _WizardLocalScreenState();
}

class _WizardLocalScreenState extends State<WizardLocalScreen> {
  static const Color _orange = Color(0xFFFF6600);

  final TextEditingController _outroLocalController = TextEditingController();
  final FocusNode _outroLocalFocus = FocusNode();

  String? _localSelecionado;
  String? _erro;

  final List<String> _locais = const [
    'Bloco A',
    'Bloco B',
    'Biblioteca',
    'Cantina',
    'Quadra Polidesportiva',
    'Estacionamento',
    'Outro Local',
  ];

  @override
  void dispose() {
    _outroLocalController.dispose();
    _outroLocalFocus.dispose();
    super.dispose();
  }

  RequerimentoDraft _draftFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoDraft) {
      return args;
    }

    return RequerimentoDraft();
  }

  void _selecionarLocal(String local) {
    setState(() {
      _localSelecionado = local;
      _erro = null;
    });

    if (local == 'Outro Local') {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _outroLocalFocus.requestFocus();
      });
    } else {
      _outroLocalFocus.unfocus();
    }
  }

  void _continuar() {
    final draft = _draftFromArgs(context);

    String? localFinal = _localSelecionado;

    if (localFinal == 'Outro Local') {
      localFinal = _outroLocalController.text.trim();
    }

    if (localFinal == null || localFinal.trim().isEmpty) {
      setState(() {
        _erro = 'Informe o local aproximado do acontecimento.';
      });
      return;
    }

    final atualizado = draft.copyWith(
      localOcorrencia: localFinal.trim(),
    );

    Navigator.pushNamed(
      context,
      AppRoutes.wizardDataHora,
      arguments: atualizado,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutroLocal = _localSelecionado == 'Outro Local';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Novo Requerimento'),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _continuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const WizardProgress(
              currentStep: 3,
              totalSteps: 6,
            ),
            const SizedBox(height: 24),
            const Text(
              'Onde aconteceu?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informe o local mais próximo onde o objeto foi perdido ou encontrado.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _locais.map((local) {
                final selected = _localSelecionado == local;

                return ChoiceChip(
                  selected: selected,
                  label: Text(local),
                  avatar: Icon(
                    local == 'Outro Local'
                        ? Icons.edit_location_alt_outlined
                        : Icons.location_on_outlined,
                    size: 18,
                    color: selected ? Colors.white : _orange,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF222222),
                    fontWeight: FontWeight.w700,
                  ),
                  selectedColor: _orange,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? _orange : const Color(0xFFE6E0DB),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  onSelected: (_) => _selecionarLocal(local),
                );
              }).toList(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: isOutroLocal
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: TextField(
                        controller: _outroLocalController,
                        focusNode: _outroLocalFocus,
                        decoration: const InputDecoration(
                          labelText: 'Digite o local',
                          hintText: 'Ex: Laboratório 3, corredor central...',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 14),
              Text(
                _erro!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}