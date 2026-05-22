import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';

class NovaSenhaScreen extends StatefulWidget {
  const NovaSenhaScreen({super.key});

  @override
  State<NovaSenhaScreen> createState() => _NovaSenhaScreenState();
}

class _NovaSenhaScreenState extends State<NovaSenhaScreen> {
  final _novaSenhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _obscureText1 = true;
  bool _obscureText2 = true;

  final Color _primaryOrange = const Color(0xFFFF6600);

  void _atualizarSenha(String matricula) async {
    final s1 = _novaSenhaController.text;
    final s2 = _confirmaSenhaController.text;

    if (s1.length < 8) {
      _mostrarErro('A palavra-passe deve ter pelo menos 8 caracteres.');
      return;
    }
    if (s1 != s2) {
      _mostrarErro('As palavras-passe não coincidem.');
      return;
    }

    setState(() => _isLoading = true);
    
    final sucesso = await _authRepo.atualizarSenha(matricula, 'perdeuunicatolica', s1);
    
    if (!mounted) return;
    
    if (sucesso) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao atualizar. Tenta novamente.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final matricula = ModalRoute.of(context)!.settings.arguments as String;

    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F7),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 100, errorBuilder: (c, e, s) => Icon(Icons.security, size: 80, color: _primaryOrange)),
                  const SizedBox(height: 24),
                  const Text('Segurança Obrigatória', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Define a tua nova palavra-passe de acesso.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)) ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NOVA SENHA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _novaSenhaController,
                          obscureText: _obscureText1,
                          decoration: InputDecoration(
                            hintText: 'Mínimo 8 caracteres',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400),
                              onPressed: () => setState(() => _obscureText1 = !_obscureText1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Text('CONFIRMAR SENHA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmaSenhaController,
                          obscureText: _obscureText2,
                          decoration: InputDecoration(
                            hintText: 'Repita a senha',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400),
                              onPressed: () => setState(() => _obscureText2 = !_obscureText2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _atualizarSenha(matricula),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Text('Salvar e Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}