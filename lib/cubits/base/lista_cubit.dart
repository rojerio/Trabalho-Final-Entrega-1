import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/eventos_dados.dart';
import 'lista_state.dart';

/// Erro de regra de negócio, com mensagem para mostrar ao usuário.
class ValidacaoException implements Exception {
  final String mensagem;
  ValidacaoException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Base dos Cubits de listagem: carrega do banco local e recarrega sozinho
/// sempre que algum dado muda (inclusive após a sincronização).
abstract class ListaCubit<T> extends Cubit<ListaState<T>> {
  final EventosDados eventos;
  StreamSubscription<void>? _assinatura;

  ListaCubit(this.eventos) : super(ListaInitial<T>()) {
    _assinatura = eventos.alteracoes.listen((_) => carregar(silencioso: true));
  }

  /// Busca os itens no repositório local.
  Future<List<T>> buscar();

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) emit(ListaLoading<T>());
    try {
      final itens = await buscar();
      if (isClosed) return;
      emit(itens.isEmpty ? ListaEmpty<T>() : ListaLoaded<T>(itens));
    } catch (e) {
      if (isClosed) return;
      emit(ListaError<T>('Não foi possível carregar os dados. $e'));
    }
  }

  @override
  Future<void> close() async {
    await _assinatura?.cancel();
    return super.close();
  }
}
