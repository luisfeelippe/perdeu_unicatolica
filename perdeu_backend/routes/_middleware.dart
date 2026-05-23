import 'package:dart_frog/dart_frog.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

Handler middleware(Handler handler) {
  return (context) async {
    // Responde às requisições de pré-verificação do navegador.
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: _corsHeaders,
      );
    }

    final response = await handler(context);

    return response.copyWith(
      headers: {
        ...response.headers,
        ..._corsHeaders,
      },
    );
  };
}