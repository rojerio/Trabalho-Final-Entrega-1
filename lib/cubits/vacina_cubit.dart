import 'package:uuid/uuid.dart';
import '../models/vacina.dart';
import '../repositories/historico_repositories.dart';
import '../services/eventos_dados.dart';
import '../services/sessao_service.dart';
import 'base/lista_cubit.dart';

/// Vacinas de um pet.
class VacinaCubit extends ListaCubit<Vacina> {
  final String petId;
  final VacinaRepository repository;
  final SessaoService sessao;

  VacinaCubit({
    required this.petId,
    required this.repository,
    required this.sessao,
    required EventosDados eventos,
  }) : super(eventos);

  @override
  Future<List<Vacina>> buscar() async {
    final vacinas = await repository.listarPorPet(petId);
    // Atrasadas e próximas aparecem primeiro.
    int prioridade(Vacina v) => switch (v.situacao) {
          SituacaoVacina.atrasada => 0,
          SituacaoVacina.proxima => 1,
          SituacaoVacina.emDia => 2,
          SituacaoVacina.semReforco => 3,
        };
    vacinas.sort((a, b) {
      final porSituacao = prioridade(a).compareTo(prioridade(b));
      if (porSituacao != 0) return porSituacao;
      return b.dataAplicacao.compareTo(a.dataAplicacao);
    });
    return vacinas;
  }

  Future<void> salvar({
    Vacina? original,
    required String nome,
    String? lote,
    String? clinicaId,
    required DateTime dataAplicacao,
    DateTime? proximaDose,
    String? novaFotoLocal,
  }) async {
    if (nome.trim().isEmpty) throw ValidacaoException('Informe o nome da vacina.');
    if (dataAplicacao.isAfter(DateTime.now())) {
      throw ValidacaoException('A data de aplicação não pode estar no futuro.');
    }
    if (proximaDose != null && !proximaDose.isAfter(dataAplicacao)) {
      throw ValidacaoException('A próxima dose deve ser depois da data de aplicação.');
    }

    final fotoMudou = novaFotoLocal != null;

    final vacina = Vacina(
      id: original?.id ?? const Uuid().v4(),
      tutorId: sessao.usuario!.id,
      petId: petId,
      clinicaId: clinicaId,
      nome: nome.trim(),
      lote: (lote == null || lote.trim().isEmpty) ? null : lote.trim(),
      dataAplicacao: dataAplicacao,
      proximaDose: proximaDose,
      fotoLocal: fotoMudou ? novaFotoLocal : original?.fotoLocal,
      fotoUrl: fotoMudou ? null : original?.fotoUrl,
      updatedAt: DateTime.now(),
    );

    await repository.salvar(vacina);
    eventos.notificarLocal();
  }

  Future<void> excluir(Vacina vacina) async {
    await repository.excluir(vacina.id);
    eventos.notificarLocal();
  }
}
