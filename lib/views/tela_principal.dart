import 'package:flutter/material.dart';
import 'cadastro_transacao_page.dart';
import 'extrato_trasacao_page.dart';

class TelaPrincipal extends StatefulWidget {
  
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {

  int _abaAtual = 0;

  final List<Widget> _telas = [
    const ExtratoTransacaoPage(),
    const CadastroTransacaoPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaAtual,
        children: _telas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaAtual,
        selectedItemColor: Colors.teal,
        onTap: (index) {
          setState(() {
            _abaAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Extrato'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Novo Lançamento'
          )
        ]
      ),
    );
  }

}