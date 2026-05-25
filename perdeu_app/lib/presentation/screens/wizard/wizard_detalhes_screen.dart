import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_draft.dart';
import 'widgets/wizard_progress.dart';

class WizardDetalhesScreen extends StatefulWidget {
  const WizardDetalhesScreen({super.key});

  @override
  State<WizardDetalhesScreen> createState() => _WizardDetalhesScreenState();
}

class _WizardDetalhesScreenState extends State<WizardDetalhesScreen> {
  static const Color _orange = Color(0xFFFF6600);

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _corController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  final FocusNode _corFocus = FocusNode();
  final FocusNode _marcaFocus = FocusNode();
  final FocusNode _descricaoFocus = FocusNode();

String? _caminhoFotoLocal;
String? _fotoBase64;
String? _erro;

  @override
  void dispose() {
    _corController.dispose();
    _marcaController.dispose();
    _descricaoController.dispose();

    _corFocus.dispose();
    _marcaFocus.dispose();
    _descricaoFocus.dispose();

    super.dispose();
  }

  RequerimentoDraft _draftFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoDraft) {
      return args;
    }

    return RequerimentoDraft();
  }

  Future<void> _tirarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1280,
      );

        if (foto != null) {
      final bytes = await foto.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _caminhoFotoLocal = foto.path;
        _fotoBase64 = base64String;
        _erro = null;
      });
    }
    } catch (_) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Permissão necessária'),
            content: const Text(
              'Não foi possível abrir a câmera. Verifique as permissões do aplicativo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          );
        },
      );
    }
  }

    void _removerFoto() {
    setState(() {
      _caminhoFotoLocal = null;
      _fotoBase64 = null;
    });
  }

  void _continuar() {
    final cor = _corController.text.trim();
    final marca = _marcaController.text.trim();
    final descricao = _descricaoController.text.trim();

    if (_caminhoFotoLocal == null || _caminhoFotoLocal!.isEmpty) {
      setState(() {
        _erro = 'Tire uma foto do objeto para continuar.';
      });
      return;
    }

    if (cor.isEmpty || !RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(cor)) {
      setState(() {
        _erro = 'Digite a cor principal do objeto.';
      });
      _corFocus.requestFocus();
      return;
    }

    if (descricao.length < 10) {
      setState(() {
        _erro = 'Forneça mais detalhes (mínimo de 10 caracteres).';
      });
      _descricaoFocus.requestFocus();
      return;
    }

        final draft = _draftFromArgs(context).copyWith(
      corPredominante: cor,
      marca: marca.isEmpty ? null : marca,
      descricao: descricao,
      caminhoFotoLocal: _caminhoFotoLocal,
      fotoBase64: _fotoBase64,
    );

    Navigator.pushNamed(
      context,
      AppRoutes.wizardRevisao,
      arguments: draft,
    );
  }

  Widget _buildFotoPreview(String caminho) {
    if (kIsWeb) {
      return Image.network(
        caminho,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(caminho),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final possuiFoto = _caminhoFotoLocal != null && _caminhoFotoLocal!.isNotEmpty;

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
              currentStep: 5,
              totalSteps: 6,
            ),
            const SizedBox(height: 24),
            const Text(
              'Detalhes do objeto',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione uma foto e descreva as características do objeto.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: possuiFoto ? null : _tirarFoto,
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4EC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFC9A6),
                    width: 1.5,
                  ),
                ),
                child: possuiFoto
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _buildFotoPreview(_caminhoFotoLocal!),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                              ),
                              onPressed: _removerFoto,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 48,
                            color: _orange,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tirar foto do objeto',
                            style: TextStyle(
                              color: _orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Obrigatório para abrir o requerimento',
                            style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _corController,
              focusNode: _corFocus,
              decoration: const InputDecoration(
                labelText: 'Cor predominante',
                hintText: 'Ex: Preto, azul, vermelho...',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _marcaController,
              focusNode: _marcaFocus,
              decoration: const InputDecoration(
                labelText: 'Marca (opcional)',
                hintText: 'Ex: Samsung, Nike, Tilibra...',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descricaoController,
              focusNode: _descricaoFocus,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Descrição detalhada',
                hintText: 'Descreva detalhes que ajudem na identificação...',
              ),
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