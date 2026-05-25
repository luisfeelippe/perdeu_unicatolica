import 'dart:convert';

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
        r.id,
        r.tipo,
        r.categoria,
        r.local_ocorrencia,
        r.data_hora_ocorrencia,
        r.descricao,
        r.foto_url,
        r.status,
        r.cor_predominante,
        r.marca,
        u.nome_completo AS usuario_nome
      FROM requerimentos r
      INNER JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.usuario_id = @usuario_id
      ORDER BY r.data_hora_ocorrencia DESC;
      '''),
      parameters: {
        'usuario_id': usuario.id,
      },
    );

    final requerimentos = result.map((row) {
      final data = row.toColumnMap();

      return {
        'id': data['id'].toString(),
        'tipo': data['tipo'],
        'categoria': data['categoria'],
        'local_ocorrencia': data['local_ocorrencia'],
        'data_hora_ocorrencia': data['data_hora_ocorrencia']?.toString(),
        'descricao': data['descricao'],
        'foto_url': data['foto_url'],
        'status': data['status'],
        'cor_predominante': data['cor_predominante'],
        'marca': data['marca'],
        'usuario_nome': data['usuario_nome'],
      };
    }).toList();

    return Response(
      statusCode: 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(requerimentos),
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao carregar seus requerimentos',
        'detalhe': e.toString(),
      },
    );
  }
}