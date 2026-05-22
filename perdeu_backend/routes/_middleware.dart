import 'package:dart_frog/dart_frog.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as shelf;

Handler middleware(Handler handler) {
  return handler.use(
    fromShelfMiddleware(
      shelf.corsHeaders(
        headers: {
          shelf.ACCESS_CONTROL_ALLOW_ORIGIN: '*', // Permite que o Chrome (Flutter Web) acesse a API
          shelf.ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
          shelf.ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Authorization',
        },
      ),
    ),
  );
}