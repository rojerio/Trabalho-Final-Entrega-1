import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Recurso nativo: câmera e galeria.
/// As fotos ficam salvas no aparelho e são enviadas ao Supabase na sincronização.
class FotoService {
  final ImagePicker _picker = ImagePicker();

  /// Tira ou escolhe uma foto e devolve o caminho do arquivo salvo no app.
  /// Devolve null se o usuário cancelar.
  Future<String?> selecionar(ImageSource origem) async {
    if (kIsWeb) {
      throw Exception('Fotos não são suportadas na versão web.');
    }

    final arquivo = await _picker.pickImage(
      source: origem,
      maxWidth: 1280,
      imageQuality: 75,
    );
    if (arquivo == null) return null;

    final pasta = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'fotos'));
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    final destino = p.join(pasta.path, 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await arquivo.saveTo(destino);
    return destino;
  }

  Future<Uint8List?> lerBytes(String caminho) async {
    if (kIsWeb) return null;
    final arquivo = File(caminho);
    if (!await arquivo.exists()) return null;
    return arquivo.readAsBytes();
  }

  static bool existe(String? caminho) {
    if (kIsWeb || caminho == null) return false;
    return File(caminho).existsSync();
  }
}
