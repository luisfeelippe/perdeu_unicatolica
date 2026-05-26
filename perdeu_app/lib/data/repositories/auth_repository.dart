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

      final payload = _decodeJwtPayload(token);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', token);
      await prefs.setString('jwt', token);
      await prefs.setString('jwt_token', token);
      await prefs.setString('matricula', matricula.trim());
      await prefs.setString('user_matricula', matricula.trim());

      if (payload != null) {
        await prefs.setString('usuario_id', payload['id']?.toString() ?? '');
        await prefs.setString('perfil', payload['perfil']?.toString() ?? '');
      }

      return {
        'sucesso': true,
        'primeiro_acesso': data['primeiro_acesso'] ?? false,
        'token': token,
        'perfil': payload?['perfil'],
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

  Future<bool> alterarSenha({
    required String senhaAntiga,
    required String novaSenha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('jwt');

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final response = await _apiClient.put(
      '/perfil/senha',
      {
        'senha_antiga': senhaAntiga,
        'nova_senha': novaSenha,
      },
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      throw Exception(data['erro']?.toString() ?? 'Erro ao alterar senha.');
    }

    throw Exception('Erro ao alterar senha.');
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
    await prefs.remove('usuario_id');
    await prefs.remove('perfil');
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');

      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}