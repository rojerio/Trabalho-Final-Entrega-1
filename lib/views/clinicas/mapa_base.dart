import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Camada de mapa do OpenStreetMap (gratuita, sem chave de API).
TileLayer camadaOpenStreetMap() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.edu.petcare',
    );

/// Centro usado quando não há nenhuma posição conhecida (Brasília).
const LatLng centroPadrao = LatLng(-15.7939, -47.8828);
