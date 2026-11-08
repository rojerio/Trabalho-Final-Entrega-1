import '../models/transacao.dart';

abstract class TransacaoState {}

class TransacaoLoaded extends TransacaoState {
  final List<Transacao> transacoes;
  final double saldoTotal;
  final double saldoReceitas;
  final double saldoDespesas;

  TransacaoLoaded({
    required this.transacoes,
    required this.saldoTotal,
    required this.saldoReceitas,
    required this.saldoDespesas
  });
  
}

class TransacaoError extends TransacaoState {
  final String message;
  TransacaoError({required this.message});
}