import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:perdeu_backend/src/services/gemini_service.dart';
import 'package:postgres/postgres.dart';

/// Endpoint de requerimentos.
/// GET: retorna o feed público.
/// POST: cria um novo requerimento e executa triagem com IA.
Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method == HttpMethod.get) {
    return _buscarRequerimentosRecentes();
  }

  if (request.method == HttpMethod.post) {
    return _criarRequerimentoComTriagem(request);
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
        AND r.status <> 'EM_ANALISE'
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

Future<Response> _criarRequerimentoComTriagem(Request request) async {
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
    final corPredominante = body['cor_predominante']?.toString().trim();
    final marca = body['marca']?.toString().trim();

    final fotoUrlFinal = fotoBase64 != null && fotoBase64.isNotEmpty
        ? 'data:image/jpeg;base64,$fotoBase64'
        : fotoUrl;

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

    final candidatos = await _buscarCandidatosParaTriagem(
      conn: conn,
      tipo: tipo,
      categoria: categoria,
    );

    var statusFinal = 'PENDENTE';
    GeminiTriagemResultado? resultadoTriagem;

    try {
      if (candidatos.isNotEmpty) {
        final geminiService = GeminiService();

        resultadoTriagem = await geminiService.analisarTriagem(
          novoObjeto: {
            'tipo': tipo,
            'categoria': categoria,
            'local_ocorrencia': localOcorrencia,
            'data_hora_ocorrencia': dataHoraOcorrencia,
            'descricao': descricao,
            'cor_predominante': corPredominante,
            'marca': marca,
          },
          candidatosHistoricos: candidatos,
        );

        if (resultadoTriagem.candidatoId != null &&
            resultadoTriagem.scoreConfianca > 85) {
          statusFinal = 'EM_ANALISE';
        }
      }
    } catch (e) {
      // Circuit breaker:
      // Se a IA falhar, o requerimento continua sendo salvo como PENDENTE.
      print('Falha silenciosa na triagem Gemini: $e');
      resultadoTriagem = null;
      statusFinal = 'PENDENTE';
    }

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
        'foto_url': fotoUrlFinal == null || fotoUrlFinal.isEmpty
            ? null
            : fotoUrlFinal,
        'status': statusFinal,
        'cor_predominante':
            corPredominante == null || corPredominante.isEmpty
                ? null
                : corPredominante,
        'marca': marca == null || marca.isEmpty ? null : marca,
      },
    );

    final requerimentoId = insertResult.first.toColumnMap()['id'].toString();

    if (statusFinal == 'EM_ANALISE' &&
        resultadoTriagem != null &&
        resultadoTriagem.candidatoId != null) {
      await _registrarMatchTriagem(
        conn: conn,
        requerimentoNovoId: requerimentoId,
        candidatoId: resultadoTriagem.candidatoId!,
        score: resultadoTriagem.scoreConfianca,
        justificativa: resultadoTriagem.justificativa,
      );
    }

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Requerimento criado com sucesso',
        'id': requerimentoId,
        'status': statusFinal,
        'triagem': {
          'executada': candidatos.isNotEmpty,
          'candidato_id': resultadoTriagem?.candidatoId,
          'score_confianca': resultadoTriagem?.scoreConfianca ?? 0,
          'justificativa': resultadoTriagem?.justificativa,
        },
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

Future<List<Map<String, dynamic>>> _buscarCandidatosParaTriagem({
  required Connection conn,
  required String tipo,
  required String categoria,
}) async {
  final tipoOposto = tipo == 'PERDA' ? 'ACHADO' : 'PERDA';

  final result = await conn.execute(
    Sql.named('''
    SELECT
      id,
      tipo,
      categoria,
      local_ocorrencia,
      data_hora_ocorrencia,
      descricao,
      status,
      cor_predominante,
      marca
    FROM requerimentos
    WHERE tipo = @tipo_oposto
      AND LOWER(categoria) = LOWER(@categoria)
      AND data_hora_ocorrencia >= NOW() - INTERVAL '30 days'
      AND status <> 'CANCELADO'
      AND status <> 'EM_ANALISE'
    ORDER BY data_hora_ocorrencia DESC
    LIMIT 5;
    '''),
    parameters: {
      'tipo_oposto': tipoOposto,
      'categoria': categoria,
    },
  );

  return result.map((row) {
    final data = row.toColumnMap();

    return {
      'id': data['id'].toString(),
      'tipo': data['tipo'],
      'categoria': data['categoria'],
      'local_ocorrencia': data['local_ocorrencia'],
      'data_hora_ocorrencia': data['data_hora_ocorrencia']?.toString(),
      'descricao': data['descricao'],
      'status': data['status'],
      'cor_predominante': data['cor_predominante'],
      'marca': data['marca'],
    };
  }).toList();
}

  Future<void> _registrarMatchTriagem({
  required Connection conn,
  required String requerimentoNovoId,
  required String candidatoId,
  required int score,
  required String justificativa,
}) async {
  await conn.execute(
    Sql.named('''
    INSERT INTO matches_triagem (
      requerimento_novo_id,
      requerimento_candidato_id,
      score_confianca,
      justificativa,
      status_triagem,
      created_at,
      updated_at
    )
    VALUES (
      @requerimento_novo_id,
      @requerimento_candidato_id,
      @score_confianca,
      @justificativa,
      'PENDENTE_ADMIN',
      NOW(),
      NOW()
    );
    '''),
    parameters: {
      'requerimento_novo_id': requerimentoNovoId,
      'requerimento_candidato_id': candidatoId,
      'score_confianca': score,
      'justificativa': justificativa,
    },
  );

  // Quando a IA encontra um match forte, também ocultamos o candidato antigo
  // para evitar que ele continue aparecendo no feed público.
  await conn.execute(
    Sql.named('''
    UPDATE requerimentos
    SET 
      status = 'EM_ANALISE',
      updated_at = NOW()
    WHERE id = @requerimento_candidato_id;
    '''),
    parameters: {
      'requerimento_candidato_id': candidatoId,
    },
  );
}