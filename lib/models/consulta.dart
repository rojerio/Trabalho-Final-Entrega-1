import 'sync_status.dart';

class Consulta implements Entidade {
  static const String tabela = 'consultas';
  static const List<String> colunasApi = [
    'id', 'tutor_id', 'pet_id', 'clinica_id', 'data_hora', 'veterinario',
    'motivo', 'diagnostico', 'prescricao', 'valor', 'foto_url', 'updated_at',
  ];

  @override
  final String id;
  final String tutorId;
  final String petId;
  final String clinicaId;
  final DateTime dataHora;
  final String? veterinario;
  final String motivo;
  final String? diagnostico;
  final String? prescricao;
  final double? valor;
  final String? fotoUrl;
  final String? fotoLocal;
  @override
  final DateTime updatedAt;
  @override
  final SyncStatus syncStatus;
  @override
  final bool deleted;

  Consulta({
    required this.id,
    required this.tutorId,
    required this.petId,
    required this.clinicaId,
    required this.dataHora,
    this.veterinario,
    required this.motivo,
    this.diagnostico,
    this.prescricao,
    this.valor,
    this.fotoUrl,
    this.fotoLocal,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.deleted = false,
  });

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'tutor_id': tutorId,
        'pet_id': petId,
        'clinica_id': clinicaId,
        'data_hora': dataHoraUtc(dataHora),
        'veterinario': veterinario,
        'motivo': motivo,
        'diagnostico': diagnostico,
        'prescricao': prescricao,
        'valor': valor,
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

  factory Consulta.fromMap(Map<String, dynamic> map) => Consulta(
        id: map['id'] as String,
        tutorId: map['tutor_id'] as String,
        petId: map['pet_id'] as String,
        clinicaId: map['clinica_id'] as String,
        dataHora: textoParaDataLocal(map['data_hora']) ?? DateTime.now(),
        veterinario: map['veterinario'] as String?,
        motivo: map['motivo'] as String,
        diagnostico: map['diagnostico'] as String?,
        prescricao: map['prescricao'] as String?,
        valor: paraDouble(map['valor']),
        fotoUrl: map['foto_url'] as String?,
        fotoLocal: map['foto_local'] as String?,
        updatedAt: textoParaData(map['updated_at']) ?? DateTime.now(),
        syncStatus: SyncStatus.fromValor(map['sync_status'] as String?),
        deleted: paraBool(map['deleted']),
      );
}
