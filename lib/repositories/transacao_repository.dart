import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transacao.dart';

class TransacaoRepository {
  
  static const String _baseUrl = "https://cefzxbeyewupfxowchac.supabase.co/rest/v1/transacoes";
  static const String _publishableKey = "<SUA_KEY>";

  final String accessToken;

  TransacaoRepository({required this.accessToken});

  Map<String, String> get _headers => {
    'apikey': _publishableKey,
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };

  Future<List<Transacao>> buscarTransacoes() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: _headers
    );

    if (response.statusCode == 200) {
      final List<dynamic> listJson = jsonDecode(response.body);
      return listJson.map((item) => Transacao.fromJson(item)).toList();
    } else {
      throw Exception('Falha ao buscar transações via REST: ${response.body}');
    }
  }

  Future<Transacao> criarTransacao(Transacao transacao) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode(transacao.toJsonApi())
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final List<dynamic> responseList = jsonDecode(response.body);
      return Transacao.fromJson(responseList.first);
    } else {
      throw Exception('Falha ao salvar transações via REST: ${response.body}');
    }
  }  

  Future<Transacao> atualizarTransacao(Transacao transacao) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl?id=eq.${transacao.id}'),
      headers: _headers,
      body: jsonEncode(transacao)
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseList = jsonDecode(response.body);
      return Transacao.fromJson(responseList.first);
    } else {
      throw Exception('Falha ao atualizar a transação via REST: ${response.body}');
    }

  }

  Future<void> excluirTransacao(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl?id=eq.$id'),
      headers: _headers
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao realizar a exclusão via REST: ${response.body}');
    }
  }

}