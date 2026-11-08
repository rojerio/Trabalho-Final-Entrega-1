import 'package:flutter/material.dart';
import 'clinicas/clinica_list_page.dart';
import 'pets/pet_list_page.dart';

/// Tela principal com as abas Pets e Clínicas.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _abaAtual = 0;

  static const List<Widget> _telas = [
    PetListPage(),
    ClinicaListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _abaAtual, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (index) => setState(() => _abaAtual = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital),
            label: 'Clínicas',
          ),
        ],
      ),
    );
  }
}
