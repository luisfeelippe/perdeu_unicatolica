import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.put) {
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

    final senhaAntiga = body['senha_antiga']?.toString().trim();
    final novaSenha = body['nova_senha']?.toString().trim();

    if (senhaAntiga == null || senhaAntiga.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Informe a senha antiga',
        },
      );
    }

    if (novaSenha == null || novaSenha.length < 8) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'A nova senha deve ter pelo menos 8 caracteres',
        },
      );
    }

    if (senhaAntiga == novaSenha) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'A nova senha precisa ser diferente da antiga',
        },
      );
    }

    final conn = await DB().connection;

    final result = await conn.execute(
      Sql.named('''
      SELECT senha_hash
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

    final senhaHashBanco = result.first.toColumnMap()['senha_hash']?.toString();

    final senhaAntigaHash = sha256.convert(
      utf8.encode(senhaAntiga),
    ).toString();

    if (senhaHashBanco != senhaAntigaHash) {
      return Response.json(
        statusCode: 401,
        body: {
          'erro': 'Senha antiga inválida',
        },
      );
    }

    final novaSenhaHash = sha256.convert(
      utf8.encode(novaSenha),
    ).toString();

    await conn.execute(
      Sql.named('''
      UPDATE usuarios
      SET senha_hash = @senha_hash
      WHERE id = @id;
      '''),
      parameters: {
        'id': usuario.id,
        'senha_hash': novaSenhaHash,
      },
    );

    return Response.json(
      body: {
        'message': 'Senha alterada com sucesso',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao alterar senha',
        'detalhe': e.toString(),
      },
    );
  }
}