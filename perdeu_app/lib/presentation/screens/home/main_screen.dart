import 'package:flutter/material.dart';

import 'atualizacoes_view.dart';
import 'home_view.dart';
import 'objetos_view.dart';
import 'perfil_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceAtual = 0;

  void _mudarAba(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6600);

    final telas = [
      HomeView(
        onAbrirAtualizacoes: () => _mudarAba(2),
        onAbrirObjetos: () => _mudarAba(1),
        onAbrirPerfil: () => _mudarAba(3),
      ),
      const ObjetosView(),
      const AtualizacoesView(),
      const PerfilView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _indiceAtual,
        children: telas,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE4D1),
        selectedIndex: _indiceAtual,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _mudarAba,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryOrange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: primaryOrange),
            label: 'Objetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications, color: primaryOrange),
            label: 'Atualizações',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: primaryOrange),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}