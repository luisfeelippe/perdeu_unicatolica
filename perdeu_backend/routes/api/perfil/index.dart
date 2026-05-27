import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  final usuario = extrairUsuarioAutenticado(request);

  if (usuario == null) {
    return Response.json(
      statusCode: 401,
      body: {
        'erro': 'Token ausente ou inválido',
      },
    );
  }

  if (request.method == HttpMethod.get) {
    return _buscarPerfil(usuario.id);
  }

  if (request.method == HttpMethod.patch) {
    return _atualizarPerfil(request, usuario.id);
  }

  return Response.json(
    statusCode: 405,
    body: {
      'erro': 'Método não permitido',
    },
  );
}

Future<Response> _buscarPerfil(String usuarioId) async {
  try {
    final conn = await DB().connection;

    final result = await conn.execute(
      Sql.named('''
      SELECT
        id,
        nome_completo,
        matricula,
        perfil,
        status_ativo,
        email,
        email_institucional,
        curso,
        semestre,
        foto_perfil
      FROM usuarios
      WHERE id = @id
      LIMIT 1;
      '''),
      parameters: {
        'id': usuarioId,
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {
          'erro': 'Usuário não encontrado',
        },
      );
    }

    final data = result.first.toColumnMap();
    final emailFinal = data['email_institucional'] ?? data['email'];

    return Response.json(
      body: {
        'id': data['id'].toString(),
        'nome_completo': data['nome_completo'],
        'matricula': data['matricula'],
        'perfil': data['perfil'],
        'status_ativo': data['status_ativo'],
        'email': emailFinal,
        'email_institucional': emailFinal,
        'curso': data['curso'],
        'semestre': data['semestre'],
        'foto_perfil': data['foto_perfil'],
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao carregar perfil',
        'detalhe': e.toString(),
      },
    );
  }
}

Future<Response> _atualizarPerfil(Request request, String usuarioId) async {
  try {
    final body = await request.json() as Map<String, dynamic>;

    final fotoPerfilRaw = body['foto_perfil'];
    final String? fotoPerfil = fotoPerfilRaw?.toString();

    final conn = await DB().connection;

    await conn.execute(
      Sql.named('''
      UPDATE usuarios
      SET
        foto_perfil = @foto_perfil,
        updated_at = NOW()
      WHERE id = @id;
      '''),
      parameters: {
        'id': usuarioId,
        'foto_perfil': fotoPerfil,
      },
    );

    return Response.json(
      body: {
        'message': fotoPerfil == null || fotoPerfil.isEmpty
            ? 'Foto de perfil removida com sucesso'
            : 'Foto de perfil atualizada com sucesso',
        'foto_perfil': fotoPerfil,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao atualizar foto de perfil',
        'detalhe': e.toString(),
      },
    );
  }
}