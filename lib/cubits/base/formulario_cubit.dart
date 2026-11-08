import 'package:flutter_bloc/flutter_bloc.dart';
import 'lista_cubit.dart';

/// Estados dos formulários de cadastro/edição.
sealed class FormularioState {
  const FormularioState();
}

class FormularioInitial extends FormularioState {
  const FormularioInitial();
}

class FormularioSaving extends FormularioState {
  const FormularioSaving();
}

class FormularioSaved extends FormularioState {
  final String mensagem;
  const FormularioSaved(this.mensagem);
}

class FormularioError extends FormularioState {
  final String mensagem;
  const FormularioError(this.mensagem);
}

/// Controla o estado de salvamento de qualquer formulário.
/// A regra de negócio fica no Cubit da entidade; aqui só o ciclo de estados.
class FormularioCubit extends Cubit<FormularioState> {
  FormularioCubit() : super(const FormularioInitial());

  Future<void> salvar(Future<void> Function() acao, {String mensagem = 'Salvo com sucesso!'}) async {
    emit(const FormularioSaving());
    try {
      await acao();
      emit(FormularioSaved(mensagem));
    } on ValidacaoException catch (e) {
      emit(FormularioError(e.mensagem));
    } catch (e) {
      emit(FormularioError('Falha ao salvar. $e'));
    }
  }

  void resetar() => emit(const FormularioInitial());
}
