import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:perdeu_backend/src/config/auth_jwt.dart';
import 'package:perdeu_backend/src/config/db.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  final bloqueio = bloquearSeNaoAdmin(request);
  if (bloqueio != null) return bloqueio;

  if (request.method == HttpMethod.get) {
    return _listarUsuarios();
  }

  if (request.method == HttpMethod.post) {
    return _criarUsuario(request);
  }

  return Response.json(
    statusCode: 405,
    body: {
      'erro': 'Método não permitido',
    },
  );
}

Future<Response> _listarUsuarios() async {
  try {
    final conn = await DB().connection;

    final result = await conn.execute('''
      SELECT
        id,
        nome_completo,
        matricula,
        perfil,
        status_ativo,
        email_institucional,
        email,
        curso,
        semestre,
        cpf
      FROM usuarios
      ORDER BY nome_completo ASC;
    ''');

    final dados = result.map((row) {
      final data = row.toColumnMap();

      final emailFinal =
          data['email_institucional'] ?? data['email'] ?? '';

      return {
        'id': data['id'].toString(),
        'nome_completo': data['nome_completo'],
        'matricula': data['matricula'],
        'perfil': data['perfil'],
        'status_ativo': data['status_ativo'],
        'email': emailFinal,
        'email_institucional': emailFinal,
        'curso': data['curso'],
        'semestre': data['semestre'],
        'cpf': data['cpf'],
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
        'erro': 'Erro ao carregar usuários',
        'detalhe': e.toString(),
      },
    );
  }
}

Future<Response> _criarUsuario(Request request) async {
  try {
    final body = await request.json() as Map<String, dynamic>;

    final nomeCompleto = body['nome_completo']?.toString().trim();
    final matricula = body['matricula']?.toString().trim();
    final email = body['email']?.toString().trim();
    final curso = body['curso']?.toString().trim();
    final semestre = body['semestre']?.toString().trim();
    final cpf = body['cpf']?.toString().trim();
    final statusAtivo = body['status_ativo'];

    if (nomeCompleto == null || nomeCompleto.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'Nome completo é obrigatório'},
      );
    }

    if (matricula == null || matricula.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'Matrícula é obrigatória'},
      );
    }

    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'E-mail institucional é obrigatório'},
      );
    }

    if (curso == null || curso.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'Curso é obrigatório'},
      );
    }

    if (semestre == null || semestre.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'Semestre é obrigatório'},
      );
    }

    if (cpf == null || cpf.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'CPF é obrigatório'},
      );
    }

    if (statusAtivo is! bool) {
      return Response.json(
        statusCode: 400,
        body: {'erro': 'Status ativo deve ser true ou false'},
      );
    }

    final conn = await DB().connection;

    final existente = await conn.execute(
      Sql.named('''
      SELECT id
      FROM usuarios
      WHERE matricula = @matricula
         OR email = @email
         OR email_institucional = @email
         OR cpf = @cpf
      LIMIT 1;
      '''),
      parameters: {
        'matricula': matricula,
        'email': email,
        'cpf': cpf,
      },
    );

    if (existente.isNotEmpty) {
      return Response.json(
        statusCode: 409,
        body: {
          'erro': 'Já existe usuário com esta matrícula, e-mail ou CPF',
        },
      );
    }

    const senhaPadrao = 'perdeuunicatolica';

    final senhaHash = sha256.convert(
      utf8.encode(senhaPadrao),
    ).toString();

    final result = await conn.execute(
      Sql.named('''
      INSERT INTO usuarios (
        nome_completo,
        matricula,
        senha_hash,
        perfil,
        primeiro_acesso,
        status_ativo,
        email,
        email_institucional,
        curso,
        semestre,
        cpf
      )
      VALUES (
        @nome_completo,
        @matricula,
        @senha_hash,
        'ALUNO',
        true,
        @status_ativo,
        @email,
        @email,
        @curso,
        @semestre,
        @cpf
      )
      RETURNING
        id,
        nome_completo,
        matricula,
        perfil,
        status_ativo,
        email,
        email_institucional,
        curso,
        semestre,
        cpf;
      '''),
      parameters: {
        'nome_completo': nomeCompleto,
        'matricula': matricula,
        'senha_hash': senhaHash,
        'status_ativo': statusAtivo,
        'email': email,
        'curso': curso,
        'semestre': semestre,
        'cpf': cpf,
      },
    );

    final data = result.first.toColumnMap();

    final emailFinal =
        data['email_institucional'] ?? data['email'] ?? email;

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Usuário criado com sucesso',
        'senha_inicial': senhaPadrao,
        'usuario': {
          'id': data['id'].toString(),
          'nome_completo': data['nome_completo'],
          'matricula': data['matricula'],
          'perfil': data['perfil'],
          'status_ativo': data['status_ativo'],
          'email': emailFinal,
          'email_institucional': emailFinal,
          'curso': data['curso'],
          'semestre': data['semestre'],
          'cpf': data['cpf'],
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'erro': 'Erro ao criar usuário',
        'detalhe': e.toString(),
      },
    );
  }
}