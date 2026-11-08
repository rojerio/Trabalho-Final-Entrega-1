/// Situação de um registro em relação ao servidor.
enum SyncStatus {
  synced('synced'),
  pendingCreate('pending_create'),
  pendingUpdate('pending_update'),
  pendingDelete('pending_delete');

  const SyncStatus(this.valor);
  final String valor;

  static SyncStatus fromValor(String? valor) {
    return SyncStatus.values.firstWhere(
      (status) => status.valor == valor,
      orElse: () => SyncStatus.synced,
    );
  }
}

/// Contrato comum das entidades que são sincronizadas com o Supabase.
abstract class Entidade {
  String get id;
  DateTime get updatedAt;
  SyncStatus get syncStatus;
  bool get deleted;

  /// Mapa com todas as colunas da tabela local.
  Map<String, dynamic> toMap();

  /// Mapa com as colunas enviadas para a API.
  Map<String, dynamic> toApi();
}

/// Converte datas para texto ISO (formato usado no SQLite e na API).
String? dataParaTexto(DateTime? data) => data?.toIso8601String();

DateTime? textoParaData(dynamic valor) {
  if (valor == null) return null;
  return DateTime.tryParse(valor.toString());
}

double? paraDouble(dynamic valor) {
  if (valor == null) return null;
  return (valor as num).toDouble();
}

bool paraBool(dynamic valor) => valor == 1 || valor == true;

/// Data sem horário (coluna `date` no Postgres), ex.: 2026-11-08.
String? dataSemHora(DateTime? data) {
  if (data == null) return null;
  final m = data.month.toString().padLeft(2, '0');
  final d = data.day.toString().padLeft(2, '0');
  return '${data.year}-$m-$d';
}

/// Data e hora em UTC (coluna `timestamptz` no Postgres).
String? dataHoraUtc(DateTime? data) => data?.toUtc().toIso8601String();

/// Lê uma data com horário e converte para o fuso do aparelho.
DateTime? textoParaDataLocal(dynamic valor) => textoParaData(valor)?.toLocal();

/// Formata uma data como dd/mm/aaaa.
String formatarData(DateTime? data) {
  if (data == null) return '-';
  final d = data.day.toString().padLeft(2, '0');
  final m = data.month.toString().padLeft(2, '0');
  return '$d/$m/${data.year}';
}

/// Formata data e hora como dd/mm/aaaa hh:mm.
String formatarDataHora(DateTime? data) {
  if (data == null) return '-';
  final h = data.hour.toString().padLeft(2, '0');
  final min = data.minute.toString().padLeft(2, '0');
  return '${formatarData(data)} $h:$min';
}
