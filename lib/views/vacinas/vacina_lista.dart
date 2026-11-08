import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/lista_state.dart';
import '../../cubits/clinica_cubit.dart';
import '../../cubits/vacina_cubit.dart';
import '../../models/sync_status.dart';
import '../../models/vacina.dart';
import '../widgets/estados.dart';
import 'vacina_form_page.dart';

/// Aba de vacinas na tela de detalhe do pet.
/// Doses atrasadas e próximas aparecem primeiro, com destaque.
class VacinaLista extends StatelessWidget {
  const VacinaLista({super.key});

  void _abrir(BuildContext context, {Vacina? vacina}) {
    final cubit = context.read<VacinaCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: cubit, child: VacinaFormPage(vacina: vacina)),
    ));
  }

  Future<void> _excluir(BuildContext context, Vacina vacina) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Remover vacina?',
      mensagem: 'O registro da vacina ${vacina.nome} de ${formatarData(vacina.dataAplicacao)} será removido.',
    );
    if (!confirmou || !context.mounted) return;
    await context.read<VacinaCubit>().excluir(vacina);
    if (context.mounted) mostrarMensagem(context, 'Vacina removida.');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VacinaCubit, ListaState<Vacina>>(
      builder: (context, state) {
        return switch (state) {
          ListaInitial<Vacina>() || ListaLoading<Vacina>() => const EstadoCarregando(),
          ListaEmpty<Vacina>() => const EstadoVazio(
              icone: Icons.vaccines_outlined,
              mensagem: 'Nenhuma vacina registrada.',
            ),
          ListaError<Vacina>(:final mensagem) => EstadoErro(
              mensagem: mensagem,
              aoTentarNovamente: () => context.read<VacinaCubit>().carregar(),
            ),
          ListaLoaded<Vacina>(:final itens) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final vacina = itens[index];
                final (cor, rotulo) = switch (vacina.situacao) {
                  SituacaoVacina.atrasada => (Colors.red, 'Atrasada'),
                  SituacaoVacina.proxima => (Colors.orange, 'Próxima'),
                  SituacaoVacina.emDia => (Colors.green, 'Em dia'),
                  SituacaoVacina.semReforco => (Colors.grey, 'Dose única'),
                };
                final clinica = context.read<ClinicaCubit>().nomeDaClinica(vacina.clinicaId);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: vacina.situacao == SituacaoVacina.atrasada
                        ? const BorderSide(color: Colors.red, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cor.withValues(alpha: 0.15),
                      child: Icon(Icons.vaccines, color: cor),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(vacina.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Chip(
                          label: Text(rotulo, style: TextStyle(color: cor, fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: cor),
                        ),
                      ],
                    ),
                    subtitle: Text([
                      'Aplicada em ${formatarData(vacina.dataAplicacao)} · $clinica',
                      if (vacina.proximaDose != null) 'Próxima dose: ${formatarData(vacina.proximaDose)}',
                    ].join('\n')),
                    isThreeLine: vacina.proximaDose != null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vacina.syncStatus != SyncStatus.synced)
                          const Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 20),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _excluir(context, vacina),
                        ),
                      ],
                    ),
                    onTap: () => _abrir(context, vacina: vacina),
                  ),
                );
              },
            ),
        };
      },
    );
  }
}
