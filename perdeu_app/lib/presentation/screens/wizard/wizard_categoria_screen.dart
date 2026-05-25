import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_draft.dart';
import 'widgets/wizard_progress.dart';

class WizardCategoriaScreen extends StatefulWidget {
  const WizardCategoriaScreen({super.key});

  @override
  State<WizardCategoriaScreen> createState() => _WizardCategoriaScreenState();
}

class _WizardCategoriaScreenState extends State<WizardCategoriaScreen> {
  static const Color _orange = Color(0xFFFF6600);

  final TextEditingController _outrosController = TextEditingController();
  final FocusNode _outrosFocus = FocusNode();

  String? _categoriaSelecionada;
  String? _erro;

  final List<_CategoriaOption> _categorias = const [
    _CategoriaOption('Celular', Icons.smartphone_rounded),
    _CategoriaOption('Mala/Mochila', Icons.backpack_rounded),
    _CategoriaOption('Garrafa de Água', Icons.local_drink_rounded),
    _CategoriaOption('Livro/Caderno', Icons.menu_book_rounded),
    _CategoriaOption('Chaves', Icons.key_rounded),
    _CategoriaOption('Óculos', Icons.visibility_outlined),
    _CategoriaOption('Outros', Icons.inventory_2_outlined),
  ];

  @override
  void dispose() {
    _outrosController.dispose();
    _outrosFocus.dispose();
    super.dispose();
  }

  RequerimentoDraft _draftFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoDraft) {
      return args;
    }

    return RequerimentoDraft();
  }

  void _selecionarCategoria(String categoria) {
    setState(() {
      _categoriaSelecionada = categoria;
      _erro = null;
    });

    if (categoria == 'Outros') {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _outrosFocus.requestFocus();
      });
    } else {
      _outrosFocus.unfocus();
    }
  }

  void _continuar() {
    final draft = _draftFromArgs(context);

    String? categoriaFinal = _categoriaSelecionada;

    if (categoriaFinal == 'Outros') {
      categoriaFinal = _outrosController.text.trim();
    }

    if (categoriaFinal == null || categoriaFinal.trim().isEmpty) {
      setState(() {
        _erro = 'Por favor, selecione ou digite uma categoria válida.';
      });
      return;
    }

    final atualizado = draft.copyWith(
      categoria: categoriaFinal.trim(),
    );

    Navigator.pushNamed(
      context,
      AppRoutes.wizardLocal,
      arguments: atualizado,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutros = _categoriaSelecionada == 'Outros';

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
              currentStep: 2,
              totalSteps: 6,
            ),
            const SizedBox(height: 24),
            const Text(
              'Qual é a categoria do objeto?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione uma categoria ou informe manualmente em Outros.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categorias.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (context, index) {
                final item = _categorias[index];
                final selected = _categoriaSelecionada == item.label;

                return _CategoriaCard(
                  label: item.label,
                  icon: item.icon,
                  selected: selected,
                  onTap: () => _selecionarCategoria(item.label),
                );
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: isOutros
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: TextField(
                        controller: _outrosController,
                        focusNode: _outrosFocus,
                        decoration: const InputDecoration(
                          labelText: 'Digite a categoria',
                          hintText: 'Ex: Fone de ouvido, carregador...',
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

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const Color _orange = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFEFE4) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _orange : const Color(0xFFE6E0DB),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? _orange : Colors.black54,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? _orange : const Color(0xFF222222),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriaOption {
  final String label;
  final IconData icon;

  const _CategoriaOption(this.label, this.icon);
}