import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/requerimento_model.dart';

class ObjetoCard extends StatelessWidget {
  const ObjetoCard({
    super.key,
    required this.requerimento,
    this.compact = false,
  });

  final RequerimentoModel requerimento;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(requerimento.status);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/objeto_detalhes',
          arguments: requerimento,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImagem(),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 18,
                  compact ? 12 : 16,
                  compact ? 12 : 18,
                  compact ? 12 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requerimento.categoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: Color(0xFFFF6600),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            requerimento.localOcorrencia,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: compact ? 13 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        requerimento.descricao,
                        maxLines: compact ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.35,
                          fontSize: compact ? 13 : 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagem() {
    final imageUrl = requerimento.fotoUrl;
    final bool forcarPlaceholder = _usarPlaceholderAoInvesDaImagem();

    if (imageUrl == null || imageUrl.isEmpty || forcarPlaceholder) {
      return _placeholderBonito();
    }

    if (imageUrl.startsWith('data:image')) {
      final base64Data = imageUrl.split(',').last;
      final bytes = base64Decode(base64Data);

      return AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4EC),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF4EC),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            placeholder: (context, url) => _loadingImagem(),
            errorWidget: (context, url, error) => _placeholderBonitoInterno(),
          ),
        ),
      ),
    );
  }

  bool _usarPlaceholderAoInvesDaImagem() {
    final categoria = requerimento.categoria.toLowerCase();

    // Evita mostrar imagem errada de cofre quando a categoria for chave.
    // Se você quiser usar assets/images/chave.png aqui depois, dá para ajustar.
    if (categoria.contains('chave')) {
      return true;
    }

    return false;
  }

  Widget _loadingImagem() {
    return Container(
      color: const Color(0xFFFFF4EC),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6600),
          strokeWidth: 2.4,
        ),
      ),
    );
  }

  Widget _placeholderBonito() {
    return AspectRatio(
      aspectRatio: 1.15,
      child: _placeholderBonitoInterno(),
    );
  }

  Widget _placeholderBonitoInterno() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE5D3),
            Color(0xFFFFF7F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: compact ? 58 : 72,
              width: compact ? 58 : 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _iconePorCategoria(requerimento.categoria),
                size: compact ? 30 : 38,
                color: const Color(0xFFFF6600),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                requerimento.categoria,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFF6600),
                  fontSize: compact ? 16 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
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

    if (texto.contains('mochila') || texto.contains('bolsa')) {
      return Icons.backpack_rounded;
    }

    if (texto.contains('documento') || texto.contains('cartão')) {
      return Icons.badge_outlined;
    }

    if (texto.contains('livro') || texto.contains('caderno')) {
      return Icons.menu_book_rounded;
    }

    if (texto.contains('óculos') || texto.contains('oculos')) {
      return Icons.visibility_outlined;
    }

    return Icons.inventory_2_outlined;
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PERDIDO':
        return 'Perdido';
      case 'ENCONTRADO':
        return 'Encontrado';
      case 'DEVOLVIDO':
        return 'Devolvido';
      default:
        return status;
    }
  }

  _StatusStyle _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'PERDIDO':
        return const _StatusStyle(
          backgroundColor: Color(0xFFFFE2E2),
          textColor: Color(0xFFB42318),
        );
      case 'ENCONTRADO':
        return const _StatusStyle(
          backgroundColor: Color(0xFFDFF7E8),
          textColor: Color(0xFF067647),
        );
      case 'DEVOLVIDO':
        return const _StatusStyle(
          backgroundColor: Color(0xFFE7E9EE),
          textColor: Color(0xFF475467),
        );
      default:
        return const _StatusStyle(
          backgroundColor: Color(0xFFE7E9EE),
          textColor: Color(0xFF475467),
        );
    }
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