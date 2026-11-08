import 'sync_status.dart';

class Clinica implements Entidade {
  static const String tabela = 'clinicas';
  static const List<String> colunasApi = [
    'id', 'tutor_id', 'nome', 'telefone', 'endereco', 'latitude', 'longitude',
    'updated_at',
  ];

  @override
  final String id;
  final String tutorId;
  final String nome;
  final String? telefone;
  final String? endereco;
  final double? latitude;
  final double? longitude;
  @override
  final DateTime updatedAt;
  @override
  final SyncStatus syncStatus;
  @override
  final bool deleted;

  Clinica({
    required this.id,
    required this.tutorId,
    required this.nome,
    this.telefone,
    this.endereco,
    this.latitude,
    this.longitude,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.deleted = false,
  });

  bool get temLocalizacao => latitude != null && longitude != null;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'tutor_id': tutorId,
        'nome': nome,
        'telefone': telefone,
        'endereco': endereco,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': dataHoraUtc(updatedAt),
        'sync_status': syncStatus.valor,
        'deleted': deleted ? 1 : 0,
      };

  @override
  Map<String, dynamic> toApi() => {
        for (final coluna in colunasApi) coluna: toMap()[coluna],
      };

  factory Clinica.fromMap(Map<String, dynamic> map) => Clinica(
        id: map['id'] as String,
        tutorId: map['tutor_id'] as String,
        nome: map['nome'] as String,
        telefone: map['telefone'] as String?,
        endereco: map['endereco'] as String?,
        latitude: paraDouble(map['latitude']),
        longitude: paraDouble(map['longitude']),
        updatedAt: textoParaData(map['updated_at']) ?? DateTime.now(),
        syncStatus: SyncStatus.fromValor(map['sync_status'] as String?),
        deleted: paraBool(map['deleted']),
      );
}
