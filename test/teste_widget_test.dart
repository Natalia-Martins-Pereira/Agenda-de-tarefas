import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_tarefas/main.dart';

void main() {
  testWidgets('Teste de fumaça - Verifica se a tela de login renderiza', (WidgetTester tester) async {
    // Constrói o aplicativo com isLoggedIn = false
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verifica se a tela de login é exibida (ex: confere o título/entradas de texto)
    expect(find.text('Bem-vindo de Volta'), findsOneWidget);
    expect(find.text('USUÁRIO'), findsOneWidget);
  });
}
