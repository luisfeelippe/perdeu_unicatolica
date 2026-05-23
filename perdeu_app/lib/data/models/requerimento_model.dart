class RequerimentoModel {
  final String id;
  final String tipo;
  final String categoria;
  final String localOcorrencia;
  final DateTime dataHoraOcorrencia;
  final String descricao;
  final String? fotoUrl;
  final String status;
  final String? usuarioNome;

  RequerimentoModel({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.localOcorrencia,
    required this.dataHoraOcorrencia,
    required this.descricao,
    required this.status,
    this.fotoUrl,
    this.usuarioNome,
  });

  factory RequerimentoModel.fromJson(Map<String, dynamic> json) {
    return RequerimentoModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      localOcorrencia: json['local_ocorrencia']?.toString() ?? '',
      dataHoraOcorrencia: DateTime.tryParse(
            json['data_hora_ocorrencia']?.toString() ?? '',
          ) ??
          DateTime.now(),
      descricao: json['descricao']?.toString() ?? '',
      fotoUrl: json['foto_url']?.toString(),
      status: json['status']?.toString() ?? '',
      usuarioNome: json['usuario_nome']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'categoria': categoria,
      'local_ocorrencia': localOcorrencia,
      'data_hora_ocorrencia': dataHoraOcorrencia.toIso8601String(),
      'descricao': descricao,
      'foto_url': fotoUrl,
      'status': status,
      'usuario_nome': usuarioNome,
    };
  }
}