import 'package:flutter_bloc/flutter_bloc.dart';
import 'transacao_form_state.dart';
import 'transacao_cubit.dart';
import '../models/transacao.dart';

class TransacaoFormCubit extends Cubit<TransacaoFormState> {

  final TransacaoCubit transacaoCubit;

  TransacaoFormCubit({required this.transacaoCubit}): super(TransacaoFormInitial());

  Future<void> salvarTransacao({
    String? id,
    required String descricao,
    required String valorText,
    required TipoTransacao tipo
  }) async {
    if (descricao.trim().isEmpty) {
      emit(TransacaoFormError('A descrição não pode ser vazia.'));
      return;
    }

    final valor = double.tryParse(valorText.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      emit(TransacaoFormError('Informe um valor válido maior que zero.'));
      return;
    }

    print('Estado Loading');

    emit(TransacaoFormLoading());

    //await Future.delayed(const Duration(seconds: 2));

    try {
      if (id != null) {
        final transacaoAtualizada = Transacao(
          id: id, 
          descricao: descricao, 
          valor: valor, 
          tipo: tipo, 
          data: DateTime.now());
        transacaoCubit.atualizarTransacao(transacaoAtualizada);
        emit(TransacaoFormSuccess("Transação atualizada com sucesso!"));
      } else {
        final dataHoraAtual = DateTime.now();
        final novaTransacao = Transacao(
          id: dataHoraAtual.millisecond.toString(),
          descricao: descricao,
          valor: valor,
          tipo: tipo,
          data: dataHoraAtual
        );

        await transacaoCubit.adicionarTransacao(novaTransacao);
        emit(TransacaoFormSuccess("Transação salva com sucesso!"));
      }
    } catch (e) {
      emit(TransacaoFormError('Falha ao salvar a transação. $e'));
    }

  }

  void resertarEstado() {
    emit(TransacaoFormInitial());
  }

}