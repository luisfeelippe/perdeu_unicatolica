import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {
        'erro': 'Método não permitido',
      },
    );
  }

  final usuario = extrairUsuarioAutenticado(request);

  if (usuario == null) {
    return Response.json(
      statusCode: 401,
      body: {
        'erro': 'Token ausente ou inválido',
      },
    );
  }

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
        curso,
        semestre
      FROM usuarios
      WHERE id = @id
      LIMIT 1;
      '''),
      parameters: {
        'id': usuario.id,
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

    return Response.json(
      body: {
        'id': data['id'].toString(),
        'nome_completo': data['nome_completo'],
        'matricula': data['matricula'],
        'perfil': data['perfil'],
        'status_ativo': data['status_ativo'],
        'email': data['email'],
        'curso': data['curso'],
        'semestre': data['semestre'],
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