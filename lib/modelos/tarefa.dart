import 'dart:convert';

class Tarefa {
  final String id;
  final String titulo;
  final String descricao;
  final DateTime data;
  final bool estaConcluida;
  final String prioridade; // prioridades: 'low' (baixa), 'medium' (média), 'high' (alta)

  Tarefa({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.data,
    this.estaConcluida = false,
    this.prioridade = 'medium',
  });

  Tarefa copyWith({
    String? id,
    String? titulo,
    String? descricao,
    DateTime? data,
    bool? estaConcluida,
    String? prioridade,
  }) {
    return Tarefa(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      data: data ?? this.data,
      estaConcluida: estaConcluida ?? this.estaConcluida,
      prioridade: prioridade ?? this.prioridade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'estaConcluida': estaConcluida,
      'prioridade': prioridade,
    };
  }

  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['id'] ?? '',
      titulo: map['titulo'] ?? map['title'] ?? '', // Fallback para compatibilidade com dados em inglês
      descricao: map['descricao'] ?? map['description'] ?? '', // Fallback para compatibilidade
      data: DateTime.parse(map['data'] ?? map['date']),
      estaConcluida: map['estaConcluida'] ?? map['isCompleted'] ?? false, // Fallback para compatibilidade
      prioridade: map['prioridade'] ?? map['priority'] ?? 'medium', // Fallback para compatibilidade
    );
  }

  String toJson() => json.encode(toMap());

  factory Tarefa.fromJson(String source) => Tarefa.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Tarefa(id: $id, titulo: $titulo, descricao: $descricao, data: $data, estaConcluida: $estaConcluida, prioridade: $prioridade)';
  }
}
