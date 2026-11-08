import 'package:flutter_bloc/flutter_bloc.dart';
import 'transacao_state.dart';
import '../models/transacao.dart';
import '../repositories/transacao_repository.dart';
import '../repositories/transacao_local_repository.dart';

class TransacaoCubit extends Cubit<TransacaoState>{
  List<Transacao> _transacoes = [];
  final TransacaoRepository repositoryApi;
  final TransacaoLocalRepository repositoryDatabase;

  TransacaoCubit({
    required this.repositoryApi,
    required this.repositoryDatabase
  }) : super(TransacaoLoaded(
    transacoes: [], 
    saldoTotal: 0.0, 
    saldoReceitas: 0.0, 
    saldoDespesas: 0.0)
  );

  Future<void> carregarTransacoes() async {
    try {
      _transacoes = await repositoryApi.buscarTransacoes();

      for (var transacao in _transacoes) {
        await repositoryDatabase.criarTransacao(transacao.copy(sincronizado: true));
      }
    } catch (e) {
      _transacoes = await repositoryDatabase.buscarTransacoes();
    }
    _calcularSaldos();
  }

  Future<void> adicionarTransacao(Transacao transacao) async {
    Transacao novaTransacao;
    try {
      novaTransacao = await repositoryApi.criarTransacao(transacao.copy(sincronizado: true));
      await repositoryDatabase.criarTransacao(transacao.copy(sincronizado: true));      
    } catch (e) {
      novaTransacao = await repositoryDatabase.criarTransacao(transacao.copy(sincronizado: false));
    }
    _transacoes.insert(0, novaTransacao);
    _calcularSaldos();    
  }

  Future<void> atualizarTransacao(Transacao transacaoAtualizada) async {
    //await repository.atualizarTransacao(transacaoAtualizada);
    //await carregarTransacoes();

    /*final index = _transacoes.indexWhere((item) => item.id == transacaoAtualizada.id);

    if (index != -1) {
      _transacoes[index] = transacaoAtualizada;
      _calcularSaldos();
    }*/
  }

  Future<void> excluirTransacao(String id) async {
    //try {
    //  await repository.excluirTransacao(id);
    //  await carregarTransacoes();    
    //} catch (e) {
    //  emit(TransacaoError(message: 'Erro ao excluir: $e'));
    //}
    
    // _transacoes.removeWhere((item) => item.id == id);
    // _calcularSaldos();
  }

  void _calcularSaldos() {
    double saldoReceitas = 0.0;
    double saldoDespesas = 0.0;

    for (final item in _transacoes) {
      if (item.tipo == TipoTransacao.receita) {
        saldoReceitas += item.valor;
      } else {
        saldoDespesas += item.valor;
      }
    }

    final saldoTotal = saldoReceitas - saldoDespesas;
    
    emit(TransacaoLoaded(
      transacoes: List.unmodifiable(_transacoes),
      saldoTotal: saldoTotal,
      saldoReceitas: saldoReceitas,
      saldoDespesas: saldoDespesas)
    );
  }

}
