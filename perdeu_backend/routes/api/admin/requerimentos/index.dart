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
        u.nome_completo AS usuario_nome,
        u.matricula AS usuario_matricula
      FROM requerimentos r
      INNER JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.status IN ('PENDENTE', 'EM_ANALISE')
      ORDER BY r.updated_at DESC, r.created_at DESC;
    ''');

    final dados = result.map((row) {
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
        'usuario_matricula': data['usuario_matricula'],
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
        'erro': 'Erro ao carregar requerimentos administrativos',
        'detalhe': e.toString(),
      },
    );
  }
}