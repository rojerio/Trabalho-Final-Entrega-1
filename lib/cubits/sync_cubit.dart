import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/eventos_dados.dart';
import '../services/sync_service.dart';

enum SituacaoSync { offline, sincronizando, sincronizado, erro }

class SyncState {
  final SituacaoSync situacao;
  final int pendentes;
  final String? mensagem;
  final DateTime? ultimaSincronizacao;

  const SyncState({
    required this.situacao,
    this.pendentes = 0,
    this.mensagem,
    this.ultimaSincronizacao,
  });

  SyncState copyWith({
    SituacaoSync? situacao,
    int? pendentes,
    String? mensagem,
    DateTime? ultimaSincronizacao,
  }) {
    return SyncState(
      situacao: situacao ?? this.situacao,
      pendentes: pendentes ?? this.pendentes,
      mensagem: mensagem,
      ultimaSincronizacao: ultimaSincronizacao ?? this.ultimaSincronizacao,
    );
  }
}

/// Monitora a conexão e dispara a sincronização:
/// ao abrir o app, ao reconectar, após cada alteração local e manualmente.
class SyncCubit extends Cubit<SyncState> {
  final SyncService syncService;
  final EventosDados eventos;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _conexao;
  StreamSubscription<void>? _alteracoes;
  bool _online = false;
  bool _executando = false;
  bool _repetir = false;

  SyncCubit({required this.syncService, required this.eventos})
      : super(const SyncState(situacao: SituacaoSync.offline));

  Future<void> iniciar() async {
    _conexao = _connectivity.onConnectivityChanged.listen(_aoMudarConexao);
    _alteracoes = eventos.alteracoesLocais.listen((_) => _aoAlterarLocalmente());
    _aoMudarConexao(await _connectivity.checkConnectivity());
  }

  void _aoMudarConexao(List<ConnectivityResult> resultados) {
    final estavaOnline = _online;
    _online = resultados.any((r) => r != ConnectivityResult.none);
    if (_online && !estavaOnline) {
      sincronizar();
    } else if (!_online) {
      _atualizarPendentes(SituacaoSync.offline);
    }
  }

  Future<void> _aoAlterarLocalmente() async {
    if (_online) {
      await sincronizar();
    } else {
      await _atualizarPendentes(SituacaoSync.offline);
    }
  }

  Future<void> sincronizar() async {
    if (isClosed) return;
    if (!_online) {
      await _atualizarPendentes(SituacaoSync.offline, mensagem: 'Sem conexão. Os dados ficam salvos no aparelho.');
      return;
    }
    if (_executando) {
      _repetir = true; // Houve alteração durante a sincronização: roda de novo no fim.
      return;
    }

    _executando = true;
    emit(state.copyWith(situacao: SituacaoSync.sincronizando));
    try {
      do {
        _repetir = false;
        await syncService.sincronizar();
      } while (_repetir);
      eventos.notificarRemoto();
      await _atualizarPendentes(SituacaoSync.sincronizado, ultima: DateTime.now());
    } catch (e) {
      await _atualizarPendentes(
        SituacaoSync.erro,
        mensagem: 'Falha ao sincronizar. Tentaremos de novo na próxima conexão.',
      );
    } finally {
      _executando = false;
    }
  }

  Future<void> _atualizarPendentes(SituacaoSync situacao, {String? mensagem, DateTime? ultima}) async {
    var pendentes = state.pendentes;
    try {
      pendentes = await syncService.contarPendentes();
    } catch (_) {}
    if (isClosed) return;
    emit(state.copyWith(
      situacao: situacao,
      pendentes: pendentes,
      mensagem: mensagem,
      ultimaSincronizacao: ultima,
    ));
  }

  @override
  Future<void> close() async {
    await _conexao?.cancel();
    await _alteracoes?.cancel();
    return super.close();
  }
}
