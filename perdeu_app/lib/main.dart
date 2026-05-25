import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/routes/app_routes.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/nova_senha_screen.dart';
import 'presentation/screens/auth/recuperacao_screen.dart';
import 'presentation/screens/home/main_screen.dart';
import 'presentation/screens/detalhes/detalhes_screen.dart';

import 'presentation/screens/wizard/wizard_tipo_screen.dart';
import 'presentation/screens/wizard/wizard_categoria_screen.dart';
import 'presentation/screens/wizard/wizard_local_screen.dart';
import 'presentation/screens/wizard/wizard_data_hora_screen.dart';
import 'presentation/screens/wizard/wizard_detalhes_screen.dart';
import 'presentation/screens/wizard/wizard_revisao_screen.dart';

void main() {
  runApp(const PerdeuApp());
}

class PerdeuApp extends StatelessWidget {
  const PerdeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6600);

    return MaterialApp(
      title: 'Perdeu - UniCatólica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryOrange,
          primary: primaryOrange,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E0DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E0DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryOrange,
              width: 1.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.novaSenha: (context) => const NovaSenhaScreen(),
        AppRoutes.recuperarSenha: (context) => const RecuperacaoScreen(),
        AppRoutes.home: (context) => const MainScreen(),

        AppRoutes.wizardTipo: (context) => const WizardTipoScreen(),
        AppRoutes.wizardCategoria: (context) => const WizardCategoriaScreen(),
        AppRoutes.wizardLocal: (context) => const WizardLocalScreen(),
        AppRoutes.wizardDataHora: (context) => const WizardDataHoraScreen(),
        AppRoutes.wizardDetalhes: (context) => const WizardDetalhesScreen(),
        AppRoutes.wizardRevisao: (context) => const WizardRevisaoScreen(),

        AppRoutes.detalhes: (context) => const DetalhesScreen(),
      },
    );
  }
}