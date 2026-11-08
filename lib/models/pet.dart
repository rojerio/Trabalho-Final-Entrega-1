import 'sync_status.dart';

class Pet implements Entidade {
  static const String tabela = 'pets';
  static const List<String> colunasApi = [
    'id', 'tutor_id', 'nome', 'especie', 'raca', 'sexo', 'data_nascimento',
    'peso_kg', 'observacoes', 'foto_url', 'updated_at',
  ];

  @override
  final String id;
  final String tutorId;
  final String nome;
  final String especie;
  final String? raca;
  final String sexo; // 'M' ou 'F'
  final DateTime? dataNascimento;
  final double? pesoKg;
  final String? observacoes;
  final String? fotoUrl;
  final String? fotoLocal;
  @override
  final DateTime updatedAt;
  @override
  final SyncStatus syncStatus;
  @override
  final bool deleted;

  Pet({
    required this.id,
    required this.tutorId,
    required this.nome,
    required this.especie,
    this.raca,
    required this.sexo,
    this.dataNascimento,
    this.pesoKg,
    this.observacoes,
    this.fotoUrl,
    this.fotoLocal,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.deleted = false,
  });

  /// Idade em texto, ex.: "3 anos" ou "5 meses".
  String get idade {
    if (dataNascimento == null) return 'Idade não informada';
    final hoje = DateTime.now();
    var meses = (hoje.year - dataNascimento!.year) * 12 + hoje.month - dataNascimento!.month;
    if (hoje.day < dataNascimento!.day) meses--;
    if (meses < 0) meses = 0;
    if (meses < 12) return meses == 1 ? '1 mês' : '$meses meses';
    final anos = meses ~/ 12;
    return anos == 1 ? '1 ano' : '$anos anos';
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'tutor_id': tutorId,
        'nome': nome,
        'especie': especie,
        'raca': raca,
        'sexo': sexo,
        'data_nascimento': dataSemHora(dataNascimento),
        'peso_kg': pesoKg,
        'observacoes': observacoes,
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

  factory Pet.fromMap(Map<String, dynamic> map) => Pet(
        id: map['id'] as String,
        tutorId: map['tutor_id'] as String,
        nome: map['nome'] as String,
        especie: map['especie'] as String,
        raca: map['raca'] as String?,
        sexo: (map['sexo'] as String?) ?? 'M',
        dataNascimento: textoParaData(map['data_nascimento']),
        pesoKg: paraDouble(map['peso_kg']),
        observacoes: map['observacoes'] as String?,
        fotoUrl: map['foto_url'] as String?,
        fotoLocal: map['foto_local'] as String?,
        updatedAt: textoParaData(map['updated_at']) ?? DateTime.now(),
        syncStatus: SyncStatus.fromValor(map['sync_status'] as String?),
        deleted: paraBool(map['deleted']),
      );
}
