import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'telas/tela_login_cadastro.dart';
import 'telas/tela_calendario_tarefas.dart';
import 'servicos/servico_armazenamento.dart';

void main() async {
  // Garante que o motor do Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o serviço de armazenamento
  final storageService = ServicoArmazenamento();
  await storageService.inicializar();
  
  // Verifica se um usuário já está logado
  final bool isLoggedIn = storageService.obterUsuarioAtual() != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A0B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF75A0),
          secondary: Color(0xFFFFB3C6),
          tertiary: Color(0xFFE08DAD),
          background: Color(0xFF1A0B14),
          surface: Color(0xFF2C1423),
          error: Colors.redAccent,
        ),
        // Usa a estilização moderna do Google Fonts
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const TelaCalendarioTarefas() : const TelaLoginCadastro(),
    );
  }
}
