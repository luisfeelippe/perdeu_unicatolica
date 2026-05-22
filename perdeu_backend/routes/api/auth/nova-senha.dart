import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart'; // <-- Importação do Postgres adicionada!
import '../../../lib/src/config/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final matricula = body['matricula'] as String?;
  final senhaAntiga = body['senha_antiga'] as String?;
  final novaSenha = body['nova_senha'] as String?;

  if (matricula == null || senhaAntiga == null || novaSenha == null) {
    return Response.json(statusCode: 400, body: {'erro': 'Dados incompletos'});
  }

  final db = await DB().connection;
  final result = await db.execute(
    Sql.named('SELECT senha_hash FROM usuarios WHERE matricula = @matricula'),
    parameters: {'matricula': matricula},
  );

  if (result.isEmpty) return Response(statusCode: 401);

  final hashAntigoDigitado = sha256.convert(utf8.encode(senhaAntiga)).toString();
  if (result[0][0] != hashAntigoDigitado) {
    return Response.json(statusCode: 401, body: {'erro': 'Credenciais inválidas'});
  }

  final novoHash = sha256.convert(utf8.encode(novaSenha)).toString();

  // Atualiza a palavra-passe e remove a flag de primeiro acesso
  await db.execute(
    Sql.named('UPDATE usuarios SET senha_hash = @hash, primeiro_acesso = false WHERE matricula = @matricula'),
    parameters: {'hash': novoHash, 'matricula': matricula},
  );

  return Response.json(body: {'mensagem': 'Palavra-passe atualizada com sucesso'});
}