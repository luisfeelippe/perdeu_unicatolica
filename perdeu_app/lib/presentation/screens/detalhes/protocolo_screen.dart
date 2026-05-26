import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_model.dart';

class ProtocoloScreen extends StatefulWidget {
  const ProtocoloScreen({super.key});

  @override
  State<ProtocoloScreen> createState() => _ProtocoloScreenState();
}

class _ProtocoloScreenState extends State<ProtocoloScreen> {
  String _usuarioId = 'usuario-nao-identificado';

  @override
  void initState() {
    super.initState();
    _carregarUsuarioId();
  }

  Future<void> _carregarUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('jwt');

    if (token == null || token.isEmpty) return;

    try {
      final partes = token.split('.');

      if (partes.length < 2) return;

      final payloadNormalizado = base64Url.normalize(partes[1]);
      final payloadJson = utf8.decode(base64Url.decode(payloadNormalizado));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      final id = payload['id']?.toString();

      if (id != null && id.isNotEmpty && mounted) {
        setState(() {
          _usuarioId = id;
        });
      }
    } catch (_) {
      // Se o token não puder ser lido, mantém o valor seguro padrão.
    }
  }

  RequerimentoModel _requerimentoFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoModel) {
      return args;
    }

    return RequerimentoModel(
      id: '',
      tipo: '',
      categoria: 'Não informado',
      localOcorrencia: 'Não informado',
      dataHoraOcorrencia: DateTime.now(),
      descricao: 'Dados não encontrados.',
      status: 'PENDENTE',
    );
  }

  @override
  Widget build(BuildContext context) {
    final requerimento = _requerimentoFromArgs(context);

    final qrData = 'PROTOCOL:${requerimento.id}|USER:$_usuarioId';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Protocolo de Retirada'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 42,
                    color: Color(0xFFFF6600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Credencial de Retirada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requerimento.categoria,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE6E0DB),
                      ),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 230,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Apresente este QR Code no guichê de Achados e Perdidos para liberação do objeto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ID do protocolo:\n${requerimento.id}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8A3A00),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: requerimento.id.isEmpty
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.assinarTermo,
                          arguments: requerimento,
                        );
                      },
                icon: const Icon(Icons.edit_document),
                label: const Text(
                  'Avançar para Termo de Assinatura',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}