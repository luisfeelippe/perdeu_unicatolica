import 'package:flutter/material.dart';

import '../../../data/models/requerimento_model.dart';
import '../../../data/repositories/requerimento_repository.dart';
import '../../widgets/objeto_card.dart';

class ObjetosView extends StatefulWidget {
  const ObjetosView({super.key});

  @override
  State<ObjetosView> createState() => _ObjetosViewState();
}

class _ObjetosViewState extends State<ObjetosView> {
  final RequerimentoRepository _repository = RequerimentoRepository();

  late Future<List<RequerimentoModel>> _futureObjetos;

  String _filtroAtual = 'Todos';

  final List<String> _filtros = const [
    'Todos',
    'Perdidos',
    'Encontrados',
    'Em análise',
    'Concluídos',
  ];

  @override
  void initState() {
    super.initState();
    _futureObjetos = _repository.fetchRequerimentosRecentes();
  }

  void _recarregar() {
    setState(() {
      _futureObjetos = _repository.fetchRequerimentosRecentes();
    });
  }

  List<RequerimentoModel> _filtrar(List<RequerimentoModel> lista) {
    final ativos = lista
        .where((item) => item.status.toUpperCase() != 'CANCELADO')
        .toList();

    switch (_filtroAtual) {
      case 'Perdidos':
        return ativos
            .where(
              (item) =>
                  item.tipo.toUpperCase() == 'PERDA' ||
                  item.status.toUpperCase() == 'PERDIDO',
            )
            .toList();

      case 'Encontrados':
        return ativos
            .where(
              (item) =>
                  item.tipo.toUpperCase() == 'ACHADO' ||
                  item.status.toUpperCase() == 'ENCONTRADO',
            )
            .toList();

      case 'Em análise':
        return ativos
            .where((item) => item.status.toUpperCase() == 'EM_ANALISE')
            .toList();

      case 'Concluídos':
        return ativos
            .where(
              (item) =>
                  item.status.toUpperCase() == 'CONCLUIDO' ||
                  item.status.toUpperCase() == 'DEVOLVIDO' ||
                  item.status.toUpperCase() == 'APROVADO',
            )
            .toList();

      default:
        return ativos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Objetos'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF6600),
        onRefresh: () async => _recarregar(),
        child: FutureBuilder<List<RequerimentoModel>>(
          future: _futureObjetos,
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
                  const SizedBox(height: 110),
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 58,
                    color: Color(0xFFFF6600),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Não foi possível carregar os objetos.',
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
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Tentar novamente',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              );
            }

            final objetos = _filtrar(snapshot.data ?? []);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
              children: [
                const Text(
                  'Todos os objetos',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Consulte os itens registrados no sistema de Achados e Perdidos.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filtros.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filtro = _filtros[index];
                      final selecionado = filtro == _filtroAtual;

                      return ChoiceChip(
                        label: Text(filtro),
                        selected: selecionado,
                        selectedColor: const Color(0xFFFFE4D1),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selecionado
                              ? const Color(0xFFFF6600)
                              : Colors.black54,
                          fontWeight: FontWeight.w800,
                        ),
                        side: BorderSide(
                          color: selecionado
                              ? const Color(0xFFFF6600)
                              : const Color(0xFFE6E0DB),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _filtroAtual = filtro;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (objetos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 54,
                          color: Color(0xFFFF6600),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum objeto encontrado nesse filtro.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tente selecionar outro filtro ou atualize a lista.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final largura = constraints.maxWidth;
                      final colunas = largura >= 900 ? 3 : 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: objetos.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: colunas,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: largura >= 900 ? 0.82 : 0.68,
                        ),
                        itemBuilder: (context, index) {
                          return ObjetoCard(
                            requerimento: objetos[index],
                            compact: true,
                          );
                        },
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}