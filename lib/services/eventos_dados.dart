import 'dart:async';

/// Avisa os Cubits quando os dados locais mudam, para as telas recarregarem.
class EventosDados {
  final _todas = StreamController<void>.broadcast();
  final _locais = StreamController<void>.broadcast();

  /// Qualquer mudança (feita pelo usuário ou vinda do servidor).
  Stream<void> get alteracoes => _todas.stream;

  /// Só as mudanças feitas pelo usuário (disparam a sincronização).
  Stream<void> get alteracoesLocais => _locais.stream;

  /// Chamado pelos Cubits após cadastrar, editar ou remover.
  void notificarLocal() {
    _locais.add(null);
    _todas.add(null);
  }

  /// Chamado pela sincronização após gravar dados do servidor.
  void notificarRemoto() => _todas.add(null);

  void dispose() {
    _todas.close();
    _locais.close();
  }
}
