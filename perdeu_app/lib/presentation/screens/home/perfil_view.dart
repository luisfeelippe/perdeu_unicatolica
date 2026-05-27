import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/perfil_repository.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final PerfilRepository _perfilRepository = PerfilRepository();
  final AuthRepository _authRepository = AuthRepository();
  final ImagePicker _imagePicker = ImagePicker();

  late Future<Map<String, dynamic>> _futurePerfil;

  bool _notificacoesAtivas = true;
  bool _atualizandoFoto = false;
  String? _fotoPerfil;

  @override
  void initState() {
    super.initState();
    _futurePerfil = _perfilRepository.buscarPerfil();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _notificacoesAtivas = prefs.getBool('notificacoes_ativas') ?? true;
    });
  }

  Future<void> _alterarNotificacoes(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notificacoes_ativas', value);

    if (!mounted) return;

    setState(() {
      _notificacoesAtivas = value;
    });
  }

  Future<void> _selecionarFotoPerfil() async {
    if (_atualizandoFoto) return;

    try {
      final imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (imagem == null) return;

      setState(() {
        _atualizandoFoto = true;
      });

      final bytes = await imagem.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataImage = 'data:image/jpeg;base64,$base64Image';

      final fotoSalva = await _perfilRepository.atualizarFotoPerfil(
        fotoPerfil: dataImage,
      );

      if (!mounted) return;

      setState(() {
        _fotoPerfil = fotoSalva;
        _atualizandoFoto = false;
        _futurePerfil = _perfilRepository.buscarPerfil();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF12A150),
          content: Text('Foto de perfil atualizada com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _atualizandoFoto = false;
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

  Future<void> _removerFotoPerfil() async {
    if (_atualizandoFoto) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover foto?'),
          content: const Text(
            'Sua foto de perfil será removida e voltará para a inicial do seu nome.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      _atualizandoFoto = true;
    });

    try {
      await _perfilRepository.removerFotoPerfil();

      if (!mounted) return;

      setState(() {
        _fotoPerfil = null;
        _atualizandoFoto = false;
        _futurePerfil = _perfilRepository.buscarPerfil();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF12A150),
          content: Text('Foto de perfil removida com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _atualizandoFoto = false;
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

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _abrirModalAlterarSenha() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return const _AlterarSenhaModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futurePerfil,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6600),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final perfil = snapshot.data ?? {};

        final nome = perfil['nome_completo']?.toString() ?? 'Usuário';
        final email = perfil['email']?.toString() ?? 'E-mail não informado';
        final matricula = perfil['matricula']?.toString() ?? '-';
        final curso = perfil['curso']?.toString() ?? '-';
        final semestre = perfil['semestre']?.toString() ?? '-';
        final tipoPerfil = perfil['perfil']?.toString() ?? '-';
        final ativo = perfil['status_ativo'] == true;
        final isAdmin = tipoPerfil.toUpperCase() == 'ADMIN';
        final foto = _fotoPerfil ?? perfil['foto_perfil']?.toString();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4F2),
          appBar: AppBar(
            title: const Text('Perfil'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
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
                child: Column(
                  children: [
                    _FotoPerfilAvatar(
                      nome: nome,
                      fotoPerfil: foto,
                      atualizando: _atualizandoFoto,
                      onAlterarFoto: _selecionarFotoPerfil,
                      onRemoverFoto: _removerFotoPerfil,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Toque na foto para alterar ou remover',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: ativo
                            ? const Color(0xFFDFF7E8)
                            : const Color(0xFFFFE2E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ativo ? 'CONTA ATIVA' : 'CONTA BLOQUEADA',
                        style: TextStyle(
                          color: ativo
                              ? const Color(0xFF067647)
                              : const Color(0xFFB42318),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PerfilCard(
                title: 'Informações Acadêmicas',
                children: [
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Matrícula',
                    value: matricula,
                  ),
                  _InfoTile(
                    icon: Icons.school_outlined,
                    label: 'Curso',
                    value: curso,
                  ),
                  _InfoTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Semestre',
                    value: semestre,
                  ),
                  _InfoTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Perfil',
                    value: tipoPerfil,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PerfilCard(
                title: 'Configurações',
                children: [
                  SwitchListTile.adaptive(
                    value: _notificacoesAtivas,
                    onChanged: _alterarNotificacoes,
                    activeThumbColor: const Color(0xFFFF6600),
                    activeTrackColor: const Color(0xFFFFE4D1),
                    title: const Text(
                      'Notificações ativas',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Receber avisos sobre atualizações do processo.',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFFFF6600),
                    ),
                    title: const Text(
                      'Alterar senha',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: _abrirModalAlterarSenha,
                  ),
                  if (isAdmin)
                    ListTile(
                      leading: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFFFF6600),
                      ),
                      title: const Text(
                        'Painel Administrativo',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.admin);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Sair da conta',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FotoPerfilAvatar extends StatelessWidget {
  const _FotoPerfilAvatar({
    required this.nome,
    required this.fotoPerfil,
    required this.atualizando,
    required this.onAlterarFoto,
    required this.onRemoverFoto,
  });

  final String nome;
  final String? fotoPerfil;
  final bool atualizando;
  final VoidCallback onAlterarFoto;
  final VoidCallback onRemoverFoto;

  bool get _temFoto {
    final foto = fotoPerfil;

    return foto != null && foto.startsWith('data:image');
  }

  @override
  Widget build(BuildContext context) {
    final foto = fotoPerfil;

    Widget conteudo;

    if (_temFoto) {
      final base64Data = foto!.split(',').last;
      final bytes = base64Decode(base64Data);

      conteudo = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 92,
        height: 92,
      );
    } else {
      conteudo = Center(
        child: Text(
          nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Color(0xFFFF6600),
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Material(
          color: const Color(0xFFFFE4D1),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: atualizando
                ? null
                : () {
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6E0DB),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Color(0xFFFF6600),
                                  ),
                                  title: const Text(
                                    'Alterar foto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onAlterarFoto();
                                  },
                                ),
                                if (_temFoto)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    title: const Text(
                                      'Remover foto',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onRemoverFoto();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
            customBorder: const CircleBorder(),
            child: SizedBox(
              height: 92,
              width: 92,
              child: atualizando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6600),
                      ),
                    )
                  : conteudo,
            ),
          ),
        ),
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6600),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
      ],
    );
  }
}

class _AlterarSenhaModal extends StatefulWidget {
  const _AlterarSenhaModal();

  @override
  State<_AlterarSenhaModal> createState() => _AlterarSenhaModalState();
}

class _AlterarSenhaModalState extends State<_AlterarSenhaModal> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _senhaAntigaController = TextEditingController();
  final _novaSenhaController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _senhaAntigaController.dispose();
    _novaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await _authRepository.alterarSenha(
        senhaAntiga: _senhaAntigaController.text.trim(),
        novaSenha: _novaSenhaController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF12A150),
          content: Text('Senha alterada com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
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
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alterar senha',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _senhaAntigaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha antiga',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a senha antiga.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _novaSenhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) {
                final nova = value?.trim() ?? '';
                final antiga = _senhaAntigaController.text.trim();

                if (nova.length < 8) {
                  return 'A nova senha deve ter pelo menos 8 caracteres.';
                }

                if (nova == antiga) {
                  return 'A nova senha precisa ser diferente da antiga.';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        'Salvar nova senha',
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

class _PerfilCard extends StatelessWidget {
  const _PerfilCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFFFF6600),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.black54,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}