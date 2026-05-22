import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return Response(statusCode: 405);

  // Regra do Silêncio: Atraso fixo e resposta invariável para evitar enumeração
  await Future.delayed(const Duration(milliseconds: 800));
  
  return Response.json(
    statusCode: 200, 
    body: {'mensagem': 'Se a matrícula for válida, foi enviado um link de recuperação para o teu e-mail institucional'}
  );
}