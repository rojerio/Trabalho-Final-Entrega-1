import 'package:uuid/uuid.dart';
import '../models/consulta.dart';
import '../repositories/historico_repositories.dart';
import '../services/eventos_dados.dart';
import '../services/sessao_service.dart';
import 'base/lista_cubit.dart';

/// Filtro de período da lista de consultas.
enum PeriodoConsulta { todas, ultimos30Dias, ultimoAno }

/// Consultas de um pet.
class ConsultaCubit extends ListaCubit<Consulta> {
  final String petId;
  final ConsultaRepository repository;
  final SessaoService sessao;
  PeriodoConsulta periodo = PeriodoConsulta.todas;

  ConsultaCubit({
    required this.petId,
    required this.repository,
    required this.sessao,
    required EventosDados eventos,
  }) : super(eventos);

  @override
  Future<List<Consulta>> buscar() {
    final agora = DateTime.now();
    final desde = switch (periodo) {
      PeriodoConsulta.todas => null,
      PeriodoConsulta.ultimos30Dias => agora.subtract(const Duration(days: 30)),
      PeriodoConsulta.ultimoAno => DateTime(agora.year - 1, agora.month, agora.day),
    };
    return repository.listarPorPet(petId, desde: desde);
  }

  Future<void> alterarPeriodo(PeriodoConsulta novoPeriodo) async {
    periodo = novoPeriodo;
    await carregar();
  }

  Future<void> salvar({
    Consulta? original,
    required String? clinicaId,
    required DateTime dataHora,
    required String motivo,
    String? veterinario,
    String? diagnostico,
    String? prescricao,
    String valorTexto = '',
    String? novaFotoLocal,
  }) async {
    if (clinicaId == null) throw ValidacaoException('Escolha a clínica da consulta.');
    if (motivo.trim().isEmpty) throw ValidacaoException('Informe o motivo da consulta.');

    double? valor;
    if (valorTexto.trim().isNotEmpty) {
      valor = double.tryParse(valorTexto.replaceAll(',', '.'));
      if (valor == null || valor < 0) throw ValidacaoException('Informe um valor válido.');
    }

    final fotoMudou = novaFotoLocal != null;

    final consulta = Consulta(
      id: original?.id ?? const Uuid().v4(),
      tutorId: sessao.usuario!.id,
      petId: petId,
      clinicaId: clinicaId,
      dataHora: dataHora,
      motivo: motivo.trim(),
      veterinario: _textoOuNulo(veterinario),
      diagnostico: _textoOuNulo(diagnostico),
      prescricao: _textoOuNulo(prescricao),
      valor: valor,
      fotoLocal: fotoMudou ? novaFotoLocal : original?.fotoLocal,
      fotoUrl: fotoMudou ? null : original?.fotoUrl,
      updatedAt: DateTime.now(),
    );

    await repository.salvar(consulta);
    eventos.notificarLocal();
  }

  Future<void> excluir(Consulta consulta) async {
    await repository.excluir(consulta.id);
    eventos.notificarLocal();
  }
}

String? _textoOuNulo(String? texto) {
  if (texto == null || texto.trim().isEmpty) return null;
  return texto.trim();
}
