import '../models/clinica.dart';
import '../models/consulta.dart';
import '../models/vacina.dart';
import '../services/sessao_service.dart';
import 'local_repository.dart';

class ClinicaRepository extends LocalRepository<Clinica> {
  final LocalRepository<Consulta> consultas;
  final LocalRepository<Vacina> vacinas;

  ClinicaRepository({
    required SessaoService sessao,
    required this.consultas,
    required this.vacinas,
  }) : super(
          tabela: Clinica.tabela,
          colunasApi: Clinica.colunasApi,
          fromMap: Clinica.fromMap,
          sessao: sessao,
        );

  Future<List<Clinica>> listarClinicas() => listar(orderBy: 'nome COLLATE NOCASE ASC');

  /// Quantas consultas e vacinas ativas usam esta clínica.
  Future<int> contarVinculos(String clinicaId) async {
    final totalConsultas = await consultas.contar(where: 'clinica_id = ?', whereArgs: [clinicaId]);
    final totalVacinas = await vacinas.contar(where: 'clinica_id = ?', whereArgs: [clinicaId]);
    return totalConsultas + totalVacinas;
  }
}
