import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/transacao_cubit.dart';
import '../cubits/transacao_state.dart';
import '../models/transacao.dart';
import '../views/cadastro_transacao_page.dart';
import 'widgets/resumo_saldo_card.dart';

class ExtratoTransacaoPage extends StatelessWidget {

  const ExtratoTransacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extrato Financeiro"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: BlocBuilder<TransacaoCubit, TransacaoState>(
          builder: (context, state) {
            if (state is TransacaoLoaded) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //Construir o card de saldos
                    ResumoSaldoCard(
                      saldoTotal: state.saldoTotal,
                      saldoReceitas: state.saldoReceitas,
                      saldoDespesas: state.saldoDespesas
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Histórico de Transações",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: state.transacoes.isEmpty
                        ? const Center(
                          child: Text(
                            "Nenhuma transação registrata.",
                            style: TextStyle(color: Colors.grey)
                          ),
                        )
                        : ListView.builder(
                          itemCount: state.transacoes.length,
                          itemBuilder: (context, index) {
                            final transacao = state.transacoes[index];
                            final isReceita = transacao.tipo == TipoTransacao.receita;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isReceita ? Colors.green.shade200 : Colors.red.shade200,
                                  child: Icon(
                                    isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: Colors.white//isReceita ? Colors.green : Colors.red
                                  ),
                                ),
                                title: Text(
                                  transacao.descricao,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${transacao.data.day}/${transacao.data.month}/${transacao.data.year}'
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isReceita ? '+' : '-'} R\$ ${transacao.valor.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isReceita ? Colors.green : Colors.red
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => CadastroTransacaoPage(
                                              transacaoParaEdicao: transacao
                                            )
                                          )
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue
                                      )
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _dialogDelete(context, transacao);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.deepOrange
                                      )
                                    )
                                  ]
                                )
                              ),
                            );
                          }
                        )
                    )
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
        )
      ),
    );
  }

  void _dialogDelete(BuildContext context, Transacao transacao) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir Transação'),
          content: Text('Tem certeza que deseja remover a transação ${transacao.descricao} no valor de ${transacao.valor.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                context.read<TransacaoCubit>().excluirTransacao(transacao.id);
                Navigator.of(dialogContext).pop();
              }, 
              child: const Text('Excluir', style: TextStyle(color: Colors.white))
            )
          ],
        );
      }
    );
  }

}