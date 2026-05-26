import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final request = context.request;

  final bloqueio = bloquearSeNaoAdmin(request);
  if (bloqueio != null) return bloqueio;

  if (request.method != HttpMethod.patch) {
    return Response.json(
      statusCode: 405,
      body: {
        'erro': 'Método não permitido',
      },
    );
  }

  try {
    final body = await request.json() as Map<String, dynamic>;
    final bloquear = body['bloquear'];

    if (bloquear is! bool) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Informe bloquear como true ou false',
        },
      );
    }

    final conn = await DB().connection;

    final result = await conn.execute(
      Sql.named('''
      UPDATE usuarios
      SET status_ativo = @status_ativo
      WHERE id = @id
      RETURNING id, status_ativo;
      '''),
      parameters: {
        'id': id,
        'status_ativo': !bloquear,
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

    return Response.json(
      body: {
        'message': bloquear
            ? 'Usuário bloqueado com sucesso'
            : 'Usuário desbloqueado com sucesso',
        'status_ativo': !bloquear,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao atualizar usuário',
        'detalhe': e.toString(),
      },
    );
  }
}