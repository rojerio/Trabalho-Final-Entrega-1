import 'package:sqflite_common/sqflite.dart';
import '../database/petcare_database.dart';
import '../models/sync_status.dart';
import '../services/sessao_service.dart';

/// Operações locais (SQLite) comuns a todas as entidades.
///
/// Toda escrita marca o registro como pendente; o SyncService é quem envia
/// os pendentes para o Supabase e os marca como sincronizados.
class LocalRepository<T extends Entidade> {
  final String tabela;
  final List<String> colunasApi;
  final bool temFoto;
  final T Function(Map<String, dynamic>) fromMap;
  final SessaoService sessao;

  LocalRepository({
    required this.tabela,
    required this.colunasApi,
    required this.fromMap,
    required this.sessao,
    this.temFoto = false,
  });

  Future<Database> get _db => PetCareDatabase.instance.database;

  String get _tutorId => sessao.usuario!.id;

  /// Lista os registros ativos do tutor logado.
  Future<List<T>> listar({String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = await _db;
    final filtro = 'tutor_id = ? AND deleted = 0${where == null ? '' : ' AND ($where)'}';
    final linhas = await db.query(
      tabela,
      where: filtro,
      whereArgs: [_tutorId, ...?whereArgs],
      orderBy: orderBy,
    );
    return linhas.map(fromMap).toList();
  }

  Future<T?> buscarPorId(String id) async {
    final db = await _db;
    final linhas = await db.query(tabela, where: 'id = ?', whereArgs: [id]);
    return linhas.isEmpty ? null : fromMap(linhas.first);
  }

  Future<int> contar({required String where, List<Object?>? whereArgs}) async {
    final db = await _db;
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabela WHERE deleted = 0 AND ($where)',
      whereArgs,
    );
    return (resultado.first['total'] as int?) ?? 0;
  }

  /// Cadastro ou edição feitos pelo usuário (funciona offline).
  Future<void> salvar(T entidade) async {
    final db = await _db;
    final existente = await db.query(
      tabela,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [entidade.id],
    );

    final statusAtual = existente.isEmpty
        ? null
        : SyncStatus.fromValor(existente.first['sync_status'] as String?);
    final novoStatus = (statusAtual == null || statusAtual == SyncStatus.pendingCreate)
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    final dados = entidade.toMap()
      ..['tutor_id'] = _tutorId
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String()
      ..['sync_status'] = novoStatus.valor
      ..['deleted'] = 0;

    await _upsert(db, dados);
  }

  /// Remoção feita pelo usuário. Se o registro nunca foi enviado ao servidor,
  /// é apagado na hora; senão, fica marcado para ser removido na sincronização.
  Future<void> excluir(String id) async {
    final db = await _db;
    await excluirComTransacao(db, id);
  }

  Future<void> excluirComTransacao(DatabaseExecutor db, String id) async {
    final linhas = await db.query(tabela, columns: ['sync_status'], where: 'id = ?', whereArgs: [id]);
    if (linhas.isEmpty) return;
    final status = SyncStatus.fromValor(linhas.first['sync_status'] as String?);
    if (status == SyncStatus.pendingCreate) {
      await db.delete(tabela, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        tabela,
        {
          'deleted': 1,
          'sync_status': SyncStatus.pendingDelete.valor,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ---------- Usado pelo SyncService ----------

  Future<List<T>> pendentesDeEnvio() async {
    final db = await _db;
    final linhas = await db.query(
      tabela,
      where: 'tutor_id = ? AND sync_status IN (?, ?)',
      whereArgs: [_tutorId, SyncStatus.pendingCreate.valor, SyncStatus.pendingUpdate.valor],
      orderBy: 'updated_at ASC',
    );
    return linhas.map(fromMap).toList();
  }

  Future<List<String>> pendentesDeExclusao() async {
    final db = await _db;
    final linhas = await db.query(
      tabela,
      columns: ['id'],
      where: 'tutor_id = ? AND sync_status = ?',
      whereArgs: [_tutorId, SyncStatus.pendingDelete.valor],
    );
    return linhas.map((linha) => linha['id'] as String).toList();
  }

  Future<int> contarPendentes() async {
    final db = await _db;
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabela WHERE tutor_id = ? AND sync_status != ?',
      [_tutorId, SyncStatus.synced.valor],
    );
    return (resultado.first['total'] as int?) ?? 0;
  }

  Future<void> marcarSincronizado(String id, {String? fotoUrl}) async {
    final db = await _db;
    await db.update(
      tabela,
      {
        'sync_status': SyncStatus.synced.valor,
        if (temFoto && fotoUrl != null) 'foto_url': fotoUrl,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removerDefinitivo(String id) async {
    final db = await _db;
    await db.delete(tabela, where: 'id = ?', whereArgs: [id]);
  }

  /// Grava localmente um registro vindo do Supabase.
  /// Regra de conflito: vence a alteração mais recente (last write wins).
  Future<void> aplicarRemoto(Map<String, dynamic> remoto) async {
    final db = await _db;
    final id = remoto['id'] as String;
    final locais = await db.query(tabela, where: 'id = ?', whereArgs: [id]);
    final local = locais.isEmpty ? null : locais.first;

    if (local != null) {
      final statusLocal = SyncStatus.fromValor(local['sync_status'] as String?);
      final dataLocal = DateTime.tryParse(local['updated_at'] as String? ?? '');
      final dataRemota = DateTime.tryParse(remoto['updated_at']?.toString() ?? '');
      final localMaisRecente = dataLocal != null && dataRemota != null && !dataRemota.isAfter(dataLocal);
      if (statusLocal != SyncStatus.synced && localMaisRecente) return;
    }

    final dados = <String, dynamic>{
      for (final coluna in colunasApi) coluna: remoto[coluna],
      'sync_status': SyncStatus.synced.valor,
      'deleted': 0,
    };

    if (temFoto) {
      // Mantém a foto já salva no aparelho se ela for a mesma do servidor.
      final mesmaFoto = local != null && local['foto_url'] == remoto['foto_url'];
      dados['foto_local'] = mesmaFoto ? local['foto_local'] : null;
    }

    await _upsert(db, dados);
  }

  /// Atualiza se existir, insere se não existir.
  /// (Não usamos INSERT OR REPLACE porque ele apagaria os filhos em cascata.)
  Future<void> _upsert(DatabaseExecutor db, Map<String, dynamic> dados) async {
    final alterados = await db.update(tabela, dados, where: 'id = ?', whereArgs: [dados['id']]);
    if (alterados == 0) {
      await db.insert(tabela, dados);
    }
  }
}
