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
    final novoStatus = body['status']?.toString().trim().toUpperCase();

    if (novoStatus != 'APROVADO' && novoStatus != 'REJEITADO') {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Status inválido. Use APROVADO ou REJEITADO.',
        },
      );
    }

    final conn = await DB().connection;

    final result = await conn.execute(
      Sql.named('''
      UPDATE requerimentos
      SET status = @status, updated_at = NOW()
      WHERE id = @id
      RETURNING id, status;
      '''),
      parameters: {
        'id': id,
        'status': novoStatus,
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {
          'erro': 'Requerimento não encontrado',
        },
      );
    }

    return Response.json(
      body: {
        'message': 'Status atualizado com sucesso',
        'id': id,
        'status': novoStatus,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao atualizar status',
        'detalhe': e.toString(),
      },
    );
  }
}