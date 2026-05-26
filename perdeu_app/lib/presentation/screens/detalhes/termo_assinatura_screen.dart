import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_model.dart';
import '../../../data/repositories/requerimento_repository.dart';

class TermoAssinaturaScreen extends StatefulWidget {
  const TermoAssinaturaScreen({super.key});

  @override
  State<TermoAssinaturaScreen> createState() => _TermoAssinaturaScreenState();
}

class _TermoAssinaturaScreenState extends State<TermoAssinaturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = RequerimentoRepository();

  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
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

  Future<String> _capturarModeloDispositivo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} ${webInfo.platform ?? 'Web'}';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await deviceInfo.androidInfo;
          return '${androidInfo.manufacturer} ${androidInfo.model}';
        case TargetPlatform.iOS:
          final iosInfo = await deviceInfo.iosInfo;
          return iosInfo.utsname.machine;
        case TargetPlatform.windows:
          final windowsInfo = await deviceInfo.windowsInfo;
          return 'Windows ${windowsInfo.computerName}';
        case TargetPlatform.macOS:
          final macInfo = await deviceInfo.macOsInfo;
          return 'macOS ${macInfo.model}';
        case TargetPlatform.linux:
          final linuxInfo = await deviceInfo.linuxInfo;
          return 'Linux ${linuxInfo.prettyName}';
        case TargetPlatform.fuchsia:
          return 'Fuchsia';
      }
    } catch (_) {
      return 'Dispositivo não identificado';
    }
  }

  Future<void> _assinarTermo() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final requerimento = _requerimentoFromArgs(context);

    if (requerimento.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Requerimento inválido.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final modelo = await _capturarModeloDispositivo();

      final sucesso = await _repository.assinarTermo(
        id: requerimento.id,
        cpf: _cpfController.text.trim(),
        senha: _senhaController.text.trim(),
        dispositivoModelo: modelo,
      );

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF12A150),
            content: Text('Termo assinado! Retirada concluída com sucesso.'),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
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
    final requerimento = _requerimentoFromArgs(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Termo de Retirada'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE6E0DB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Termo de Responsabilidade e Recebimento de Bem',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Objeto: ${requerimento.categoria}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6600),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Declaro, para os devidos fins, que recebi o objeto identificado no protocolo de retirada apresentado ao setor de Achados e Perdidos da UniCatólica.\n\n'
                      'Declaro ainda que conferi as informações do bem, assumindo total responsabilidade pela veracidade dos dados informados neste processo.\n\n'
                      'Estou ciente de que esta assinatura digital registra data, hora, endereço de rede e identificação do dispositivo utilizado, compondo a trilha de auditoria da retirada.\n\n'
                      'Ao confirmar, reconheço o recebimento do bem e autorizo o encerramento do requerimento no sistema Perdeu.',
                      style: TextStyle(
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _CpfInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  hintText: '000.000.000-00',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

                  if (digits.length != 11) {
                    return 'Informe um CPF válido com 11 dígitos.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _senhaController,
                obscureText: _obscureSenha,
                decoration: InputDecoration(
                  labelText: 'Senha do aplicativo',
                  hintText: 'Digite sua senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureSenha = !_obscureSenha;
                      });
                    },
                    icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe sua senha.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _assinarTermo,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(
                    _isLoading
                        ? 'Assinando...'
                        : 'Confirmar e Assinar Digitalmente',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      }

      if (i == 9) {
        buffer.write('-');
      }

      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}