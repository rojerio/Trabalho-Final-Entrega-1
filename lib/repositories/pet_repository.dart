import '../database/petcare_database.dart';
import '../models/consulta.dart';
import '../models/pet.dart';
import '../models/vacina.dart';
import '../services/sessao_service.dart';
import 'local_repository.dart';

class PetRepository extends LocalRepository<Pet> {
  final LocalRepository<Consulta> consultas;
  final LocalRepository<Vacina> vacinas;

  PetRepository({
    required SessaoService sessao,
    required this.consultas,
    required this.vacinas,
  }) : super(
          tabela: Pet.tabela,
          colunasApi: Pet.colunasApi,
          fromMap: Pet.fromMap,
          sessao: sessao,
          temFoto: true,
        );

  Future<List<Pet>> listarPets() => listar(orderBy: 'nome COLLATE NOCASE ASC');

  /// Remove o pet junto com as consultas e vacinas dele (cascata).
  Future<void> excluirComHistorico(String petId) async {
    final db = await PetCareDatabase.instance.database;
    await db.transaction((txn) async {
      for (final repositorio in <LocalRepository>[consultas, vacinas]) {
        final filhos = await txn.query(
          repositorio.tabela,
          columns: ['id'],
          where: 'pet_id = ? AND deleted = 0',
          whereArgs: [petId],
        );
        for (final filho in filhos) {
          await repositorio.excluirComTransacao(txn, filho['id'] as String);
        }
      }
      await excluirComTransacao(txn, petId);
    });
  }
}
