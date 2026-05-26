import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PerfilRepository {
  PerfilRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'http://localhost:8080';

  Future<Map<String, dynamic>> buscarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('jwt');

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final uri = Uri.parse('$_baseUrl/api/perfil');

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      throw Exception(data['erro']?.toString() ?? 'Erro ao carregar perfil.');
    }

    throw Exception('Erro ao carregar perfil.');
  }
}