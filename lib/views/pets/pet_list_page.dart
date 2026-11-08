import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/base/lista_state.dart';
import '../../cubits/pet_cubit.dart';
import '../../models/pet.dart';
import '../../models/sync_status.dart';
import '../widgets/estados.dart';
import '../widgets/foto.dart';
import '../widgets/sync_indicator.dart';
import 'pet_detalhe_page.dart';
import 'pet_form_page.dart';

class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

  void _abrirFormulario(BuildContext context, {Pet? pet}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetFormPage(pet: pet)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus pets'),
        actions: [
          const SyncIndicator(),
          PopupMenuButton<String>(
            onSelected: (opcao) {
              if (opcao == 'sair') context.read<AuthCubit>().logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sair', child: Text('Sair')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo pet'),
      ),
      body: BlocBuilder<PetCubit, ListaState<Pet>>(
        builder: (context, state) {
          return switch (state) {
            ListaInitial<Pet>() || ListaLoading<Pet>() => const EstadoCarregando(),
            ListaEmpty<Pet>() => EstadoVazio(
                icone: Icons.pets,
                mensagem: 'Você ainda não cadastrou nenhum pet.',
                textoBotao: 'Cadastrar primeiro pet',
                aoPressionar: () => _abrirFormulario(context),
              ),
            ListaError<Pet>(:final mensagem) => EstadoErro(
                mensagem: mensagem,
                aoTentarNovamente: () => context.read<PetCubit>().carregar(),
              ),
            ListaLoaded<Pet>(:final itens) => RefreshIndicator(
                onRefresh: () => context.read<PetCubit>().carregar(silencioso: true),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: itens.length,
                  itemBuilder: (context, index) => _PetCard(pet: itens[index]),
                ),
              ),
          };
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final detalhes = [pet.especie, if (pet.raca != null) pet.raca!, pet.idade].join(' · ');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: FotoView(fotoLocal: pet.fotoLocal, fotoUrl: pet.fotoUrl),
        title: Text(pet.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(detalhes),
        trailing: pet.syncStatus == SyncStatus.synced
            ? const Icon(Icons.chevron_right)
            : const Tooltip(
                message: 'Aguardando sincronização',
                child: Icon(Icons.cloud_upload_outlined, color: Colors.orange),
              ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PetDetalhePage(petId: pet.id)),
        ),
      ),
    );
  }
}
