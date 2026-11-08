enum TipoTransacao { receita, despesa }

class Transacao {
  final String id;
  final String descricao;
  final double valor;
  final TipoTransacao tipo;
  final DateTime data;
  final bool sincronizado;

  Transacao({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.data,
    this.sincronizado = true
  });

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo.toString(),
      'data': DateTime.now().toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0
    };
  }

  Map<String, dynamic> toJsonApi() {
    return {
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo.toString(),
      'sincronizado': sincronizado ? 1 : 0
    };
  }

  factory Transacao.fromJson(Map<String, dynamic> json) {
    return Transacao(
      id: json['id'] as String,
      descricao: json['descricao'] as String,
      valor: (json['valor'] as num).toDouble(),
      tipo: (json['tipo'] as String) == TipoTransacao.receita.toString() ? TipoTransacao.receita : TipoTransacao.despesa,
      data: DateTime.parse(json['created_at'] as String),
      sincronizado: json['sincronizado'] == 1
    );
  }

  Transacao copy({
    String? id,
    String? descricao,
    double? valor,
    TipoTransacao? tipo,
    DateTime? data,
    bool? sincronizado
  }) {
    return Transacao(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      data: data ?? this.data,
      sincronizado: sincronizado ?? this.sincronizado
    );
  }

}