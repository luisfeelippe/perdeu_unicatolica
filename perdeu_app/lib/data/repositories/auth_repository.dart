import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String matricula, String senha, bool manterConectado) async {
    final response = await _apiClient.post('/auth/login', {
      'matricula': matricula,
      'senha': senha,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (manterConectado) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('matricula', matricula);
      }
      return {'sucesso': true, 'primeiro_acesso': data['primeiro_acesso']};
    }
    return {'sucesso': false, 'erro': 'Credenciais inválidas'};
  }

  Future<bool> atualizarSenha(String matricula, String senhaAntiga, String novaSenha) async {
    final response = await _apiClient.post('/auth/nova-senha', {
      'matricula': matricula,
      'senha_antiga': senhaAntiga,
      'nova_senha': novaSenha,
    });
    return response.statusCode == 200;
  }

  Future<String> recuperarSenha(String matricula) async {
    final response = await _apiClient.post('/auth/recuperar-senha', {'matricula': matricula});
    final data = jsonDecode(response.body);
    return data['mensagem'];
  }
}