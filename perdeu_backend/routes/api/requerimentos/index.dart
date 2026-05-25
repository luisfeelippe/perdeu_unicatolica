import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:perdeu_backend/src/config/db.dart';

/// Endpoint de requerimentos.
/// GET: retorna o feed público.
/// POST: cria um novo requerimento vindo do Wizard.
Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method == HttpMethod.get) {
    return _buscarRequerimentosRecentes();
  }

  if (request.method == HttpMethod.post) {
    return _criarRequerimento(request);
  }

  return Response.json(
    statusCode: 405,
    body: {
      'erro': 'Método não permitido',
    },
  );
}

Future<Response> _buscarRequerimentosRecentes() async {
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
        r.cor_predominante,
        r.marca,
        u.nome_completo AS usuario_nome
      FROM requerimentos r
      INNER JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.status <> 'CANCELADO'
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
        'erro': 'Erro ao carregar requerimentos recentes',
        'detalhe': e.toString(),
      },
    );
  }
}

Future<Response> _criarRequerimento(Request request) async {
  try {
    final body = await request.json() as Map<String, dynamic>;

    final matricula = body['matricula']?.toString().trim();
    final tipo = body['tipo']?.toString().trim().toUpperCase();
    final categoria = body['categoria']?.toString().trim();
    final localOcorrencia = body['local_ocorrencia']?.toString().trim();
    final dataHoraOcorrencia = body['data_hora_ocorrencia']?.toString().trim();
    final descricao = body['descricao']?.toString().trim();
    final fotoUrl = body['foto_url']?.toString().trim();
    final fotoBase64 = body['foto_base64']?.toString().trim();

    final fotoUrlFinal = fotoBase64 != null && fotoBase64.isNotEmpty
    ? 'data:image/jpeg;base64,$fotoBase64'
    : fotoUrl;
    final corPredominante = body['cor_predominante']?.toString().trim();
    final marca = body['marca']?.toString().trim();

    if (matricula == null ||
        matricula.isEmpty ||
        tipo == null ||
        tipo.isEmpty ||
        categoria == null ||
        categoria.isEmpty ||
        localOcorrencia == null ||
        localOcorrencia.isEmpty ||
        dataHoraOcorrencia == null ||
        dataHoraOcorrencia.isEmpty ||
        descricao == null ||
        descricao.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Dados obrigatórios não informados',
        },
      );
    }

    if (tipo != 'PERDA' && tipo != 'ACHADO') {
      return Response.json(
        statusCode: 400,
        body: {
          'erro': 'Tipo inválido. Use PERDA ou ACHADO.',
        },
      );
    }

    final conn = await DB().connection;

      final usuarioResult = await conn.execute(
    Sql.named('''
    SELECT id
    FROM usuarios
    WHERE matricula = @matricula
      AND status_ativo = true
    LIMIT 1;
    '''),
    parameters: {
      'matricula': matricula,
    },
  );

    if (usuarioResult.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {
          'erro': 'Usuário não encontrado ou inativo',
        },
      );
    }

    final usuarioId = usuarioResult.first.toColumnMap()['id'].toString();

    final statusInicial = tipo == 'PERDA' ? 'PERDIDO' : 'ENCONTRADO';

    final insertResult = await conn.execute(
      Sql.named('''
      INSERT INTO requerimentos (
        usuario_id,
        tipo,
        categoria,
        local_ocorrencia,
        data_hora_ocorrencia,
        descricao,
        foto_url,
        status,
        cor_predominante,
        marca,
        created_at,
        updated_at
      )
      VALUES (
        @usuario_id,
        @tipo,
        @categoria,
        @local_ocorrencia,
        @data_hora_ocorrencia,
        @descricao,
        @foto_url,
        @status,
        @cor_predominante,
        @marca,
        NOW(),
        NOW()
      )
        RETURNING id;
        '''),
        parameters: {
        'usuario_id': usuarioId,
        'tipo': tipo,
        'categoria': categoria,
        'local_ocorrencia': localOcorrencia,
        'data_hora_ocorrencia': dataHoraOcorrencia,
        'descricao': descricao,
        'foto_url': fotoUrlFinal == null || fotoUrlFinal.isEmpty ? null : fotoUrlFinal,
        'status': statusInicial,
        'cor_predominante':
            corPredominante == null || corPredominante.isEmpty
                ? null
                : corPredominante,
        'marca': marca == null || marca.isEmpty ? null : marca,
      },
    );

    final requerimentoId = insertResult.first.toColumnMap()['id'].toString();

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Requerimento criado com sucesso',
        'id': requerimentoId,
        'status': statusInicial,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao criar requerimento',
        'detalhe': e.toString(),
      },
    );
  }
}