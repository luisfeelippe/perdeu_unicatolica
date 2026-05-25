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
  final String? corPredominante;
  final String? marca;

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
    this.corPredominante,
    this.marca,
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
      corPredominante: json['cor_predominante']?.toString(),
      marca: json['marca']?.toString(),
    );
  }

  RequerimentoModel copyWith({
    String? id,
    String? tipo,
    String? categoria,
    String? localOcorrencia,
    DateTime? dataHoraOcorrencia,
    String? descricao,
    String? fotoUrl,
    String? status,
    String? usuarioNome,
    String? corPredominante,
    String? marca,
  }) {
    return RequerimentoModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      localOcorrencia: localOcorrencia ?? this.localOcorrencia,
      dataHoraOcorrencia: dataHoraOcorrencia ?? this.dataHoraOcorrencia,
      descricao: descricao ?? this.descricao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      status: status ?? this.status,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      corPredominante: corPredominante ?? this.corPredominante,
      marca: marca ?? this.marca,
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
      'cor_predominante': corPredominante,
      'marca': marca,
    };
  }
}