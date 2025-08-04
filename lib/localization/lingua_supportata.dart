class LinguaSupportata {
  final String nome;
  final String livello;

  LinguaSupportata({required this.nome, required this.livello});

  factory LinguaSupportata.fromJson(Map<String, dynamic> json) {
    return LinguaSupportata(
      nome: json['nome'],
      livello: json['livello'],
    );
  }
} 