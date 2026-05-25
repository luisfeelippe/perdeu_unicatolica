import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(
    String matricula,
    String senha,
    bool manterConectado,
  ) async {
    final response = await _apiClient.post('/auth/login', {
      'matricula': matricula.trim(),
      'senha': senha.trim(),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final token = data['token']?.toString();

      if (token == null || token.isEmpty) {
        return {
          'sucesso': false,
          'erro': 'Token não retornado pelo servidor',
        };
      }

      final prefs = await SharedPreferences.getInstance();

      // Salva sempre o token, porque o app precisa dele para:
      // - Atualizações
      // - Meus requerimentos
      // - Cancelamento
      // - Futuras rotas privadas
      await prefs.setString('token', token);
      await prefs.setString('jwt', token);
      await prefs.setString('jwt_token', token);
      await prefs.setString('matricula', matricula.trim());
      await prefs.setString('user_matricula', matricula.trim());

      return {
        'sucesso': true,
        'primeiro_acesso': data['primeiro_acesso'] ?? false,
        'token': token,
      };
    }

    return {
      'sucesso': false,
      'erro': 'Credenciais inválidas',
    };
  }

  Future<bool> atualizarSenha(
    String matricula,
    String senhaAntiga,
    String novaSenha,
  ) async {
    final response = await _apiClient.post('/auth/nova-senha', {
      'matricula': matricula.trim(),
      'senha_antiga': senhaAntiga.trim(),
      'nova_senha': novaSenha.trim(),
    });

    return response.statusCode == 200;
  }

  Future<String> recuperarSenha(String matricula) async {
    final response = await _apiClient.post('/auth/recuperar-senha', {
      'matricula': matricula.trim(),
    });

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data['mensagem']?.toString() ?? 'Solicitação enviada.';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('jwt');
    await prefs.remove('jwt_token');
    await prefs.remove('matricula');
    await prefs.remove('user_matricula');
  }
}