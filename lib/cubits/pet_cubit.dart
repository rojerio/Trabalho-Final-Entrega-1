import 'package:uuid/uuid.dart';
import '../models/pet.dart';
import '../repositories/pet_repository.dart';
import '../services/eventos_dados.dart';
import '../services/sessao_service.dart';
import 'base/lista_cubit.dart';
import 'base/lista_state.dart';

class PetCubit extends ListaCubit<Pet> {
  final PetRepository repository;
  final SessaoService sessao;

  PetCubit({required this.repository, required this.sessao, required EventosDados eventos})
      : super(eventos);

  @override
  Future<List<Pet>> buscar() => repository.listarPets();

  /// Pet atual na lista (usado pela tela de detalhe).
  Pet? porId(String id) {
    final estado = state;
    if (estado is! ListaLoaded<Pet>) return null;
    for (final pet in estado.itens) {
      if (pet.id == id) return pet;
    }
    return null;
  }

  Future<void> salvar({
    Pet? original,
    required String nome,
    required String especie,
    String? raca,
    required String sexo,
    DateTime? dataNascimento,
    String pesoTexto = '',
    String? observacoes,
    String? novaFotoLocal,
  }) async {
    if (nome.trim().isEmpty) throw ValidacaoException('Informe o nome do pet.');
    if (especie.trim().isEmpty) throw ValidacaoException('Informe a espécie do pet.');
    if (dataNascimento != null && dataNascimento.isAfter(DateTime.now())) {
      throw ValidacaoException('A data de nascimento não pode estar no futuro.');
    }

    double? peso;
    if (pesoTexto.trim().isNotEmpty) {
      peso = double.tryParse(pesoTexto.replaceAll(',', '.'));
      if (peso == null || peso <= 0) throw ValidacaoException('Informe um peso válido, maior que zero.');
    }

    // Se a foto mudou, a URL antiga deixa de valer e a nova será enviada na sincronização.
    final fotoMudou = novaFotoLocal != null;

    final pet = Pet(
      id: original?.id ?? const Uuid().v4(),
      tutorId: sessao.usuario!.id,
      nome: nome.trim(),
      especie: especie.trim(),
      raca: _textoOuNulo(raca),
      sexo: sexo,
      dataNascimento: dataNascimento,
      pesoKg: peso,
      observacoes: _textoOuNulo(observacoes),
      fotoLocal: fotoMudou ? novaFotoLocal : original?.fotoLocal,
      fotoUrl: fotoMudou ? null : original?.fotoUrl,
      updatedAt: DateTime.now(),
    );

    await repository.salvar(pet);
    eventos.notificarLocal();
  }

  Future<void> excluir(Pet pet) async {
    await repository.excluirComHistorico(pet.id);
    eventos.notificarLocal();
  }
}

String? _textoOuNulo(String? texto) {
  if (texto == null || texto.trim().isEmpty) return null;
  return texto.trim();
}
