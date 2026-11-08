import 'package:flutter/material.dart';

class ResumoSaldoCard extends StatelessWidget {
  final double saldoTotal;
  final double saldoReceitas;
  final double saldoDespesas;

  const ResumoSaldoCard({
    super.key,
    required this.saldoTotal,
    required this.saldoReceitas,
    required this.saldoDespesas
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)
      ),
      color: Colors.teal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Saldo Atual',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${saldoTotal.toStringAsFixed(2)}',
              style: TextStyle(
                color: saldoTotal >= 0 ? Colors.white : Colors.red,
                fontSize: 28,
                fontWeight: FontWeight.bold
              ),
            ),
            const Divider(color: Colors.white, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItemResumo('Receitas', saldoReceitas, Colors.lightGreen),
                SizedBox(height: 30, width: 1),
                _buildItemResumo('Despesas', saldoDespesas, Colors.red)
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildItemResumo(String titulo, double valor, Color cor) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12
          )
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: 16
          )
        )
      ],
    );
  }
}