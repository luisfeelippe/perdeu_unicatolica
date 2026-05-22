import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/src/config/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Método não permitido');
  }

  final body = await context.request.json() as Map<String, dynamic>;
  
  // O trim() remove espaços em branco que o usuário possa ter digitado sem querer
  final matricula = (body['matricula'] as String?)?.trim();
  final senha = (body['senha'] as String?)?.trim();

  if (matricula == null || senha == null) {
    return Response.json(statusCode: 400, body: {'erro': 'Credenciais em falta'});
  }

  final db = await DB().connection;
  final result = await db.execute(
    Sql.named('SELECT id, senha_hash, perfil, primeiro_acesso, status_ativo FROM usuarios WHERE matricula = @matricula'),
    parameters: {'matricula': matricula},
  );

  final bytes = utf8.encode(senha);
  final hashDigitado = sha256.convert(bytes).toString();

  // --- DEBUG VIBE CODING ---
  print('\n--- TENTATIVA DE LOGIN ---');
  print('Matrícula recebida: "$matricula"');
  if (result.isEmpty) {
    print('Erro: Matrícula não encontrada no banco de dados.');
  } else {
    print('Hash Salvo no Banco: ${result[0][1]}');
    print('Hash Gerado no Dart: $hashDigitado');
    print('Status Ativo: ${result[0][4]}');
  }
  print('--------------------------\n');
  // -------------------------

  if (result.isEmpty || result[0][1] != hashDigitado || result[0][4] == false) {
    await Future.delayed(const Duration(milliseconds: 1500));
    return Response.json(statusCode: 401, body: {'erro': 'Credenciais inválidas'});
  }

  final user = result[0];
  final id = user[0] as String;
  final perfil = user[2] as String;
  final primeiroAcesso = user[3] as bool;

  final jwt = JWT({
    'id': id,
    'matricula': matricula,
    'perfil': perfil,
  });

  final token = jwt.sign(SecretKey('CHAVE_SECRETA_SUPER_SEGURA_UNICATOLICA'));

  return Response.json(body: {
    'token': token,
    'primeiro_acesso': primeiroAcesso,
  });
}