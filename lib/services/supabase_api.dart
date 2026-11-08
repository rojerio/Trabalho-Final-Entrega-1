import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import 'sessao_service.dart';

/// Cliente REST genérico para as tabelas e o Storage do Supabase.
class SupabaseApi {
  final SessaoService sessao;

  SupabaseApi(this.sessao);

  Map<String, String> _headers({Map<String, String> extras = const {}}) => {
        'apikey': SupabaseConfig.publishableKey,
        'Authorization': 'Bearer ${sessao.usuario?.accessToken}',
        'Content-Type': 'application/json',
        ...extras,
      };

  /// Executa a requisição e, se o token tiver expirado (401), renova e tenta de novo.
  Future<http.Response> _executar(Future<http.Response> Function() requisicao) async {
    var response = await requisicao().timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      await sessao.renovarToken();
      response = await requisicao().timeout(const Duration(seconds: 20));
    }
    return response;
  }

  /// Insere ou atualiza (upsert) um registro pela chave primária.
  Future<void> upsert(String tabela, Map<String, dynamic> dados) async {
    final uri = Uri.parse('${SupabaseConfig.restUrl}/$tabela?on_conflict=id');
    final response = await _executar(() => http.post(
          uri,
          headers: _headers(extras: {'Prefer': 'resolution=merge-duplicates,return=minimal'}),
          body: jsonEncode(dados),
        ));
    if (response.statusCode != 201 && response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao enviar $tabela: ${response.body}');
    }
  }

  Future<void> excluir(String tabela, String id) async {
    final uri = Uri.parse('${SupabaseConfig.restUrl}/$tabela?id=eq.$id');
    final response = await _executar(() => http.delete(uri, headers: _headers()));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir em $tabela: ${response.body}');
    }
  }

  /// Busca os registros alterados no servidor depois de [desde].
  Future<List<Map<String, dynamic>>> buscarAlterados(
    String tabela,
    List<String> colunas, {
    DateTime? desde,
  }) async {
    final parametros = <String, String>{
      'select': colunas.join(','),
      'order': 'updated_at.asc',
      if (desde != null) 'updated_at': 'gt.${desde.toUtc().toIso8601String()}',
    };
    final uri = Uri.parse('${SupabaseConfig.restUrl}/$tabela').replace(queryParameters: parametros);
    final response = await _executar(() => http.get(uri, headers: _headers()));
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar $tabela: ${response.body}');
    }
    final lista = jsonDecode(response.body) as List<dynamic>;
    return lista.cast<Map<String, dynamic>>();
  }

  /// Envia uma foto para o Storage e devolve a URL pública dela.
  Future<String> enviarFoto({required Uint8List bytes, required String destino}) async {
    final caminho = '${SupabaseConfig.bucketFotos}/$destino';
    final uri = Uri.parse('${SupabaseConfig.storageUrl}/object/$caminho');
    final response = await _executar(() => http.post(
          uri,
          headers: _headers(extras: {'Content-Type': 'image/jpeg', 'x-upsert': 'true'}),
          body: bytes,
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao enviar a foto: ${response.body}');
    }
    return '${SupabaseConfig.storageUrl}/object/public/$caminho';
  }
}
