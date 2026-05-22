import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/routes/app_routes.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/nova_senha_screen.dart';
import 'presentation/screens/auth/recuperacao_screen.dart';

void main() {
  runApp(const PerdeuApp());
}

class PerdeuApp extends StatelessWidget {
  const PerdeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perdeu - UniCatólica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
        // Tipografia premium conforme documentação
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.novaSenha: (context) => const NovaSenhaScreen(),
        AppRoutes.recuperarSenha: (context) => const RecuperacaoScreen(),
        // Uma Home provisória só para não quebrar o redirecionamento de sucesso
        AppRoutes.home: (context) => const Scaffold(
          body: Center(child: Text('Bem-vindo ao Feed (Módulo 2 em breve!)')),
        ),
      },
    );
  }
}