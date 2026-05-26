import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  final bloqueio = bloquearSeNaoAdmin(request);
  if (bloqueio != null) return bloqueio;

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

    final result = await conn.execute('''
      SELECT
        m.id,
        m.score_confianca,
        m.justificativa,
        m.status_triagem,
        m.created_at,

        rn.id AS novo_id,
        rn.tipo AS novo_tipo,
        rn.categoria AS novo_categoria,
        rn.local_ocorrencia AS novo_local,
        rn.descricao AS novo_descricao,
        rn.foto_url AS novo_foto_url,
        rn.status AS novo_status,

        rc.id AS candidato_id,
        rc.tipo AS candidato_tipo,
        rc.categoria AS candidato_categoria,
        rc.local_ocorrencia AS candidato_local,
        rc.descricao AS candidato_descricao,
        rc.foto_url AS candidato_foto_url,
        rc.status AS candidato_status
      FROM matches_triagem m
      INNER JOIN requerimentos rn ON rn.id = m.requerimento_novo_id
      INNER JOIN requerimentos rc ON rc.id = m.requerimento_candidato_id
      ORDER BY m.created_at DESC;
    ''');

    final dados = result.map((row) {
      final data = row.toColumnMap();

      return {
        'id': data['id'].toString(),
        'score_confianca': data['score_confianca'],
        'justificativa': data['justificativa'],
        'status_triagem': data['status_triagem'],
        'created_at': data['created_at']?.toString(),
        'novo': {
          'id': data['novo_id'].toString(),
          'tipo': data['novo_tipo'],
          'categoria': data['novo_categoria'],
          'local_ocorrencia': data['novo_local'],
          'descricao': data['novo_descricao'],
          'foto_url': data['novo_foto_url'],
          'status': data['novo_status'],
        },
        'candidato': {
          'id': data['candidato_id'].toString(),
          'tipo': data['candidato_tipo'],
          'categoria': data['candidato_categoria'],
          'local_ocorrencia': data['candidato_local'],
          'descricao': data['candidato_descricao'],
          'foto_url': data['candidato_foto_url'],
          'status': data['candidato_status'],
        },
      };
    }).toList();

    return Response(
      statusCode: 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(dados),
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao carregar matches da IA',
        'detalhe': e.toString(),
      },
    );
  }
}