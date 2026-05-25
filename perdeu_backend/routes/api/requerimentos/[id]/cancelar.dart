import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final request = context.request;

  if (request.method != HttpMethod.patch) {
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
    final body = await request.json() as Map<String, dynamic>;
    final justificativa = body['justificativa']?.toString().trim();

    if (justificativa == null || justificativa.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Informe uma justificativa para o cancelamento',
        },
      );
    }

    final conn = await DB().connection;

    final donoResult = await conn.execute(
      Sql.named('''
      SELECT id, status
      FROM requerimentos
      WHERE id = @id
        AND usuario_id = @usuario_id
      LIMIT 1;
      '''),
      parameters: {
        'id': id,
        'usuario_id': usuario.id,
      },
    );

    if (donoResult.isEmpty) {
      return Response.json(
        statusCode: 403,
        body: {
          'erro': 'Você não tem permissão para cancelar este requerimento',
        },
      );
    }

    final statusAtual = donoResult.first.toColumnMap()['status']?.toString();

    if (statusAtual == 'CANCELADO') {
      return Response.json(
        statusCode: 200,
        body: {
          'message': 'Requerimento já estava cancelado',
          'status': 'CANCELADO',
        },
      );
    }

    if (statusAtual == 'CONCLUIDO' || statusAtual == 'APROVADO') {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Não é possível cancelar um requerimento concluído',
        },
      );
    }

    await conn.execute(
      Sql.named('''
      UPDATE requerimentos
      SET
        status = 'CANCELADO',
        updated_at = NOW()
      WHERE id = @id
        AND usuario_id = @usuario_id;
      '''),
      parameters: {
        'id': id,
        'usuario_id': usuario.id,
      },
    );

    await conn.execute(
      Sql.named('''
      INSERT INTO logs_auditoria (
        usuario_id,
        requerimento_id,
        acao,
        justificativa,
        created_at
      )
      VALUES (
        @usuario_id,
        @requerimento_id,
        'CANCELAMENTO_REQUERIMENTO',
        @justificativa,
        NOW()
      );
      '''),
      parameters: {
        'usuario_id': usuario.id,
        'requerimento_id': id,
        'justificativa': justificativa,
      },
    );

    return Response.json(
      statusCode: 200,
      body: {
        'message': 'Requerimento cancelado com sucesso',
        'status': 'CANCELADO',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao cancelar requerimento',
        'detalhe': e.toString(),
      },
    );
  }
}