# Agenda de Tarefas 🌸

Um aplicativo moderno, elegante e intuitivo desenvolvido em Flutter para gerenciar tarefas diárias integrando calendário e lista de tarefas com uma interface premium e futurista na paleta de cores rosa e tons escuros (*Rose & Berry Dark Mode*).

---

## ✨ Funcionalidades

- **Autenticação Simulada (Cadastro e Login)**: Sistema local que gerencia sessões de usuário simulando armazenamento persistente com segurança local.
- **Calendário Dinâmico**: Visualização completa do mês em português (PT-BR), sinalizando visualmente os dias que contêm tarefas pendentes e concluídas com pontos luminosos coloridos.
- **Painel de Progresso**: Monitoramento e cálculo em tempo real da porcentagem de conclusão de tarefas para o dia selecionado.
- **Organização Inteligente**: Exibição das tarefas organizadas em duas sessões: pendentes no topo e concluídas ao final. A ordenação respeita uma estrutura alfabética rigorosa em cada seção.
- **Ações Rápidas**:
  - **Buscar por Data**: Permite digitar uma data no formato padrão `DD/MM/AAAA` para localizar rapidamente e focar o calendário no dia desejado.
  - **Concluídas do Mês**: Visualização em painel inferior (*Bottom Sheet*) de todas as tarefas que foram marcadas como concluídas no respectivo mês em exibição.
- **Design Customizado**: Paleta de cores exclusiva com tons de rosa vibrante, orchid e berry, com estilo moderno usando efeitos de iluminação e Glassmorphic.

---

## 🛠️ Tecnologias Utilizadas

O projeto foi construído utilizando as seguintes ferramentas:
- **[Flutter](https://flutter.dev/)** (Framework UI)
- **[Dart](https://dart.dev/)** (Linguagem de programação)
- **[SharedPreferences](https://pub.dev/packages/shared_preferences)** (Persistência de dados local segura)
- **[Table Calendar](https://pub.dev/packages/table_calendar)** (Componente do calendário dinâmico)
- **[Google Fonts (Outfit)](https://pub.dev/packages/google_fonts)** (Tipografia moderna de alto padrão)
- **[Intl](https://pub.dev/packages/intl)** (Internacionalização e formatação de datas em PT-BR)

---

## 🚀 Como Executar o Projeto

Para executar o projeto localmente, certifique-se de possuir o SDK do Flutter configurado em sua máquina.

1. **Clonar o Repositório**:
   ```bash
   git clone <link-do-repositorio>
   cd agenda_tarefas
   ```

2. **Obter dependências**:
   ```bash
   flutter pub get
   ```

3. **Executar em modo desenvolvimento**:
   ```bash
   flutter run
   ```

4. **Rodar testes unitários e de widgets**:
   ```bash
   flutter test
   ```
