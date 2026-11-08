import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Recurso nativo: GPS do aparelho.
class LocalizacaoService {
  /// Posição atual do aparelho. Lança uma exceção com uma mensagem amigável
  /// se o GPS estiver desligado ou a permissão for negada.
  Future<LatLng> posicaoAtual() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw Exception('Ative a localização (GPS) do aparelho.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw Exception('Permissão de localização negada.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização bloqueada. Libere nas configurações do aparelho.');
    }

    final posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(posicao.latitude, posicao.longitude);
  }

  /// Igual a [posicaoAtual], mas devolve null em vez de lançar exceção.
  Future<LatLng?> tentarPosicaoAtual() async {
    try {
      return await posicaoAtual();
    } catch (_) {
      return null;
    }
  }

  /// Distância em quilômetros entre dois pontos.
  double distanciaKm(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude) / 1000;
  }
}
