import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class RecuperacaoScreen extends StatefulWidget {
  const RecuperacaoScreen({super.key});

  @override
  State<RecuperacaoScreen> createState() => _RecuperacaoScreenState();
}

class _RecuperacaoScreenState extends State<RecuperacaoScreen> {
  final _matriculaController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  String? _mensagemSucesso;

  // Nossa cor principal
  final Color _primaryOrange = const Color(0xFFFF6600);

  void _enviarLink() async {
    if (_matriculaController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _mensagemSucesso = null;
    });

    final msg = await _authRepo.recuperarSenha(_matriculaController.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _mensagemSucesso = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7), // Mesmo fundo off-white do Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Recuperar Senha', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset_rounded, size: 80, color: _primaryOrange),
                const SizedBox(height: 24),
                Text(
                  'Esqueceu a senha?', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Informe a tua matrícula abaixo. Se for válida, enviaremos um link de recuperação para o e-mail.', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                
                // Mensagem de Sucesso (Regra do Silêncio) estilizada
                if (_mensagemSucesso != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _mensagemSucesso!, 
                            style: TextStyle(color: Colors.green.shade900, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      Text(
                        'MATRÍCULA', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _matriculaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0000000',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          suffixIcon: Icon(Icons.badge_outlined, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), 
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), 
                            borderSide: BorderSide(color: _primaryOrange),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Botão Enviar Link
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _enviarLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('Enviar Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}