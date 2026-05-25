class RequerimentoDraft {
  String? tipo;
  String? categoria;
  String? localOcorrencia;
  DateTime? dataHoraOcorrencia;
  String? corPredominante;
  String? marca;
  String? descricao;
  String? caminhoFotoLocal;

  RequerimentoDraft({
    this.tipo,
    this.categoria,
    this.localOcorrencia,
    this.dataHoraOcorrencia,
    this.corPredominante,
    this.marca,
    this.descricao,
    this.caminhoFotoLocal,
  });

  RequerimentoDraft copyWith({
    String? tipo,
    String? categoria,
    String? localOcorrencia,
    DateTime? dataHoraOcorrencia,
    String? corPredominante,
    String? marca,
    String? descricao,
    String? caminhoFotoLocal,
  }) {
    return RequerimentoDraft(
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      localOcorrencia: localOcorrencia ?? this.localOcorrencia,
      dataHoraOcorrencia: dataHoraOcorrencia ?? this.dataHoraOcorrencia,
      corPredominante: corPredominante ?? this.corPredominante,
      marca: marca ?? this.marca,
      descricao: descricao ?? this.descricao,
      caminhoFotoLocal: caminhoFotoLocal ?? this.caminhoFotoLocal,
    );
  }

  Map<String, dynamic> toJson({
    required String matricula,
    String? fotoBase64,
  }) {
    return {
      'matricula': matricula,
      'tipo': tipo,
      'categoria': categoria,
      'local_ocorrencia': localOcorrencia,
      'data_hora_ocorrencia': dataHoraOcorrencia?.toIso8601String(),
      'cor_predominante': corPredominante,
      'marca': marca,
      'descricao': descricao,
      'foto_url': null,
      'foto_base64': fotoBase64,
    };
  }
}