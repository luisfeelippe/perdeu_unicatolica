import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const String jwtSecret = 'CHAVE_SECRETA_SUPER_SEGURA_UNICATOLICA';

class UsuarioAutenticado {
  const UsuarioAutenticado({
    required this.id,
    required this.matricula,
    required this.perfil,
  });

  final String id;
  final String matricula;
  final String perfil;

  bool get isAdmin => perfil.toUpperCase() == 'ADMIN';
}

UsuarioAutenticado? extrairUsuarioAutenticado(Request request) {
  final authorization = request.headers['authorization'];

  if (authorization == null || !authorization.startsWith('Bearer ')) {
    return null;
  }

  final token = authorization.replaceFirst('Bearer ', '').trim();

  try {
    final jwt = JWT.verify(
      token,
      SecretKey(jwtSecret),
    );

    final payload = jwt.payload as Map<String, dynamic>;

    final id = payload['id']?.toString();
    final matricula = payload['matricula']?.toString();
    final perfil = payload['perfil']?.toString();

    if (id == null || matricula == null || perfil == null) {
      return null;
    }

    return UsuarioAutenticado(
      id: id,
      matricula: matricula,
      perfil: perfil,
    );
  } catch (_) {
    return null;
  }
}

Response? bloquearSeNaoAdmin(Request request) {
  final usuario = extrairUsuarioAutenticado(request);

  if (usuario == null) {
    return Response.json(
      statusCode: 401,
      body: {
        'erro': 'Token ausente ou inválido',
      },
    );
  }

  if (!usuario.isAdmin) {
    return Response.json(
      statusCode: 403,
      body: {
        'erro': 'Acesso restrito ao administrador',
      },
    );
  }

  return null;
}