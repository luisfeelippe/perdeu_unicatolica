import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_model.dart';
import '../../../data/repositories/requerimento_repository.dart';
import '../../widgets/objeto_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.onAbrirAtualizacoes,
    required this.onAbrirObjetos,
    required this.onAbrirPerfil,
  });

  final VoidCallback onAbrirAtualizacoes;
  final VoidCallback onAbrirObjetos;
  final VoidCallback onAbrirPerfil;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final RequerimentoRepository _repository = RequerimentoRepository();

  late Future<List<RequerimentoModel>> _futureRequerimentos;
  String _nomeUsuario = 'Usuário';

  @override
  void initState() {
    super.initState();
    _futureRequerimentos = _repository.fetchRequerimentosRecentes();
    _carregarNomeUsuario();
  }

  Future<void> _carregarNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _nomeUsuario =
          prefs.getString('nome_completo') ??
          prefs.getString('nomeUsuario') ??
          prefs.getString('nome') ??
          'Administrador';
    });
  }

  void _recarregarFeed() {
    setState(() {
      _futureRequerimentos = _repository.fetchRequerimentosRecentes();
    });
  }

  String get _saudacao {
    final hora = DateTime.now().hour;

    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFFF6600),
      onRefresh: () async => _recarregarFeed(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HeaderHome(
              saudacao: _saudacao,
              nomeUsuario: _nomeUsuario,
              onAbrirPerfil: widget.onAbrirPerfil,
            ),
          ),
          SliverToBoxAdapter(
            child: _QuickActions(
              onAbrirRequerimento: () {
                Navigator.pushNamed(context, AppRoutes.wizardTipo);
              },
              onAcompanhar: widget.onAbrirAtualizacoes,
              onVerObjetos: widget.onAbrirObjetos,
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text(
                'Ocorrências Recentes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF222222),
                ),
              ),
            ),
          ),
          FutureBuilder<List<RequerimentoModel>>(
            future: _futureRequerimentos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6600),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: _EstadoErro(
                    mensagem: snapshot.error.toString(),
                    onTentarNovamente: _recarregarFeed,
                  ),
                );
              }

              final requerimentos = (snapshot.data ?? [])
                  .where((item) => item.status.toUpperCase() != 'CANCELADO')
                  .toList();

              if (requerimentos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: _EstadoVazio(),
                );
              }

              return SliverToBoxAdapter(
                child: _OcorrenciasLayout(
                  requerimentos: requerimentos,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

class _HeaderHome extends StatelessWidget {
  const _HeaderHome({
    required this.saudacao,
    required this.nomeUsuario,
    required this.onAbrirPerfil,
  });

  final String saudacao;
  final String nomeUsuario;
  final VoidCallback onAbrirPerfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFE4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFFF6600),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saudacao,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nomeUsuario,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF222222),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFFFF6600),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onAbrirPerfil,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  height: 48,
                  width: 48,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAbrirRequerimento,
    required this.onAcompanhar,
    required this.onVerObjetos,
  });

  final VoidCallback onAbrirRequerimento;
  final VoidCallback onAcompanhar;
  final VoidCallback onVerObjetos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Abrir Requerimento',
                  icon: Icons.add_circle_outline,
                  backgroundColor: const Color(0xFFFF6600),
                  textColor: Colors.white,
                  onTap: onAbrirRequerimento,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Acompanhar Solicitações',
                  icon: Icons.timeline_outlined,
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFFFF6600),
                  borderColor: const Color(0xFFFF6600),
                  onTap: onAcompanhar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: 'Ver todos os objetos',
            icon: Icons.inventory_2_outlined,
            backgroundColor: const Color(0xFFFFEFE4),
            textColor: const Color(0xFFFF6600),
            borderColor: const Color(0xFFFFD1B0),
            onTap: onVerObjetos,
            horizontal: true,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.borderColor,
    this.horizontal = false,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: horizontal ? 16 : 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.4)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: horizontal
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      icon,
                      color: textColor,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OcorrenciasLayout extends StatelessWidget {
  const _OcorrenciasLayout({
    required this.requerimentos,
  });

  final List<RequerimentoModel> requerimentos;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    final int quantidadeColunas = largura >= 900 ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: requerimentos.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: quantidadeColunas,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: largura >= 900 ? 0.82 : 0.68,
        ),
        itemBuilder: (context, index) {
          return ObjetoCard(
            requerimento: requerimentos[index],
            compact: true,
          );
        },
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: Color(0xFFFF6600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o feed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
              ),
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 50,
              color: Color(0xFFFF6600),
            ),
            SizedBox(height: 12),
            Text(
              'Ainda não há ocorrências recentes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quando alguém registrar um objeto perdido ou encontrado, ele aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}