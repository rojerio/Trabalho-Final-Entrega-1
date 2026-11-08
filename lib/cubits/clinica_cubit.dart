import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/clinica.dart';
import '../repositories/clinica_repository.dart';
import '../services/eventos_dados.dart';
import '../services/localizacao_service.dart';
import '../services/sessao_service.dart';
import 'base/lista_cubit.dart';
import 'base/lista_state.dart';

/// Clínica com a distância até o usuário (quando o GPS está disponível).
class ClinicaItem {
  final Clinica clinica;
  final double? distanciaKm;
  ClinicaItem(this.clinica, this.distanciaKm);
}

class ClinicaCubit extends ListaCubit<ClinicaItem> {
  final ClinicaRepository repository;
  final SessaoService sessao;
  final LocalizacaoService localizacao;

  LatLng? posicaoUsuario;
  bool _buscouPosicao = false;

  ClinicaCubit({
    required this.repository,
    required this.sessao,
    required this.localizacao,
    required EventosDados eventos,
  }) : super(eventos);

  @override
  Future<List<ClinicaItem>> buscar() async {
    if (!_buscouPosicao) {
      _buscouPosicao = true;
      posicaoUsuario = await localizacao.tentarPosicaoAtual();
    }

    final clinicas = await repository.listarClinicas();
    final itens = clinicas.map((clinica) {
      double? distancia;
      if (posicaoUsuario != null && clinica.temLocalizacao) {
        distancia = localizacao.distanciaKm(
          posicaoUsuario!,
          LatLng(clinica.latitude!, clinica.longitude!),
        );
      }
      return ClinicaItem(clinica, distancia);
    }).toList();

    // Mais próximas primeiro; clínicas sem localização vão para o fim.
    itens.sort((a, b) {
      if (a.distanciaKm == null && b.distanciaKm == null) {
        return a.clinica.nome.toLowerCase().compareTo(b.clinica.nome.toLowerCase());
      }
      if (a.distanciaKm == null) return 1;
      if (b.distanciaKm == null) return -1;
      return a.distanciaKm!.compareTo(b.distanciaKm!);
    });
    return itens;
  }

  /// Lê o GPS de novo e reordena a lista.
  Future<void> atualizarLocalizacao() async {
    posicaoUsuario = await localizacao.tentarPosicaoAtual();
    _buscouPosicao = true;
    await carregar(silencioso: true);
  }

  /// Lista simples de clínicas, usada nos formulários de consulta e vacina.
  List<Clinica> get clinicas {
    final estado = state;
    if (estado is! ListaLoaded<ClinicaItem>) return [];
    final lista = estado.itens.map((item) => item.clinica).toList();
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  String nomeDaClinica(String? id) {
    if (id == null) return 'Sem clínica';
    for (final clinica in clinicas) {
      if (clinica.id == id) return clinica.nome;
    }
    return 'Clínica removida';
  }

  Future<void> salvar({
    Clinica? original,
    required String nome,
    String? telefone,
    String? endereco,
    LatLng? posicao,
  }) async {
    if (nome.trim().isEmpty) throw ValidacaoException('Informe o nome da clínica.');
    if (posicao == null && (endereco == null || endereco.trim().isEmpty)) {
      throw ValidacaoException('Informe o endereço ou marque a localização no mapa.');
    }

    final clinica = Clinica(
      id: original?.id ?? const Uuid().v4(),
      tutorId: sessao.usuario!.id,
      nome: nome.trim(),
      telefone: _textoOuNulo(telefone),
      endereco: _textoOuNulo(endereco),
      latitude: posicao?.latitude,
      longitude: posicao?.longitude,
      updatedAt: DateTime.now(),
    );

    await repository.salvar(clinica);
    eventos.notificarLocal();
  }

  /// Regra: clínica com consultas ou vacinas vinculadas não pode ser removida.
  Future<void> excluir(Clinica clinica) async {
    final vinculos = await repository.contarVinculos(clinica.id);
    if (vinculos > 0) {
      throw ValidacaoException(
        'Não é possível remover: há $vinculos registro(s) de consulta ou vacina nesta clínica.',
      );
    }
    await repository.excluir(clinica.id);
    eventos.notificarLocal();
  }
}

String? _textoOuNulo(String? texto) {
  if (texto == null || texto.trim().isEmpty) return null;
  return texto.trim();
}
