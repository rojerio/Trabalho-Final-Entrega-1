import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/localizacao_service.dart';
import '../widgets/estados.dart';
import 'mapa_base.dart';

/// Toque no mapa para marcar onde fica a clínica. Devolve um LatLng.
class SeletorLocalPage extends StatefulWidget {
  final LatLng? posicaoInicial;
  const SeletorLocalPage({super.key, this.posicaoInicial});

  @override
  State<SeletorLocalPage> createState() => _SeletorLocalPageState();
}

class _SeletorLocalPageState extends State<SeletorLocalPage> {
  final MapController _mapa = MapController();
  LatLng? _selecionada;

  @override
  void initState() {
    super.initState();
    _selecionada = widget.posicaoInicial;
  }

  Future<void> _centralizarNoUsuario() async {
    try {
      final posicao = await context.read<LocalizacaoService>().posicaoAtual();
      if (!mounted) return;
      _mapa.move(posicao, 16);
      setState(() => _selecionada ??= posicao);
    } catch (e) {
      if (mounted) mostrarMensagem(context, e.toString().replaceFirst('Exception: ', ''), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toque para marcar a clínica')),
      body: FlutterMap(
        mapController: _mapa,
        options: MapOptions(
          initialCenter: widget.posicaoInicial ?? centroPadrao,
          initialZoom: widget.posicaoInicial != null ? 16 : 4,
          onTap: (_, ponto) => setState(() => _selecionada = ponto),
          onMapReady: () {
            if (widget.posicaoInicial == null) _centralizarNoUsuario();
          },
        ),
        children: [
          camadaOpenStreetMap(),
          if (_selecionada != null)
            MarkerLayer(markers: [
              Marker(
                point: _selecionada!,
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on, size: 48, color: Colors.red),
              ),
            ]),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'gps',
            tooltip: 'Minha localização',
            onPressed: _centralizarNoUsuario,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'confirmar',
            onPressed: _selecionada == null ? null : () => Navigator.of(context).pop(_selecionada),
            icon: const Icon(Icons.check),
            label: const Text('Usar este local'),
          ),
        ],
      ),
    );
  }
}
