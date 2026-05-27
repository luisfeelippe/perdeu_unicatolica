import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/repositories/admin_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _repository = AdminRepository();

  final TextEditingController _buscaController = TextEditingController();

  Future<List<Map<String, dynamic>>>? _futurePendentes;
  Future<List<Map<String, dynamic>>>? _futureMatches;
  Future<List<Map<String, dynamic>>>? _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _futurePendentes = _repository.buscarRequerimentosPendentes();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _carregarAba(int index) {
    setState(() {
      if (index == 0) {
        _futurePendentes ??= _repository.buscarRequerimentosPendentes();
      } else if (index == 1) {
        _futureMatches ??= _repository.buscarMatches();
      } else if (index == 2) {
        _futureUsuarios ??= _repository.buscarUsuarios();
      }
    });
  }

  Future<void> _atualizarStatus(String id, String status) async {
    try {
      await _repository.atualizarStatusRequerimento(
        id: id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _futurePendentes = _repository.buscarRequerimentosPendentes();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF12A150),
          content: Text('Requerimento $status com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _bloquearUsuario(String id, bool bloquear) async {
    try {
      await _repository.bloquearUsuario(
        id: id,
        bloquear: bloquear,
      );

      if (!mounted) return;

      setState(() {
        _futureUsuarios = _repository.buscarUsuarios();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF12A150),
          content: Text(
            bloquear
                ? 'Usuário bloqueado com sucesso.'
                : 'Usuário desbloqueado com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _confirmarMatch(String id) async {
    try {
      await _repository.confirmarMatch(id: id);

      if (!mounted) return;

      setState(() {
        _futureMatches = _repository.buscarMatches();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF12A150),
          content: Text('Match concluído e removido da lista.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _abrirModalNovoUsuario() async {
    final criado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return _NovoUsuarioModal(
          repository: _repository,
        );
      },
    );

    if (criado == true && mounted) {
      setState(() {
        _futureUsuarios = _repository.buscarUsuarios();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF12A150),
          content: Text(
            'Usuário criado com sucesso. Senha inicial: perdeuunicatolica',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              _carregarAba(tabController.index);
            }
          });

          return Scaffold(
            backgroundColor: const Color(0xFFF7F4F2),
            appBar: AppBar(
              title: const Text('Painel Admin'),
              centerTitle: true,
              bottom: const TabBar(
                labelColor: Color(0xFFFF6600),
                unselectedLabelColor: Colors.black54,
                indicatorColor: Color(0xFFFF6600),
                tabs: [
                  Tab(text: 'Pendentes'),
                  Tab(text: 'IA Matches'),
                  Tab(text: 'Alunos'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PendentesTab(
                  future: _futurePendentes!,
                  onAprovar: (id) => _atualizarStatus(id, 'APROVADO'),
                  onRejeitar: (id) => _atualizarStatus(id, 'REJEITADO'),
                ),
                _MatchesTab(
                  future: _futureMatches ??
                      Future<List<Map<String, dynamic>>>.value([]),
                  onConfirmarMatch: _confirmarMatch,
                ),
                _UsuariosTab(
                  future: _futureUsuarios ??
                      Future<List<Map<String, dynamic>>>.value([]),
                  buscaController: _buscaController,
                  onBloquear: _bloquearUsuario,
                  onNovoUsuario: _abrirModalNovoUsuario,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendentesTab extends StatelessWidget {
  const _PendentesTab({
    required this.future,
    required this.onAprovar,
    required this.onRejeitar,
  });

  final Future<List<Map<String, dynamic>>> future;
  final void Function(String id) onAprovar;
  final void Function(String id) onRejeitar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6600),
            ),
          );
        }

        final dados = snapshot.data!;

        if (dados.isEmpty) {
          return const Center(
            child: Text('Nenhum requerimento pendente.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dados.length,
          itemBuilder: (context, index) {
            final item = dados[index];

            return _AdminCard(
              title: item['categoria']?.toString() ?? 'Sem categoria',
              subtitle:
                  '${item['tipo']} • ${item['local_ocorrencia'] ?? '-'}',
              description: item['descricao']?.toString() ?? '-',
              trailing: Text(
                item['status']?.toString() ?? '',
                style: const TextStyle(
                  color: Color(0xFFFF6600),
                  fontWeight: FontWeight.w900,
                ),
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: () => onAprovar(item['id'].toString()),
                  icon: const Icon(Icons.check),
                  label: const Text('Aprovar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onRejeitar(item['id'].toString()),
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({
    required this.future,
    required this.onConfirmarMatch,
  });

  final Future<List<Map<String, dynamic>>> future;
  final void Function(String id) onConfirmarMatch;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6600),
            ),
          );
        }

        final dados = snapshot.data!;

        if (dados.isEmpty) {
          return const Center(
            child: Text('Nenhum match encontrado.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dados.length,
          itemBuilder: (context, index) {
            final match = dados[index];
            final novo = match['novo'] as Map<String, dynamic>;
            final candidato = match['candidato'] as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text(
                    'Score IA: ${match['score_confianca']}%',
                    style: const TextStyle(
                      color: Color(0xFFFF6600),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match['justificativa']?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ObjetoComparacao(
                          titulo: 'Objeto A',
                          dados: novo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ObjetoComparacao(
                          titulo: 'Objeto B',
                          dados: candidato,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onConfirmarMatch(match['id'].toString());
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Confirmar Match'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab({
    required this.future,
    required this.buscaController,
    required this.onBloquear,
    required this.onNovoUsuario,
  });

  final Future<List<Map<String, dynamic>>> future;
  final TextEditingController buscaController;
  final Future<void> Function(String id, bool bloquear) onBloquear;
  final VoidCallback onNovoUsuario;

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6600),
            ),
          );
        }

        final usuarios = snapshot.data!.where((usuario) {
          final matricula = usuario['matricula']?.toString().toLowerCase() ?? '';
          final nome = usuario['nome_completo']?.toString().toLowerCase() ?? '';
          final query = _busca.toLowerCase();

          return matricula.contains(query) || nome.contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.buscaController,
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar por matrícula ou nome',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _busca = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: widget.onNovoUsuario,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text(
                        'Novo',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Senha inicial dos novos usuários: perdeuunicatolica',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final user = usuarios[index];
                  final ativo = user['status_ativo'] == true;

                  return _AdminCard(
                    title: user['nome_completo']?.toString() ?? 'Usuário',
                    subtitle:
                        'Matrícula: ${user['matricula']} • ${user['perfil']}',
                    description:
                        '${user['curso'] ?? '-'} • ${user['semestre'] ?? '-'}\n'
                        'E-mail: ${user['email'] ?? '-'}\n'
                        'CPF: ${user['cpf'] ?? '-'}',
                    trailing: Text(
                      ativo ? 'Ativo' : 'Bloqueado',
                      style: TextStyle(
                        color: ativo ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.onBloquear(
                            user['id'].toString(),
                            ativo,
                          );
                        },
                        icon: Icon(
                          ativo ? Icons.block : Icons.lock_open,
                        ),
                        label: Text(
                          ativo ? 'Suspender Acesso' : 'Liberar Acesso',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              ativo ? Colors.red : const Color(0xFF12A150),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NovoUsuarioModal extends StatefulWidget {
  const _NovoUsuarioModal({
    required this.repository,
  });

  final AdminRepository repository;

  @override
  State<_NovoUsuarioModal> createState() => _NovoUsuarioModalState();
}

class _NovoUsuarioModalState extends State<_NovoUsuarioModal> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cursoController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _semestreController = TextEditingController();

  bool _statusAtivo = true;
  bool _loading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cursoController.dispose();
    _matriculaController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _semestreController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await widget.repository.criarUsuario(
        nomeCompleto: _nomeController.text.trim(),
        matricula: _matriculaController.text.trim(),
        email: _emailController.text.trim(),
        curso: _cursoController.text.trim(),
        semestre: _semestreController.text.trim(),
        cpf: _cpfController.text.trim(),
        statusAtivo: _statusAtivo,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Novo usuário',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'A senha inicial será: perdeuunicatolica',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cursoController,
              decoration: const InputDecoration(
                labelText: 'Curso',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _matriculaController,
              decoration: const InputDecoration(
                labelText: 'Matrícula',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail institucional',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final texto = value?.trim() ?? '';

                if (texto.isEmpty) {
                  return 'Campo obrigatório';
                }

                if (!texto.contains('@')) {
                  return 'Informe um e-mail válido';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                labelText: 'CPF',
                prefixIcon: Icon(Icons.assignment_ind_outlined),
              ),
              validator: (value) {
                final texto = value?.trim() ?? '';

                if (texto.length != 11) {
                  return 'Informe um CPF com 11 dígitos';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _semestreController,
              decoration: const InputDecoration(
                labelText: 'Semestre',
                hintText: 'Ex: 6º Semestre',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _statusAtivo,
              onChanged: (value) {
                setState(() {
                  _statusAtivo = value;
                });
              },
              activeThumbColor: const Color(0xFFFF6600),
              activeTrackColor: const Color(0xFFFFE4D1),
              title: const Text(
                'Usuário ativo no sistema',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _statusAtivo
                    ? 'O usuário poderá acessar o aplicativo.'
                    : 'O usuário será criado bloqueado.',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _salvar,
                icon: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Salvando...' : 'Criar usuário',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _obrigatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.actions,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String description;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _ObjetoComparacao extends StatelessWidget {
  const _ObjetoComparacao({
    required this.titulo,
    required this.dados,
  });

  final String titulo;
  final Map<String, dynamic> dados;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF6600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dados['categoria']?.toString() ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dados['descricao']?.toString() ?? '-',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}