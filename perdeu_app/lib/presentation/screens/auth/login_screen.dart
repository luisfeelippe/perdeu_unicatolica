import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _matriculaController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authRepo = AuthRepository();
  
  bool _obscureText = true;
  bool _isLoading = false;
  String? _erroMatricula;
  String? _erroSenha;

  // Cor principal extraída do protótipo
  final Color _primaryOrange = const Color(0xFFFF6600); 

  void _fazerLogin() async {
    setState(() {
      _erroMatricula = _matriculaController.text.isEmpty ? 'Obrigatório' : null;
      _erroSenha = _senhaController.text.isEmpty ? 'Obrigatório' : null;
    });

    if (_erroMatricula != null || _erroSenha != null) return;

    setState(() => _isLoading = true);

    // No protótipo não há checkbox de "manter conectado", então passamos true por padrão
    final result = await _authRepo.login(
      _matriculaController.text, 
      _senhaController.text, 
      true 
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['sucesso'] == true) {
      if (result['primeiro_acesso'] == true) {
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.novaSenha,
          arguments: _matriculaController.text,
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciais inválidas'), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7), // Fundo levemente off-white do protótipo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dinâmica
                Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 100, color: _primaryOrange),
                ),
                const SizedBox(height: 40),
                
                // Card Branco com Sombra
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Input Matrícula
                      Text('MATRÍCULA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _matriculaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0000000',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          errorText: _erroMatricula,
                          suffixIcon: Icon(Icons.badge_outlined, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Input Senha
                      Text('SENHA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _senhaController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          errorText: _erroSenha,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.lock_outline : Icons.lock_open_outlined, color: Colors.grey.shade400),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Botão Entrar
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _fazerLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.login_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Botão Esqueci minha senha (Agora sem borda!)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.recuperarSenha),
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Esqueci minha senha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}