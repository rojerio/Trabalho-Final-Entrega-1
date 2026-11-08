import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/sync_cubit.dart';

/// Ícone na barra superior que mostra o status da conexão e da sincronização.
/// Tocar nele força uma sincronização.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncCubit, SyncState>(
      listenWhen: (anterior, atual) => atual.mensagem != null && atual.mensagem != anterior.mensagem,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.mensagem!)));
      },
      builder: (context, state) {
        final (icone, dica) = switch (state.situacao) {
          SituacaoSync.offline => (Icons.cloud_off, 'Offline'),
          SituacaoSync.sincronizando => (Icons.sync, 'Sincronizando...'),
          SituacaoSync.sincronizado => (Icons.cloud_done_outlined, 'Sincronizado'),
          SituacaoSync.erro => (Icons.sync_problem, 'Erro na sincronização'),
        };

        final textoDica = state.pendentes > 0 ? '$dica · ${state.pendentes} pendente(s)' : dica;

        Widget icon = state.situacao == SituacaoSync.sincronizando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icone);

        if (state.pendentes > 0) {
          icon = Badge(label: Text('${state.pendentes}'), child: icon);
        }

        return IconButton(
          tooltip: textoDica,
          onPressed: () => context.read<SyncCubit>().sincronizar(),
          icon: icon,
        );
      },
    );
  }
}
