/// Estados das telas de listagem. Toda tela principal trata os cinco.
sealed class ListaState<T> {
  const ListaState();
}

class ListaInitial<T> extends ListaState<T> {
  const ListaInitial();
}

class ListaLoading<T> extends ListaState<T> {
  const ListaLoading();
}

class ListaLoaded<T> extends ListaState<T> {
  final List<T> itens;
  const ListaLoaded(this.itens);
}

class ListaEmpty<T> extends ListaState<T> {
  const ListaEmpty();
}

class ListaError<T> extends ListaState<T> {
  final String mensagem;
  const ListaError(this.mensagem);
}
