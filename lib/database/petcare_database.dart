import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

/// Banco SQLite local: fonte principal de dados do app (offline-first).
class PetCareDatabase {
  static const String _nomeBanco = 'petcare.db';
  static const int _versao = 1;
  static const String tabelaSyncMeta = 'sync_meta';

  PetCareDatabase._();
  static final PetCareDatabase instance = PetCareDatabase._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _abrir();
    return _database!;
  }

  Future<Database> _abrir() async {
    final caminho = kIsWeb ? _nomeBanco : join(await getDatabasesPath(), _nomeBanco);
    return openDatabase(
      caminho,
      version: _versao,
      onConfigure: (db) async {
        // Necessário para o SQLite respeitar as chaves estrangeiras.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _criarTabelas,
    );
  }

  // Colunas de controle presentes em todas as tabelas sincronizadas.
  static const String _colunasControle = '''
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending_create',
    deleted INTEGER NOT NULL DEFAULT 0
  ''';

  Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE clinicas (
        id TEXT PRIMARY KEY,
        tutor_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        telefone TEXT,
        endereco TEXT,
        latitude REAL,
        longitude REAL,
        $_colunasControle
      )
    ''');

    await db.execute('''
      CREATE TABLE pets (
        id TEXT PRIMARY KEY,
        tutor_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        especie TEXT NOT NULL,
        raca TEXT,
        sexo TEXT NOT NULL,
        data_nascimento TEXT,
        peso_kg REAL,
        observacoes TEXT,
        foto_url TEXT,
        foto_local TEXT,
        $_colunasControle
      )
    ''');

    await db.execute('''
      CREATE TABLE consultas (
        id TEXT PRIMARY KEY,
        tutor_id TEXT NOT NULL,
        pet_id TEXT NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        clinica_id TEXT NOT NULL REFERENCES clinicas(id) ON DELETE RESTRICT,
        data_hora TEXT NOT NULL,
        veterinario TEXT,
        motivo TEXT NOT NULL,
        diagnostico TEXT,
        prescricao TEXT,
        valor REAL,
        foto_url TEXT,
        foto_local TEXT,
        $_colunasControle
      )
    ''');

    await db.execute('''
      CREATE TABLE vacinas (
        id TEXT PRIMARY KEY,
        tutor_id TEXT NOT NULL,
        pet_id TEXT NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        clinica_id TEXT REFERENCES clinicas(id) ON DELETE SET NULL,
        nome TEXT NOT NULL,
        lote TEXT,
        data_aplicacao TEXT NOT NULL,
        proxima_dose TEXT,
        foto_url TEXT,
        foto_local TEXT,
        $_colunasControle
      )
    ''');

    // Guarda, por tabela e por tutor, a data da última sincronização.
    await db.execute('''
      CREATE TABLE $tabelaSyncMeta (
        chave TEXT PRIMARY KEY,
        ultima_sincronizacao TEXT NOT NULL
      )
    ''');
  }

  Future<DateTime?> ultimaSincronizacao(String chave) async {
    final db = await database;
    final linhas = await db.query(tabelaSyncMeta, where: 'chave = ?', whereArgs: [chave]);
    if (linhas.isEmpty) return null;
    return DateTime.tryParse(linhas.first['ultima_sincronizacao'] as String);
  }

  Future<void> salvarUltimaSincronizacao(String chave, DateTime data) async {
    final db = await database;
    await db.insert(
      tabelaSyncMeta,
      {'chave': chave, 'ultima_sincronizacao': data.toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
