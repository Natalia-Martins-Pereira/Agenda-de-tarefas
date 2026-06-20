import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../modelos/tarefa.dart';
import '../servicos/servico_armazenamento.dart';
import 'tela_login_cadastro.dart';

class TelaCalendarioTarefas extends StatefulWidget {
  const TelaCalendarioTarefas({Key? key}) : super(key: key);

  @override
  State<TelaCalendarioTarefas> createState() => _TelaCalendarioTarefasState();
}

class _TelaCalendarioTarefasState extends State<TelaCalendarioTarefas> {
  final ServicoArmazenamento _servicoArmazenamento = ServicoArmazenamento();
  
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<Tarefa> _todasTarefas = [];
  String _usuario = '';
  
  @override
  void initState() {
    super.initState();
    // Inicializa a formatação de datas em português
    initializeDateFormatting('pt_BR', null);
    
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _usuario = _servicoArmazenamento.obterUsuarioAtual() ?? 'Usuário';
    _carregarTarefas();
  }

  void _carregarTarefas() {
    setState(() {
      _todasTarefas = _servicoArmazenamento.obterTodasTarefas();
    });
  }

  // Lógica de ordenação: pendentes primeiro, depois concluídas, ambas alfabeticamente
  List<Tarefa> _obterTarefasOrdenadasParaDataSelecionada() {
    final tarefasParaData = _todasTarefas.where((tarefa) {
      return tarefa.data.year == _selectedDay.year &&
             tarefa.data.month == _selectedDay.month &&
             tarefa.data.day == _selectedDay.day;
    }).toList();

    tarefasParaData.sort((a, b) {
      // 1. Pendentes (false) primeiro, concluídas (true) depois
      if (a.estaConcluida != b.estaConcluida) {
        return a.estaConcluida ? 1 : -1;
      }
      // 2. Ambas compartilham o mesmo estado de conclusão, ordena alfabeticamente por título
      return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    });

    return tarefasParaData;
  }

  // Busca eventos do dia para o calendário (retorna tarefas para desenhar os pontos indicadores)
  List<Tarefa> _obterEventosDoDia(DateTime dia) {
    return _todasTarefas.where((tarefa) {
      return tarefa.data.year == dia.year &&
             tarefa.data.month == dia.month &&
             tarefa.data.day == dia.day;
    }).toList();
  }

  Future<void> _lidarAdicionarTarefa(String titulo, String descricao, String prioridade) async {
    final novaTarefa = Tarefa(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      descricao: descricao,
      data: _selectedDay,
      prioridade: prioridade,
      estaConcluida: false,
    );

    await _servicoArmazenamento.adicionarTarefa(novaTarefa);
    _carregarTarefas();
  }

