import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/lista_state.dart';
import '../../cubits/clinica_cubit.dart';
import '../../cubits/consulta_cubit.dart';
import '../../models/consulta.dart';
import '../../models/sync_status.dart';
import '../widgets/estados.dart';
import '../widgets/foto.dart';
import 'consulta_form_page.dart';

/// Aba de consultas na tela de detalhe do pet.
class ConsultaLista extends StatelessWidget {
  const ConsultaLista({super.key});

  void _abrir(BuildContext context, {Consulta? consulta}) {
    final cubit = context.read<ConsultaCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: cubit, child: ConsultaFormPage(consulta: consulta)),
    ));
  }

  Future<void> _excluir(BuildContext context, Consulta consulta) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Remover consulta?',
      mensagem: 'A consulta de ${formatarData(consulta.dataHora)} (${consulta.motivo}) será removida.',
    );
    if (!confirmou || !context.mounted) return;
    await context.read<ConsultaCubit>().excluir(consulta);
    if (context.mounted) mostrarMensagem(context, 'Consulta removida.');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConsultaCubit>();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: BlocBuilder<ConsultaCubit, ListaState<Consulta>>(
            builder: (context, _) => Row(
              children: [
                for (final (periodo, rotulo) in const [
                  (PeriodoConsulta.todas, 'Todas'),
                  (PeriodoConsulta.ultimos30Dias, 'Últimos 30 dias'),
                  (PeriodoConsulta.ultimoAno, 'Último ano'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(rotulo),
                      selected: cubit.periodo == periodo,
                      onSelected: (_) => cubit.alterarPeriodo(periodo),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ConsultaCubit, ListaState<Consulta>>(
            builder: (context, state) {
              return switch (state) {
                ListaInitial<Consulta>() || ListaLoading<Consulta>() => const EstadoCarregando(),
                ListaEmpty<Consulta>() => const EstadoVazio(
                    icone: Icons.medical_services_outlined,
                    mensagem: 'Nenhuma consulta registrada neste período.',
                  ),
                ListaError<Consulta>(:final mensagem) => EstadoErro(
                    mensagem: mensagem,
                    aoTentarNovamente: () => cubit.carregar(),
                  ),
                ListaLoaded<Consulta>(:final itens) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final consulta = itens[index];
                      final clinica = context.read<ClinicaCubit>().nomeDaClinica(consulta.clinicaId);
                      return Card(
                        child: ListTile(
                          leading: (consulta.fotoLocal != null || consulta.fotoUrl != null)
                              ? FotoView(
                                  fotoLocal: consulta.fotoLocal,
                                  fotoUrl: consulta.fotoUrl,
                                  tamanho: 48,
                                  circular: false,
                                  iconeVazio: Icons.receipt_long,
                                )
                              : const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
                          title: Text(consulta.motivo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text([
                            formatarDataHora(consulta.dataHora),
                            clinica,
                            if (consulta.diagnostico != null) consulta.diagnostico!,
                          ].join('\n')),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (consulta.syncStatus != SyncStatus.synced)
                                const Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 20),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _excluir(context, consulta),
                              ),
                            ],
                          ),
                          onTap: () => _abrir(context, consulta: consulta),
                        ),
                      );
                    },
                  ),
              };
            },
          ),
        ),
      ],
    );
  }
}
