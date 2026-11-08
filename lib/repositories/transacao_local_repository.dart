import 'package:sqflite_common/sqflite.dart';
import '../database/database_helper.dart';
import '../models/transacao.dart';

class TransacaoLocalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Transacao>> buscarTransacoes() async {
    final db = await _dbHelper.databaseConnection;

    final List<Map<String, dynamic>> dbresponse = 
      await db.query(
        DatabaseHelper.tabelaTransacoes,
        orderBy: 'data DESC'
      );
    
    return dbresponse.map((row) => 
      Transacao.fromJson(row))
      .toList();
  }

  Future<Transacao> criarTransacao(Transacao transacao) async {
    final db = await _dbHelper.databaseConnection;

    await db.insert(
      DatabaseHelper.tabelaTransacoes, 
      transacao.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );

    return transacao;
  }

  Future<List<Transacao>> getTransacoesPendentes() async {
    final db = await _dbHelper.databaseConnection;
    final List<Map<String, dynamic>> results = await db.query(
        DatabaseHelper.tabelaTransacoes,
        where: 'sincronizado = ?',
        whereArgs: [0]
      );
    return results.map((result) => Transacao.fromJson(result)).toList();
    
  }

  Future<void> marcarComoSincronizado(String id) async {
    final db = await _dbHelper.databaseConnection;

    await db.update(
      DatabaseHelper.tabelaTransacoes,
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

}