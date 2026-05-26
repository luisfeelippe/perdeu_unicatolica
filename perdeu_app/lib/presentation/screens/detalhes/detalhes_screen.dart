import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_model.dart';
import '../../../data/repositories/requerimento_repository.dart';
import '../../widgets/timeline_widget.dart';

class DetalhesScreen extends StatefulWidget {
  const DetalhesScreen({super.key});

  @override
  State<DetalhesScreen> createState() => _DetalhesScreenState();
}

class _DetalhesScreenState extends State<DetalhesScreen> {
  final RequerimentoRepository _repository = RequerimentoRepository();

  late RequerimentoModel _requerimento;

  bool _inicializado = false;
  bool _cancelando = false;

  final TextEditingController _justificativaController =
      TextEditingController();

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_inicializado) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoModel) {
      _requerimento = args;
    } else {
      _requerimento = RequerimentoModel(
        id: '',
        tipo: '',
        categoria: 'Não informado',
        localOcorrencia: 'Não informado',
        dataHoraOcorrencia: DateTime.now(),
        descricao: 'Dados não encontrados.',
        status: 'PENDENTE',
      );
    }

    _inicializado = true;
  }

  bool get _podeCancelar {
    final status = _requerimento.status.toUpperCase();

    return status != 'CANCELADO' &&
        status != 'CONCLUIDO' &&
        status != 'APROVADO' &&
        status != 'DEVOLVIDO' &&
        _requerimento.id.isNotEmpty;
  }

  bool get _podeAssinarRetirada {
    final status = _requerimento.status.toUpperCase();

    return status != 'CANCELADO' &&
        status != 'CONCLUIDO' &&
        status != 'APROVADO' &&
        status != 'DEVOLVIDO' &&
        _requerimento.id.isNotEmpty;
  }

  Future<void> _abrirModalCancelamento() async {
    _justificativaController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> cancelar() async {
              final justificativa = _justificativaController.text.trim();

              if (justificativa.isEmpty) {
                ScaffoldMessenger.of(modalContext).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Informe uma justificativa.'),
                  ),
                );
                return;
              }

              setModalState(() {
                _cancelando = true;
              });

              try {
                final sucesso = await _repository.cancelarRequerimento(
                  id: _requerimento.id,
                  justificativa: justificativa,
                );

                if (!mounted) return;

                if (sucesso) {
                  Navigator.pop(modalContext);

                  setState(() {
                    _cancelando = false;
                    _requerimento = _requerimento.copyWith(
                      status: 'CANCELADO',
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF12A150),
                      content: Text('Requerimento cancelado com sucesso.'),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;

                setModalState(() {
                  _cancelando = false;
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

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 22,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deseja mesmo cancelar?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Essa ação é irreversível. O requerimento será mantido apenas para auditoria.',
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _justificativaController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Justificativa',
                      hintText: 'Ex: encontrei o objeto sozinho...',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _cancelando ? null : cancelar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _cancelando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.6,
                              ),
                            )
                          : const Text(
                              'Sim, Cancelar',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _cancelando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataHora = DateFormat('dd/MM/yyyy HH:mm').format(
      _requerimento.dataHoraOcorrencia,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Detalhes'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        children: [
          _ImagemObjeto(
            fotoUrl: _requerimento.fotoUrl,
            categoria: _requerimento.categoria,
          ),
          const SizedBox(height: 18),
          Text(
            _requerimento.categoria,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatarStatus(_requerimento.status),
            style: const TextStyle(
              color: Color(0xFFFF6600),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _InfoBox(
            children: [
              _InfoLinha(
                icon: Icons.compare_arrows_rounded,
                label: 'Tipo',
                value: _requerimento.tipo,
              ),
              _InfoLinha(
                icon: Icons.location_on_outlined,
                label: 'Local',
                value: _requerimento.localOcorrencia,
              ),
              _InfoLinha(
                icon: Icons.access_time_rounded,
                label: 'Data/Hora',
                value: dataHora,
              ),
              _InfoLinha(
                icon: Icons.palette_outlined,
                label: 'Cor',
                value: _requerimento.corPredominante ?? '-',
              ),
              _InfoLinha(
                icon: Icons.label_outline,
                label: 'Marca',
                value: _requerimento.marca ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DescricaoBox(descricao: _requerimento.descricao),
          const SizedBox(height: 16),
          TimelineWidget(status: _requerimento.status),
          if (_podeAssinarRetirada) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.protocolo,
                    arguments: _requerimento,
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text(
                  'Gerar Protocolo de Retirada',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          if (_podeCancelar) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _abrirModalCancelamento,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Requerimento'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatarStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return 'Pendente';
      case 'EM_ANALISE':
        return 'Em análise';
      case 'CANCELADO':
        return 'Cancelado';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'APROVADO':
        return 'Aprovado';
      case 'DEVOLVIDO':
        return 'Devolvido';
      case 'PERDIDO':
        return 'Perdido';
      case 'ENCONTRADO':
        return 'Encontrado';
      default:
        return status;
    }
  }
}

class _ImagemObjeto extends StatelessWidget {
  const _ImagemObjeto({
    required this.fotoUrl,
    required this.categoria,
  });

  final String? fotoUrl;
  final String categoria;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl;

    if (url == null || url.isEmpty) {
      return _placeholder();
    }

    if (url.startsWith('data:image')) {
      final base64Data = url.split(',').last;
      final bytes = base64Decode(base64Data);

      return _imageContainer(
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
        ),
      );
    }

    return _imageContainer(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _placeholder(),
      ),
    );
  }

  Widget _imageContainer({
    required Widget child,
  }) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: child,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFFF6600),
              size: 52,
            ),
            const SizedBox(height: 10),
            Text(
              categoria,
              style: const TextStyle(
                color: Color(0xFFFF6600),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE6E0DB),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  const _InfoLinha({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF6600),
            size: 21,
          ),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescricaoBox extends StatelessWidget {
  const _DescricaoBox({
    required this.descricao,
  });

  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Descrição',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}