import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'sistema_financeiro.db';
  static const int _databaseVersion = 2;
  static const String tabelaTransacoes = 'transacoes';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _databaseConnection;

  Future<Database> get databaseConnection async {
    if (_databaseConnection != null) {
      return _databaseConnection!;
    }
    _databaseConnection = await _initDatabase();
    return _databaseConnection!;
  }

  Future<Database> _initDatabase() async {
    String path;
    if (kIsWeb) {
      path = _databaseName;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _databaseName);
    }
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tabelaTransacoes (
        id TEXT PRIMARY KEY,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        sincronizado INT NOT NULL DEFAULT 1
      )
    ''');
  }
}