  Future<void> _lidarExcluirTarefa(String idTarefa) async {
    await _servicoArmazenamento.removerTarefa(idTarefa);
    _carregarTarefas();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarefa removida com sucesso.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _lidarAlternarConclusao(String idTarefa) async {
    await _servicoArmazenamento.alternarConclusaoTarefa(idTarefa);
    _carregarTarefas();
  }

  void _lidarLogout() async {
    await _servicoArmazenamento.fazerLogout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TelaLoginCadastro()),
      );
    }
  }

  // String de data formatada para a data selecionada
  String _obterDataSelecionadaFormatada() {
    return DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(_selectedDay);
  }

  DateTime? _analisarData(String input) {
    // Valida formatos DD/MM/AAAA ou D/M/AAAA
    final regex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    if (!regex.hasMatch(input)) return null;

    final match = regex.firstMatch(input);
    if (match == null) return null;

    final dia = int.tryParse(match.group(1)!) ?? 0;
    final mes = int.tryParse(match.group(2)!) ?? 0;
    final ano = int.tryParse(match.group(3)!) ?? 0;

    if (dia < 1 || dia > 31 || mes < 1 || mes > 12 || ano < 2000 || ano > 2099) {
      return null;
    }

    try {
      final date = DateTime(ano, mes, dia);
      if (date.day != dia || date.month != mes || date.year != ano) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  void _exibirDialogoBuscarData() {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF2C1423).withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF75A0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search_rounded, color: Color(0xFFFF75A0)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscar por Data',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'DIGITE A DATA DESEJADA',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF75A0),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _decoracaoInputDialogo('Ex: 25/12/2026'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira a data';
                      }
                      if (_analisarData(value.trim()) == null) {
                        return 'Data inválida. Use o formato DD/MM/AAAA';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF75A0), Color(0xFFFF2A85)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final dataAnalisada = _analisarData(dateController.text.trim())!;
                      setState(() {
                        _selectedDay = dataAnalisada;
                        _focusedDay = dataAnalisada;
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Buscar',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exibirPainelTarefasConcluidasMes() {
    final tarefasConcluidas = _todasTarefas.where((tarefa) {
      return tarefa.estaConcluida &&
             tarefa.data.year == _focusedDay.year &&
             tarefa.data.month == _focusedDay.month;
    }).toList();

    // Ordena por dia, depois alfabeticamente
    tarefasConcluidas.sort((a, b) {
      if (a.data.day != b.data.day) {
        return a.data.day.compareTo(b.data.day);
      }
      return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    });

    final nomeMes = DateFormat('MMMM', 'pt_BR').format(_focusedDay);
    final mesCapitalizado = '${nomeMes[0].toUpperCase()}${nomeMes.substring(1)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C1423),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: const Color(0xFFFF75A0).withOpacity(0.2), width: 1.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Concluídas em $mesCapitalizado',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tarefasConcluidas.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma tarefa concluída neste mês.',
                            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          itemCount: tarefasConcluidas.length,
                          itemBuilder: (context, index) {
                            final tarefa = tarefasConcluidas[index];
                            final diaFormatado = DateFormat('dd/MM').format(tarefa.data);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Color(0xFFFF75A0), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tarefa.titulo,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (tarefa.descricao.isNotEmpty)
                                          Text(
                                            tarefa.descricao,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    diaFormatado,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white30,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Diálogo para adicionar tarefa (modal bottom sheet ou diálogo de alerta estilizado)
  void _exibirDialogoAdicionarTarefa() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String prioridadeSelecionada = 'medium';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: const Color(0xFF2C1423).withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF75A0).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_task_rounded, color: Color(0xFFFF75A0)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nova Tarefa',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'TÍTULO',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF75A0),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: titleController,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: _decoracaoInputDialogo('Ex: Comprar leite'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'O título é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'DESCRIÇÃO',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF75A0),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descController,
                          style: GoogleFonts.outfit(color: Colors.white),
                          maxLines: 2,
                          decoration: _decoracaoInputDialogo('Descrição opcional'),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'PRIORIDADE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF75A0),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _chipPrioridade(
                              label: 'Baixa',
                              value: 'low',
                              selectedColor: const Color(0xFFFFB3C6),
                              isSelected: prioridadeSelecionada == 'low',
                              onTap: () => setDialogState(() => prioridadeSelecionada = 'low'),
                            ),
                            _chipPrioridade(
                              label: 'Média',
                              value: 'medium',
                              selectedColor: const Color(0xFFE08DAD),
                              isSelected: prioridadeSelecionada == 'medium',
                              onTap: () => setDialogState(() => prioridadeSelecionada = 'medium'),
                            ),
                            _chipPrioridade(
                              label: 'Alta',
                              value: 'high',
                              selectedColor: const Color(0xFFFF2A85),
                              isSelected: prioridadeSelecionada == 'high',
                              onTap: () => setDialogState(() => prioridadeSelecionada = 'high'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF75A0), Color(0xFFFF2A85)],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          _lidarAdicionarTarefa(
                            titleController.text.trim(),
                            descController.text.trim(),
                            prioridadeSelecionada,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Adicionar',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chipPrioridade({
    required String label,
    required String value,
    required Color selectedColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? selectedColor : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracaoInputDialogo(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF75A0), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tarefasOrdenadas = _obterTarefasOrdenadasParaDataSelecionada();
    final tarefasPendentes = tarefasOrdenadas.where((t) => !t.estaConcluida).toList();
    final tarefasConcluidasList = tarefasOrdenadas.where((t) => t.estaConcluida).toList();
    final tarefasDia = _obterEventosDoDia(_selectedDay);
    final contagemConcluidas = tarefasDia.where((t) => t.estaConcluida).length;
    final contagemTotal = tarefasDia.length;
    final taxaConclusao = contagemTotal > 0 ? (contagemConcluidas / contagemTotal) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0B14),
      body: Stack(
        children: [
          // Luz ambiental de fundo
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB3C6).withOpacity(0.18),
                    blurRadius: 140,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF75A0).withOpacity(0.18),
                    blurRadius: 140,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Linha de cabeçalho com informações do usuário e botão de sair
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${_usuario[0].toUpperCase()}${_usuario.substring(1)}!',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Organize o seu dia',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white60,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                        // Botão brilhante de logout
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                             border: Border.all(color: Colors.white.withOpacity(0.15)),
                            color: const Color(0xFF2C1423).withOpacity(0.6),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF2A85), size: 20),
                            onPressed: _lidarLogout,
                            tooltip: 'Sair da Conta',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contêiner do calendário em forma de cartão
                  Card(
                    elevation: 0,
                    color: const Color(0xFF2C1423).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TableCalendar(
                            locale: 'pt_BR',
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            eventLoader: _obterEventosDoDia,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            headerStyle: HeaderStyle(
                               formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Color(0xFFFF75A0)),
                              rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF75A0)),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.w600),
                              weekendStyle: GoogleFonts.outfit(color: const Color(0xFFFF2A85), fontWeight: FontWeight.w600),
                            ),
                            calendarStyle: CalendarStyle(
                              defaultTextStyle: GoogleFonts.outfit(color: Colors.white),
                              weekendTextStyle: GoogleFonts.outfit(color: Colors.white70),
                              outsideDaysVisible: false,
                              todayDecoration: BoxDecoration(
                                color: const Color(0xFFE08DAD).withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE08DAD), width: 1.5),
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFFFF75A0),
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: GoogleFonts.outfit(
                                color: const Color(0xFF1A0B14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isNotEmpty) {
                                  final temPendente = events.cast<Tarefa>().any((t) => !t.estaConcluida);
                                  return Positioned(
                                    bottom: 5,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: temPendente ? const Color(0xFFFF2A85) : const Color(0xFFFFB3C6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (temPendente ? const Color(0xFFFF2A85) : const Color(0xFFFFB3C6)).withOpacity(0.5),
                                            blurRadius: 3,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Painel de estatísticas do dia
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2C1423).withOpacity(0.4),
                          const Color(0xFF2C1423).withOpacity(0.7)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _obterDataSelecionadaFormatada(),
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contagemTotal == 0
                                    ? 'Nenhuma tarefa agendada'
                                    : '$contagemConcluidas de $contagemTotal tarefas concluídas',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (contagemTotal > 0)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 42,
                                height: 42,
                                child: CircularProgressIndicator(
                                  value: taxaConclusao,
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    taxaConclusao == 1.0 ? const Color(0xFFFF2A85) : const Color(0xFFFF75A0),
                                  ),
                                  strokeWidth: 4,
                                ),
                              ),
                              Text(
                                '${(taxaConclusao * 100).toInt()}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Linha de Ações Rápidas (Buscar Data e Concluídas do Mês)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exibirDialogoBuscarData,
                          icon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFFF75A0)),
                          label: Text(
                            'Buscar por Data',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exibirPainelTarefasConcluidasMes,
                          icon: const Icon(Icons.playlist_add_check_rounded, size: 20, color: Color(0xFFFFB3C6)),
                          label: Text(
                            'Concluídas do Mês',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Linha de cabeçalho das tarefas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LISTA DE TAREFAS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF75A0),
                          letterSpacing: 1.5,
                        ),
                      ),
                      // Botão de adicionar estilizado como botão de ação flutuante
                      GestureDetector(
                        onTap: _exibirDialogoAdicionarTarefa,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF75A0), Color(0xFFFF2A85)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF75A0).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Nova',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),

                  // Lista de tarefas
                  Expanded(
                    child: tarefasOrdenadas.isEmpty
                        ? _construirEstadoVazio()
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              // Tarefas pendentes (ordem alfabética)
                              if (tarefasPendentes.isNotEmpty) ...[
                                ...tarefasPendentes.map((tarefa) => _construirItemTarefa(tarefa)),
                              ],
                              // Seção de tarefas concluídas
                              if (tarefasConcluidasList.isNotEmpty) ...[
                                if (tarefasPendentes.isNotEmpty) const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Colors.white10, height: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Text(
                                        'TAREFAS CONCLUÍDAS',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF75A0),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Colors.white10, height: 1)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...tarefasConcluidasList.map((tarefa) => _construirItemTarefa(tarefa)),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.done_all_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.08),
          ),
          const SizedBox(height: 12),
          Text(
            'Tudo limpo para este dia!',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clique em "+ Nova" acima para começar.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemTarefa(Tarefa tarefa) {
    Color corPrioridade;
    switch (tarefa.prioridade) {
      case 'high':
        corPrioridade = const Color(0xFFFF2A85);
        break;
      case 'medium':
        corPrioridade = const Color(0xFFE08DAD);
        break;
      default:
        corPrioridade = const Color(0xFFFFB3C6);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tarefa.estaConcluida
            ? const Color(0xFF2C1423).withOpacity(0.2)
            : const Color(0xFF2C1423).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tarefa.estaConcluida
              ? Colors.white.withOpacity(0.02)
              : corPrioridade.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () => _lidarAlternarConclusao(tarefa.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: tarefa.estaConcluida
                    ? const Color(0xFFFF75A0)
                    : Colors.white.withOpacity(0.4),
                width: 2,
              ),
              color: tarefa.estaConcluida ? const Color(0xFFFF75A0).withOpacity(0.15) : Colors.transparent,
            ),
            child: tarefa.estaConcluida
                ? const Icon(Icons.check, size: 16, color: Color(0xFFFF75A0))
                : null,
          ),
        ),
        title: Text(
          tarefa.titulo,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: tarefa.estaConcluida ? Colors.white38 : Colors.white,
          ),
        ),
        subtitle: tarefa.descricao.isNotEmpty
            ? Text(
                tarefa.descricao,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: tarefa.estaConcluida ? Colors.white24 : Colors.white60,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pequena etiqueta indicando a prioridade
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corPrioridade.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tarefa.prioridade == 'high' ? 'Alta' : (tarefa.prioridade == 'medium' ? 'Média' : 'Baixa'),
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: corPrioridade,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão de excluir
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.shade100, size: 20),
              onPressed: () => _lidarExcluirTarefa(tarefa.id),
            ),
          ],
        ),
      ),
    );
  }
}
