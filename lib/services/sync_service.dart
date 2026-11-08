import '../database/petcare_database.dart';
import '../models/sync_status.dart';
import '../repositories/local_repository.dart';
import 'foto_service.dart';
import 'sessao_service.dart';
import 'supabase_api.dart';

/// Sincroniza o banco local com o Supabase.
///
/// 1. Envia cadastros/edições pendentes (pais antes dos filhos).
/// 2. Envia exclusões pendentes (filhos antes dos pais).
/// 3. Baixa o que mudou no servidor desde a última sincronização.
class SyncService {
  final SupabaseApi api;
  final SessaoService sessao;
  final FotoService fotoService;

  /// Ordem de dependência: clínicas e pets antes de consultas e vacinas.
  final List<LocalRepository> repositorios;

  SyncService({
    required this.api,
    required this.sessao,
    required this.fotoService,
    required this.repositorios,
  });

  Future<int> contarPendentes() async {
    var total = 0;
    for (final repositorio in repositorios) {
      total += await repositorio.contarPendentes();
    }
    return total;
  }

  Future<void> sincronizar() async {
    if (!sessao.logado) return;
    await _enviarPendentes();
    await _enviarExclusoes();
    await _baixarAlteracoes();
  }

  Future<void> _enviarPendentes() async {
    for (final repositorio in repositorios) {
      final pendentes = await repositorio.pendentesDeEnvio();
      for (final entidade in pendentes) {
        final dados = entidade.toApi();
        String? fotoUrl;

        if (repositorio.temFoto) {
          fotoUrl = await _enviarFotoSePreciso(repositorio.tabela, entidade);
          if (fotoUrl != null) dados['foto_url'] = fotoUrl;
        }

        await api.upsert(repositorio.tabela, dados);
        await repositorio.marcarSincronizado(entidade.id, fotoUrl: fotoUrl);
      }
    }
  }

  /// Envia a foto tirada offline (foto_local sem foto_url) e devolve a URL.
  Future<String?> _enviarFotoSePreciso(String tabela, Entidade entidade) async {
    final mapa = entidade.toMap();
    final fotoLocal = mapa['foto_local'] as String?;
    final fotoUrl = mapa['foto_url'] as String?;
    if (fotoLocal == null || fotoUrl != null) return null;

    final bytes = await fotoService.lerBytes(fotoLocal);
    if (bytes == null) return null;

    final destino = '${sessao.usuario!.id}/$tabela/${entidade.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return api.enviarFoto(bytes: bytes, destino: destino);
  }

  Future<void> _enviarExclusoes() async {
    for (final repositorio in repositorios.reversed) {
      final ids = await repositorio.pendentesDeExclusao();
      for (final id in ids) {
        await api.excluir(repositorio.tabela, id);
        await repositorio.removerDefinitivo(id);
      }
    }
  }

  Future<void> _baixarAlteracoes() async {
    final banco = PetCareDatabase.instance;
    for (final repositorio in repositorios) {
      final chave = '${sessao.usuario!.id}_${repositorio.tabela}';
      final desde = await banco.ultimaSincronizacao(chave);
      final registros = await api.buscarAlterados(
        repositorio.tabela,
        repositorio.colunasApi,
        desde: desde,
      );

      DateTime? maisRecente = desde;
      for (final registro in registros) {
        try {
          await repositorio.aplicarRemoto(registro);
        } catch (_) {
          // Registro com referência inválida (ex.: pai removido): ignora.
        }
        final data = DateTime.tryParse(registro['updated_at']?.toString() ?? '');
        if (data != null && (maisRecente == null || data.isAfter(maisRecente))) {
          maisRecente = data;
        }
      }

      if (maisRecente != null) {
        await banco.salvarUltimaSincronizacao(chave, maisRecente);
      }
    }
  }
}
