import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/requerimento_draft.dart';
import '../models/requerimento_model.dart';

class RequerimentoRepository {
  RequerimentoRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  // Para Flutter Web/Chrome, localhost funciona.
  // Se for rodar em emulador Android, troque para http://10.0.2.2:8080.
  static const String _baseUrl = 'http://localhost:8080';

  Future<List<RequerimentoModel>> fetchRequerimentosRecentes() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/requerimentos');

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar ocorrências recentes.');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Resposta inválida da API.');
      }

      return decoded
          .map(
            (item) => RequerimentoModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on SocketException {
      throw Exception('Sem conexão com o servidor.');
    } on TimeoutException {
      throw Exception('Tempo de resposta excedido.');
    } on FormatException {
      throw Exception('Erro ao interpretar resposta do servidor.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String> criarRequerimento(RequerimentoDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final matricula =
          prefs.getString('matricula') ??
          prefs.getString('user_matricula') ??
          'admin123';

      final token = prefs.getString('token') ?? prefs.getString('jwt');

      final uri = Uri.parse('$_baseUrl/api/requerimentos');

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(
              draft.toJson(
                matricula: matricula,
              ),
            ),
          )
          .timeout(
            const Duration(seconds: 12),
          );

      final decoded = jsonDecode(response.body);

      if (response.statusCode != 201) {
        final erro = decoded is Map<String, dynamic>
            ? decoded['erro']?.toString()
            : null;

        throw Exception(erro ?? 'Erro ao criar requerimento.');
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Resposta inválida da API.');
      }

      return decoded['id']?.toString() ?? '';
    } on SocketException {
      throw Exception('Sem conexão com o servidor.');
    } on TimeoutException {
      throw Exception('Tempo de resposta excedido.');
    } on FormatException {
      throw Exception('Erro ao interpretar resposta do servidor.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}