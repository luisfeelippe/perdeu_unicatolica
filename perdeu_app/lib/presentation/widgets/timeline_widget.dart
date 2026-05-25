import 'package:flutter/material.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({
    super.key,
    required this.status,
  });

  final String status;

  static const Color _orange = Color(0xFFFF6600);
  static const Color _green = Color(0xFF12A150);
  static const Color _red = Color(0xFFD92D20);

  bool get _cancelado => status.toUpperCase() == 'CANCELADO';

  bool get _emAnalise {
    final s = status.toUpperCase();
    return s == 'EM_ANALISE' ||
        s == 'CONCLUIDO' ||
        s == 'APROVADO' ||
        s == 'DEVOLVIDO';
  }

  bool get _concluido {
    final s = status.toUpperCase();
    return s == 'CONCLUIDO' || s == 'APROVADO' || s == 'DEVOLVIDO';
  }

  @override
  Widget build(BuildContext context) {
    if (_cancelado) {
      return _TimelineContainer(
        children: [
          _TimelineStep(
            title: 'Processo Cancelado',
            subtitle: 'Este requerimento foi encerrado pelo usuário.',
            active: true,
            color: _red,
            isLast: true,
          ),
        ],
      );
    }

    return _TimelineContainer(
      children: [
        const _TimelineStep(
          title: 'Aberto',
          subtitle: 'Requerimento registrado no sistema.',
          active: true,
          color: _green,
        ),
        _TimelineStep(
          title: 'Em Análise / Triagem IA',
          subtitle: 'A UniCatólica está verificando possíveis correspondências.',
          active: _emAnalise,
          color: _orange,
        ),
        _TimelineStep(
          title: 'Disponível / Encontrado',
          subtitle: 'O processo foi concluído ou aprovado pela administração.',
          active: _concluido,
          color: _green,
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineContainer extends StatelessWidget {
  const _TimelineContainer({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
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

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.color,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool active;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = active ? color : const Color(0xFF98A2B3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? Icons.check : Icons.circle,
                size: active ? 14 : 8,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 52,
                color: active ? dotColor : const Color(0xFFE6E0DB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 14 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: active ? const Color(0xFF222222) : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: active ? Colors.black54 : Colors.black38,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}