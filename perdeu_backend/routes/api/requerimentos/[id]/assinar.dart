import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
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

    final cpf = body['cpf']?.toString().trim();
    final senha = body['senha']?.toString().trim();
    final dispositivoModelo = body['dispositivo_modelo']?.toString().trim();

    if (cpf == null || cpf.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'CPF é obrigatório',
        },
      );
    }

    if (senha == null || senha.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Senha é obrigatória',
        },
      );
    }

    if (dispositivoModelo == null || dispositivoModelo.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Modelo do dispositivo não informado',
        },
      );
    }

    final conn = await DB().connection;

    final usuarioResult = await conn.execute(
      Sql.named('''
      SELECT id, senha_hash, status_ativo
      FROM usuarios
      WHERE id = @usuario_id
      LIMIT 1;
      '''),
      parameters: {
        'usuario_id': usuario.id,
      },
    );

    if (usuarioResult.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {
          'erro': 'Usuário não encontrado',
        },
      );
    }

    final usuarioData = usuarioResult.first.toColumnMap();
    final senhaHashBanco = usuarioData['senha_hash']?.toString();
    final statusAtivo = usuarioData['status_ativo'] == true;

    final senhaHashDigitada = sha256.convert(
      utf8.encode(senha),
    ).toString();

    if (!statusAtivo || senhaHashBanco != senhaHashDigitada) {
      return Response.json(
        statusCode: 401,
        body: {
          'erro': 'Senha inválida',
        },
      );
    }

    final requerimentoResult = await conn.execute(
      Sql.named('''
      SELECT id, usuario_id, status
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

    if (requerimentoResult.isEmpty) {
      return Response.json(
        statusCode: 403,
        body: {
          'erro': 'Você não tem permissão para assinar este requerimento',
        },
      );
    }

    final requerimentoData = requerimentoResult.first.toColumnMap();
    final statusAtual = requerimentoData['status']?.toString();

    if (statusAtual == 'CANCELADO') {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Não é possível assinar um requerimento cancelado',
        },
      );
    }

    if (statusAtual == 'CONCLUIDO' || statusAtual == 'DEVOLVIDO') {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Este requerimento já foi concluído',
        },
      );
    }

    final ipRede = request.connectionInfo.remoteAddress.address;
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final assinaturaHash = sha256.convert(
      utf8.encode('$id|$cpf|$timestamp'),
    ).toString();

    await conn.execute(
      Sql.named('''
      INSERT INTO termos_retirada (
        requerimento_id,
        usuario_id,
        cpf,
        assinatura_hash,
        ip_rede,
        dispositivo_modelo,
        created_at
      )
      VALUES (
        @requerimento_id,
        @usuario_id,
        @cpf,
        @assinatura_hash,
        @ip_rede,
        @dispositivo_modelo,
        NOW()
      );
      '''),
      parameters: {
        'requerimento_id': id,
        'usuario_id': usuario.id,
        'cpf': cpf,
        'assinatura_hash': assinaturaHash,
        'ip_rede': ipRede,
        'dispositivo_modelo': dispositivoModelo,
      },
    );

    await conn.execute(
      Sql.named('''
      UPDATE requerimentos
      SET
        status = 'CONCLUIDO',
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
        'ASSINATURA_TERMO_RETIRADA',
        @justificativa,
        NOW()
      );
      '''),
      parameters: {
        'usuario_id': usuario.id,
        'requerimento_id': id,
        'justificativa':
            'Termo assinado digitalmente. IP: $ipRede. Dispositivo: $dispositivoModelo.',
      },
    );

    return Response.json(
      statusCode: 200,
      body: {
        'message': 'Termo assinado com sucesso',
        'status': 'CONCLUIDO',
        'assinatura_hash': assinaturaHash,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao assinar termo de retirada',
        'detalhe': e.toString(),
      },
    );
  }
}