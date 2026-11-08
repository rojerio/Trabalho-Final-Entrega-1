import '../models/consulta.dart';
import '../models/vacina.dart';
import '../services/sessao_service.dart';
import 'local_repository.dart';

class ConsultaRepository extends LocalRepository<Consulta> {
  ConsultaRepository({required SessaoService sessao})
      : super(
          tabela: Consulta.tabela,
          colunasApi: Consulta.colunasApi,
          fromMap: Consulta.fromMap,
          sessao: sessao,
          temFoto: true,
        );

  Future<List<Consulta>> listarPorPet(String petId, {DateTime? desde}) {
    if (desde == null) {
      return listar(where: 'pet_id = ?', whereArgs: [petId], orderBy: 'data_hora DESC');
    }
    return listar(
      where: 'pet_id = ? AND data_hora >= ?',
      whereArgs: [petId, desde.toUtc().toIso8601String()],
      orderBy: 'data_hora DESC',
    );
  }
}

class VacinaRepository extends LocalRepository<Vacina> {
  VacinaRepository({required SessaoService sessao})
      : super(
          tabela: Vacina.tabela,
          colunasApi: Vacina.colunasApi,
          fromMap: Vacina.fromMap,
          sessao: sessao,
          temFoto: true,
        );

  Future<List<Vacina>> listarPorPet(String petId) =>
      listar(where: 'pet_id = ?', whereArgs: [petId], orderBy: 'data_aplicacao DESC');
}
