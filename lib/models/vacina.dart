import 'sync_status.dart';

enum SituacaoVacina { emDia, proxima, atrasada, semReforco }

class Vacina implements Entidade {
  static const String tabela = 'vacinas';
  static const List<String> colunasApi = [
    'id', 'tutor_id', 'pet_id', 'clinica_id', 'nome', 'lote', 'data_aplicacao',
    'proxima_dose', 'foto_url', 'updated_at',
  ];

  /// Quantos dias antes da próxima dose ela passa a ser "próxima".
  static const int diasAviso = 30;

  @override
  final String id;
  final String tutorId;
  final String petId;
  final String? clinicaId;
  final String nome;
  final String? lote;
  final DateTime dataAplicacao;
  final DateTime? proximaDose;
  final String? fotoUrl;
  final String? fotoLocal;
  @override
  final DateTime updatedAt;
  @override
  final SyncStatus syncStatus;
  @override
  final bool deleted;

  Vacina({
    required this.id,
    required this.tutorId,
    required this.petId,
    this.clinicaId,
    required this.nome,
    this.lote,
    required this.dataAplicacao,
    this.proximaDose,
    this.fotoUrl,
    this.fotoLocal,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.deleted = false,
  });

  SituacaoVacina get situacao {
    if (proximaDose == null) return SituacaoVacina.semReforco;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (proximaDose!.isBefore(hoje)) return SituacaoVacina.atrasada;
    if (proximaDose!.difference(hoje).inDays <= diasAviso) return SituacaoVacina.proxima;
    return SituacaoVacina.emDia;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'tutor_id': tutorId,
        'pet_id': petId,
        'clinica_id': clinicaId,
        'nome': nome,
        'lote': lote,
        'data_aplicacao': dataSemHora(dataAplicacao),
        'proxima_dose': dataSemHora(proximaDose),
        'foto_url': fotoUrl,
        'foto_local': fotoLocal,
        'updated_at': dataHoraUtc(updatedAt),
        'sync_status': syncStatus.valor,
        'deleted': deleted ? 1 : 0,
      };

  @override
  Map<String, dynamic> toApi() => {
        for (final coluna in colunasApi) coluna: toMap()[coluna],
      };

  factory Vacina.fromMap(Map<String, dynamic> map) => Vacina(
        id: map['id'] as String,
        tutorId: map['tutor_id'] as String,
        petId: map['pet_id'] as String,
        clinicaId: map['clinica_id'] as String?,
        nome: map['nome'] as String,
        lote: map['lote'] as String?,
        dataAplicacao: textoParaData(map['data_aplicacao']) ?? DateTime.now(),
        proximaDose: textoParaData(map['proxima_dose']),
        fotoUrl: map['foto_url'] as String?,
        fotoLocal: map['foto_local'] as String?,
        updatedAt: textoParaData(map['updated_at']) ?? DateTime.now(),
        syncStatus: SyncStatus.fromValor(map['sync_status'] as String?),
        deleted: paraBool(map['deleted']),
      );
}
