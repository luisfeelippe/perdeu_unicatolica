import 'package:postgres/postgres.dart';

/// Singleton para gerir a ligação à base de dados PostgreSQL
class DB {
  static final DB _instance = DB._internal();
  Connection? _connection;

  factory DB() {
    return _instance;
  }

  DB._internal();

  Future<Connection> get connection async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }
    _connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'perdeu_db',
        username: 'postgres',
        password: 'root', // A senha que definimos no terminal
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return _connection!;
  }
}