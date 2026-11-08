import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cubits/base/lista_state.dart';
import '../../cubits/clinica_cubit.dart';
import '../widgets/estados.dart';
import 'mapa_base.dart';

/// Mostra todas as clínicas com localização no mapa, junto com a posição do usuário.
class ClinicaMapaPage extends StatelessWidget {
  const ClinicaMapaPage({super.key});

  Future<void> _abrirRota(BuildContext context, ClinicaItem item) async {
    final c = item.clinica;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${c.latitude},${c.longitude}',
    );
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && context.mounted) {
      mostrarMensagem(context, 'Não foi possível abrir o aplicativo de mapas.', erro: true);
    }
  }

  void _mostrarDetalhes(BuildContext context, ClinicaItem item) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.clinica.nome, style: Theme.of(sheetContext).textTheme.titleLarge),
            if (item.clinica.endereco != null) Text(item.clinica.endereco!),
            if (item.clinica.telefone != null) Text(item.clinica.telefone!),
            if (item.distanciaKm != null) Text('${item.distanciaKm!.toStringAsFixed(1)} km de você'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _abrirRota(context, item);
              },
              icon: const Icon(Icons.directions),
              label: const Text('Como chegar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clínicas no mapa')),
      body: BlocBuilder<ClinicaCubit, ListaState<ClinicaItem>>(
        builder: (context, state) {
          final cubit = context.read<ClinicaCubit>();
          final itens = state is ListaLoaded<ClinicaItem>
              ? state.itens.where((i) => i.clinica.temLocalizacao).toList()
              : <ClinicaItem>[];
          final usuario = cubit.posicaoUsuario;

          final centro = usuario ??
              (itens.isNotEmpty
                  ? LatLng(itens.first.clinica.latitude!, itens.first.clinica.longitude!)
                  : centroPadrao);

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: (usuario != null || itens.isNotEmpty) ? 13 : 4,
                ),
                children: [
                  camadaOpenStreetMap(),
                  MarkerLayer(markers: [
                    for (final item in itens)
                      Marker(
                        point: LatLng(item.clinica.latitude!, item.clinica.longitude!),
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => _mostrarDetalhes(context, item),
                          child: const Icon(Icons.location_on, size: 44, color: Colors.red),
                        ),
                      ),
                    if (usuario != null)
                      Marker(
                        point: usuario,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
              if (itens.isEmpty)
                const Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nenhuma clínica com localização marcada ainda.'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
