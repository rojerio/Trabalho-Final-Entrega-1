import 'package:flutter/material.dart';

/// Widgets usados pelas telas para mostrar cada estado do Cubit.

class EstadoCarregando extends StatelessWidget {
  const EstadoCarregando({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String? textoBotao;
  final VoidCallback? aoPressionar;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.mensagem,
    this.textoBotao,
    this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            if (textoBotao != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: aoPressionar,
                icon: const Icon(Icons.add),
                label: Text(textoBotao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback aoTentarNovamente;

  const EstadoErro({super.key, required this.mensagem, required this.aoTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pergunta antes de remover. Devolve true se o usuário confirmar.
Future<bool> confirmarExclusao(BuildContext context, {required String titulo, required String mensagem}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

void mostrarMensagem(BuildContext context, String mensagem, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? Colors.redAccent : null,
    ));
}
