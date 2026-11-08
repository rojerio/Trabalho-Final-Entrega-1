abstract class TransacaoFormState {}

class TransacaoFormInitial extends TransacaoFormState {}

class TransacaoFormLoading extends TransacaoFormState {}

class TransacaoFormSuccess extends TransacaoFormState {
  final String mensagem;
  TransacaoFormSuccess(this.mensagem);
}

class TransacaoFormError extends TransacaoFormState {
  final String erro;
  TransacaoFormError(this.erro);
}