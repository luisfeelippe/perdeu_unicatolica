import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/db.dart';

/// Endpoint público do feed de requerimentos.
/// Retorna as ocorrências mais recentes para alimentar a Home do aplicativo.
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

  try {
    final conn = await DB().connection;

    final result = await conn.execute(
      '''
      SELECT 
        r.id,
        r.tipo,
        r.categoria,
        r.local_ocorrencia,
        r.data_hora_ocorrencia,
        r.descricao,
        r.foto_url,
        r.status,
        u.nome_completo AS usuario_nome
      FROM requerimentos r
      INNER JOIN usuarios u ON u.id = r.usuario_id
      ORDER BY r.data_hora_ocorrencia DESC;
      ''',
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
        'erro': 'Erro ao carregar requerimentos recentes',
        'detalhe': e.toString(),
      },
    );
  }
}