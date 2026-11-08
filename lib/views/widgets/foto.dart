import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/foto_service.dart';
import 'estados.dart';

/// Mostra a foto salva no aparelho ou, se não houver, a do servidor.
class FotoView extends StatelessWidget {
  final String? fotoLocal;
  final String? fotoUrl;
  final double tamanho;
  final IconData iconeVazio;
  final bool circular;

  const FotoView({
    super.key,
    this.fotoLocal,
    this.fotoUrl,
    this.tamanho = 56,
    this.iconeVazio = Icons.pets,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget conteudo;
    if (FotoService.existe(fotoLocal)) {
      conteudo = Image.file(File(fotoLocal!), fit: BoxFit.cover, width: tamanho, height: tamanho);
    } else if (fotoUrl != null) {
      conteudo = Image.network(
        fotoUrl!,
        fit: BoxFit.cover,
        width: tamanho,
        height: tamanho,
        errorBuilder: (_, __, ___) => _vazio(context),
      );
    } else {
      conteudo = _vazio(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(circular ? tamanho / 2 : 12),
      child: SizedBox(width: tamanho, height: tamanho, child: conteudo),
    );
  }

  Widget _vazio(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(iconeVazio, size: tamanho * 0.5, color: Theme.of(context).colorScheme.primary),
      );
}

/// Campo de formulário para tirar ou escolher uma foto (recurso nativo).
class FotoSelector extends StatelessWidget {
  final String? fotoLocal;
  final String? fotoUrl;
  final String rotulo;
  final IconData iconeVazio;
  final ValueChanged<String> aoSelecionar;

  const FotoSelector({
    super.key,
    this.fotoLocal,
    this.fotoUrl,
    required this.rotulo,
    this.iconeVazio = Icons.photo_camera_outlined,
    required this.aoSelecionar,
  });

  Future<void> _selecionar(BuildContext context, ImageSource origem) async {
    try {
      final caminho = await FotoService().selecionar(origem);
      if (caminho != null) aoSelecionar(caminho);
    } catch (e) {
      if (context.mounted) {
        mostrarMensagem(context, e.toString().replaceFirst('Exception: ', ''), erro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FotoView(
          fotoLocal: fotoLocal,
          fotoUrl: fotoUrl,
          tamanho: 88,
          circular: false,
          iconeVazio: iconeVazio,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selecionar(context, ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Câmera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _selecionar(context, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeria'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
