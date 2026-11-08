import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/lista_cubit.dart';
import '../../cubits/base/lista_state.dart';
import '../../cubits/clinica_cubit.dart';
import '../../models/clinica.dart';
import '../../models/sync_status.dart';
import '../widgets/estados.dart';
import '../widgets/sync_indicator.dart';
import 'clinica_form_page.dart';
import 'clinica_mapa_page.dart';

class ClinicaListPage extends StatelessWidget {
  const ClinicaListPage({super.key});

  void _abrirFormulario(BuildContext context, {Clinica? clinica}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClinicaFormPage(clinica: clinica)));
  }

  Future<void> _excluir(BuildContext context, Clinica clinica) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Remover ${clinica.nome}?',
      mensagem: 'A clínica será removida da sua lista.',
    );
    if (!confirmou || !context.mounted) return;
    try {
      await context.read<ClinicaCubit>().excluir(clinica);
      if (context.mounted) mostrarMensagem(context, 'Clínica removida.');
    } on ValidacaoException catch (e) {
      if (context.mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clínicas'),
        actions: [
          IconButton(
            tooltip: 'Ver no mapa',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClinicaMapaPage()),
            ),
          ),
          const SyncIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nova clínica'),
      ),
      body: BlocBuilder<ClinicaCubit, ListaState<ClinicaItem>>(
        builder: (context, state) {
          final cubit = context.read<ClinicaCubit>();
          return switch (state) {
            ListaInitial<ClinicaItem>() || ListaLoading<ClinicaItem>() => const EstadoCarregando(),
            ListaEmpty<ClinicaItem>() => EstadoVazio(
                icone: Icons.local_hospital_outlined,
                mensagem: 'Cadastre as clínicas veterinárias que você frequenta.',
                textoBotao: 'Cadastrar clínica',
                aoPressionar: () => _abrirFormulario(context),
              ),
            ListaError<ClinicaItem>(:final mensagem) => EstadoErro(
                mensagem: mensagem,
                aoTentarNovamente: () => cubit.carregar(),
              ),
            ListaLoaded<ClinicaItem>(:final itens) => RefreshIndicator(
                onRefresh: () => cubit.atualizarLocalizacao(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        cubit.posicaoUsuario == null
                            ? 'Localização indisponível: ordenado por nome.'
                            : 'Ordenado pela distância até você. Puxe para atualizar.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    for (final item in itens)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
                          title: Text(item.clinica.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text([
                            if (item.clinica.endereco != null) item.clinica.endereco!,
                            if (item.clinica.telefone != null) item.clinica.telefone!,
                          ].join('\n')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.distanciaKm != null)
                                Text(
                                  item.distanciaKm! < 1
                                      ? '${(item.distanciaKm! * 1000).round()} m'
                                      : '${item.distanciaKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              if (item.clinica.syncStatus != SyncStatus.synced)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 20),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _excluir(context, item.clinica),
                              ),
                            ],
                          ),
                          onTap: () => _abrirFormulario(context, clinica: item.clinica),
                        ),
                      ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
