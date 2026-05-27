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
    final conn = await DB().connection;

    final result = await conn.execute(
      Sql.named('''
      UPDATE matches_triagem
      SET status_triagem = 'CONCLUIDO'
      WHERE id = @id
      RETURNING id, status_triagem;
      '''),
      parameters: {
        'id': id,
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {
          'erro': 'Match não encontrado',
        },
      );
    }

    return Response.json(
      body: {
        'message': 'Match concluído com sucesso',
        'id': id,
        'status_triagem': 'CONCLUIDO',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao confirmar match',
        'detalhe': e.toString(),
      },
    );
  }
}