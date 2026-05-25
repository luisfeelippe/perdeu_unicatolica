import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_model.dart';
import '../../../data/repositories/requerimento_repository.dart';

class AtualizacoesView extends StatefulWidget {
  const AtualizacoesView({super.key});

  @override
  State<AtualizacoesView> createState() => _AtualizacoesViewState();
}

class _AtualizacoesViewState extends State<AtualizacoesView> {
  final RequerimentoRepository _repository = RequerimentoRepository();

  late Future<List<RequerimentoModel>> _futureRequerimentos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futureRequerimentos = _repository.fetchMeusRequerimentos();
  }

  Future<void> _recarregar() async {
    setState(() {
      _carregar();
    });
  }

  Future<void> _abrirDetalhes(RequerimentoModel requerimento) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detalhes,
      arguments: requerimento,
    );

    if (!mounted) return;

    await _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F4F2),
      child: RefreshIndicator(
        color: const Color(0xFFFF6600),
        onRefresh: _recarregar,
        child: FutureBuilder<List<RequerimentoModel>>(
          future: _futureRequerimentos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 230),
                  Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6600),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 58,
                    color: Color(0xFFFF6600),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Não foi possível carregar suas atualizações.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Tentar novamente',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final requerimentos = snapshot.data ?? [];

            if (requerimentos.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: Color(0xFFFF6600),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Você ainda não possui nenhum requerimento aberto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quando você abrir um requerimento, ele aparecerá aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: requerimentos.length,
              itemBuilder: (context, index) {
                final item = requerimentos[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AtualizacaoCard(
                    requerimento: item,
                    onTap: () => _abrirDetalhes(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AtualizacaoCard extends StatelessWidget {
  const _AtualizacaoCard({
    required this.requerimento,
    required this.onTap,
  });

  final RequerimentoModel requerimento;
  final VoidCallback onTap;

  static const Color _orange = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(requerimento.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 138,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 128,
                height: double.infinity,
                child: _ImagemCompacta(
                  fotoUrl: requerimento.fotoUrl,
                  categoria: requerimento.categoria,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              requerimento.categoria,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusStyle.backgroundColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _formatStatus(requerimento.status),
                              style: TextStyle(
                                color: statusStyle.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: _orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              requerimento.localOcorrencia,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          requerimento.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Ver detalhes',
                            style: TextStyle(
                              color: _orange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: _orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
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

  _StatusStyle _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return const _StatusStyle(
          backgroundColor: Color(0xFFFFEFE4),
          textColor: Color(0xFFFF6600),
        );
      case 'EM_ANALISE':
        return const _StatusStyle(
          backgroundColor: Color(0xFFFFF4CC),
          textColor: Color(0xFF946200),
        );
      case 'CANCELADO':
        return const _StatusStyle(
          backgroundColor: Color(0xFFFFE2E2),
          textColor: Color(0xFFB42318),
        );
      case 'CONCLUIDO':
      case 'APROVADO':
      case 'DEVOLVIDO':
        return const _StatusStyle(
          backgroundColor: Color(0xFFDFF7E8),
          textColor: Color(0xFF067647),
        );
      default:
        return const _StatusStyle(
          backgroundColor: Color(0xFFE7E9EE),
          textColor: Color(0xFF475467),
        );
    }
  }
}

class _ImagemCompacta extends StatelessWidget {
  const _ImagemCompacta({
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

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => _placeholder(),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFFFF4EC),
      child: Center(
        child: Icon(
          _iconePorCategoria(categoria),
          color: const Color(0xFFFF6600),
          size: 42,
        ),
      ),
    );
  }

  IconData _iconePorCategoria(String categoria) {
    final texto = categoria.toLowerCase();

    if (texto.contains('celular') || texto.contains('telefone')) {
      return Icons.smartphone_rounded;
    }

    if (texto.contains('chave')) {
      return Icons.key_rounded;
    }

    if (texto.contains('garrafa')) {
      return Icons.local_drink_rounded;
    }

    if (texto.contains('mochila') || texto.contains('mala')) {
      return Icons.backpack_rounded;
    }

    if (texto.contains('livro') || texto.contains('caderno')) {
      return Icons.menu_book_rounded;
    }

    if (texto.contains('óculos') || texto.contains('oculos')) {
      return Icons.visibility_outlined;
    }

    return Icons.inventory_2_outlined;
  }
}

class _StatusStyle {
  final Color backgroundColor;
  final Color textColor;

  const _StatusStyle({
    required this.backgroundColor,
    required this.textColor,
  });
}