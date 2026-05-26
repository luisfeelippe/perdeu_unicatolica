import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminRepository {
  AdminRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'http://localhost:8080';

  Future<List<Map<String, dynamic>>> buscarRequerimentosPendentes() async {
    return _getList('/api/admin/requerimentos');
  }

  Future<List<Map<String, dynamic>>> buscarMatches() async {
    return _getList('/api/admin/matches');
  }

  Future<List<Map<String, dynamic>>> buscarUsuarios() async {
    return _getList('/api/admin/usuarios');
  }

  Future<bool> criarUsuario({
    required String nomeCompleto,
    required String matricula,
    required String email,
    required String curso,
    required String semestre,
    required String cpf,
    required bool statusAtivo,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/api/admin/usuarios',
      body: {
        'nome_completo': nomeCompleto,
        'matricula': matricula,
        'email': email,
        'curso': curso,
        'semestre': semestre,
        'cpf': cpf,
        'status_ativo': statusAtivo,
      },
    );

    if (response.statusCode == 201) {
      return true;
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final erro = decoded['erro']?.toString() ?? 'Erro ao criar usuário.';
      final detalhe = decoded['detalhe']?.toString();

      if (detalhe != null && detalhe.isNotEmpty) {
        throw Exception('$erro\n$detalhe');
      }

      throw Exception(erro);
    }   

        throw Exception('Erro ao criar usuário.');
    }

  Future<bool> atualizarStatusRequerimento({
    required String id,
    required String status,
  }) async {
    final response = await _request(
      method: 'PATCH',
      path: '/api/admin/requerimentos/$id/status',
      body: {
        'status': status,
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> bloquearUsuario({
    required String id,
    required bool bloquear,
  }) async {
    final response = await _request(
      method: 'PATCH',
      path: '/api/admin/usuarios/$id/bloquear',
      body: {
        'bloquear': bloquear,
      },
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _request(
      method: 'GET',
      path: path,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((item) => item as Map<String, dynamic>).toList();
      }

      throw Exception('Resposta inválida da API.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      throw Exception(decoded['erro']?.toString() ?? 'Erro administrativo.');
    }

    throw Exception('Erro administrativo.');
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('jwt');

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final uri = Uri.parse('$_baseUrl$path');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);

      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );

      case 'PATCH':
        return _client.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );

      default:
        throw Exception('Método HTTP inválido.');
    }
  }
}