import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/tarefa.dart';

class ServicoArmazenamento {
  static const String _chaveUsuarios = 'app_users';
  static const String _chaveUsuarioAtual = 'current_user';
  static const String _prefixoChaveTarefas = 'tasks_';

  // Instância Singleton
  static final ServicoArmazenamento _instancia = ServicoArmazenamento._interno();
  factory ServicoArmazenamento() => _instancia;
  ServicoArmazenamento._interno();

  SharedPreferences? _prefs;

  Future<void> inicializar() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Verifica se foi inicializado
  void _verificarInicializacao() {
    if (_prefs == null) {
      throw Exception('ServicoArmazenamento deve ser inicializado. Chame inicializar() primeiro.');
    }
  }

  // --- Autenticação ---

  // Cadastra o usuário
  // Retorna o status de sucesso e uma mensagem em caso de erro
  Future<Map<String, dynamic>> cadastrarUsuario(String usuario, String senha) async {
    _verificarInicializacao();
    final jsonUsuarios = _prefs!.getString(_chaveUsuarios);
    Map<String, String> usuarios = {};
    
    if (jsonUsuarios != null) {
      final Map<String, dynamic> decodificado = json.decode(jsonUsuarios);
      usuarios = decodificado.map((key, value) => MapEntry(key, value.toString()));
    }

    if (usuarios.containsKey(usuario.toLowerCase())) {
      return {'success': false, 'message': 'Nome de usuário já cadastrado.'};
    }

    usuarios[usuario.toLowerCase()] = senha;
    await _prefs!.setString(_chaveUsuarios, json.encode(usuarios));
    
    // Faz login automaticamente após o cadastro
    await _prefs!.setString(_chaveUsuarioAtual, usuario.toLowerCase());
    return {'success': true, 'message': 'Usuário cadastrado com sucesso!'};
  }

  // Faz login do usuário
  Future<Map<String, dynamic>> fazerLoginUsuario(String usuario, String senha) async {
    _verificarInicializacao();
    final jsonUsuarios = _prefs!.getString(_chaveUsuarios);
    if (jsonUsuarios == null) {
      return {'success': false, 'message': 'Usuário não encontrado. Cadastre-se primeiro!'};
    }

    final Map<String, dynamic> decodificado = json.decode(jsonUsuarios);
    final usuarios = decodificado.map((key, value) => MapEntry(key, value.toString()));

    final usuarioMinusculo = usuario.toLowerCase();
    if (!usuarios.containsKey(usuarioMinusculo)) {
      return {'success': false, 'message': 'Usuário não encontrado.'};
    }

    if (usuarios[usuarioMinusculo] != senha) {
      return {'success': false, 'message': 'Senha incorreta.'};
    }

    await _prefs!.setString(_chaveUsuarioAtual, usuarioMinusculo);
    return {'success': true, 'message': 'Login realizado com sucesso!'};
  }

  // Obtém o usuário logado atualmente
  String? obterUsuarioAtual() {
    _verificarInicializacao();
    return _prefs!.getString(_chaveUsuarioAtual);
  }

  // Faz logout
  Future<void> fazerLogout() async {
    _verificarInicializacao();
    await _prefs!.remove(_chaveUsuarioAtual);
  }

  // --- Armazenamento de Tarefas ---

  String _obterChaveTarefasUsuario() {
    final usuario = obterUsuarioAtual();
    if (usuario == null) throw Exception('Nenhum usuário logado.');
    return '$_prefixoChaveTarefas$usuario';
  }

  // Obtém todas as tarefas para o usuário logado
  List<Tarefa> obterTodasTarefas() {
    _verificarInicializacao();
    final chave = _obterChaveTarefasUsuario();
    final jsonTarefas = _prefs!.getString(chave);
    if (jsonTarefas == null) return [];

    try {
      final List<dynamic> decodificado = json.decode(jsonTarefas);
      return decodificado.map((mapaTarefa) => Tarefa.fromMap(mapaTarefa)).toList();
    } catch (e) {
      return [];
    }
  }

  // Obtém as tarefas para uma data específica (ignorando a hora)
  List<Tarefa> obterTarefasPorData(DateTime data) {
    final todasTarefas = obterTodasTarefas();
    return todasTarefas.where((tarefa) {
      return tarefa.data.year == data.year &&
             tarefa.data.month == data.month &&
             tarefa.data.day == data.day;
    }).toList();
  }

  // Salva a lista de todas as tarefas
  Future<void> _salvarTodasTarefas(List<Tarefa> tarefas) async {
    _verificarInicializacao();
    final chave = _obterChaveTarefasUsuario();
    final lista = tarefas.map((tarefa) => tarefa.toMap()).toList();
    await _prefs!.setString(chave, json.encode(lista));
  }

  // Adiciona uma tarefa
  Future<void> adicionarTarefa(Tarefa tarefa) async {
    final tarefas = obterTodasTarefas();
    tarefas.add(tarefa);
    await _salvarTodasTarefas(tarefas);
  }

  // Remove uma tarefa
  Future<void> removerTarefa(String idTarefa) async {
    final tarefas = obterTodasTarefas();
    tarefas.removeWhere((tarefa) => tarefa.id == idTarefa);
    await _salvarTodasTarefas(tarefas);
  }

  // Alterna a conclusão de uma tarefa
  Future<void> alternarConclusaoTarefa(String idTarefa) async {
    final tarefas = obterTodasTarefas();
    final indice = tarefas.indexWhere((tarefa) => tarefa.id == idTarefa);
    if (indice != -1) {
      tarefas[indice] = tarefas[indice].copyWith(estaConcluida: !tarefas[indice].estaConcluida);
      await _salvarTodasTarefas(tarefas);
    }
  }
}
