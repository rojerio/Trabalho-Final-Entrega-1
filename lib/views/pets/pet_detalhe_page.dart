import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/lista_state.dart';
import '../../cubits/consulta_cubit.dart';
import '../../cubits/pet_cubit.dart';
import '../../cubits/vacina_cubit.dart';
import '../../models/pet.dart';
import '../../models/sync_status.dart';
import '../../repositories/historico_repositories.dart';
import '../../services/eventos_dados.dart';
import '../../services/sessao_service.dart';
import '../consultas/consulta_form_page.dart';
import '../consultas/consulta_lista.dart';
import '../vacinas/vacina_form_page.dart';
import '../vacinas/vacina_lista.dart';
import '../widgets/estados.dart';
import '../widgets/foto.dart';
import 'pet_form_page.dart';

/// Detalhe do pet com o histórico de consultas e vacinas.
class PetDetalhePage extends StatelessWidget {
  final String petId;
  const PetDetalhePage({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    final sessao = context.read<SessaoService>();
    final eventos = context.read<EventosDados>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ConsultaCubit(
            petId: petId,
            repository: context.read<ConsultaRepository>(),
            sessao: sessao,
            eventos: eventos,
          )..carregar(),
        ),
        BlocProvider(
          create: (context) => VacinaCubit(
            petId: petId,
            repository: context.read<VacinaRepository>(),
            sessao: sessao,
            eventos: eventos,
          )..carregar(),
        ),
      ],
      child: BlocBuilder<PetCubit, ListaState<Pet>>(
        builder: (context, state) {
          final pet = context.read<PetCubit>().porId(petId);
          if (pet == null) {
            return Scaffold(
              appBar: AppBar(),
              body: state is ListaLoading<Pet>
                  ? const EstadoCarregando()
                  : const EstadoVazio(icone: Icons.search_off, mensagem: 'Pet não encontrado.'),
            );
          }
          return _PetDetalhe(pet: pet);
        },
      ),
    );
  }
}

class _PetDetalhe extends StatefulWidget {
  final Pet pet;
  const _PetDetalhe({required this.pet});

  @override
  State<_PetDetalhe> createState() => _PetDetalheState();
}

class _PetDetalheState extends State<_PetDetalhe> with SingleTickerProviderStateMixin {
  late final TabController _abas;

  @override
  void initState() {
    super.initState();
    _abas = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  Future<void> _excluir() async {
    final pet = widget.pet;
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Remover ${pet.nome}?',
      mensagem: 'Todas as consultas e vacinas deste pet também serão removidas.',
    );
    if (!confirmou || !mounted) return;
    final navigator = Navigator.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    await context.read<PetCubit>().excluir(pet);
    navigator.pop();
    mensageiro.showSnackBar(SnackBar(content: Text('${pet.nome} foi removido.')));
  }

  void _novoRegistro() {
    if (_abas.index == 0) {
      final cubit = context.read<ConsultaCubit>();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: const ConsultaFormPage()),
      ));
    } else {
      final cubit = context.read<VacinaCubit>();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: const VacinaFormPage()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.nome),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PetFormPage(pet: pet)),
            ),
          ),
          IconButton(
            tooltip: 'Remover',
            icon: const Icon(Icons.delete_outline),
            onPressed: _excluir,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoRegistro,
        icon: const Icon(Icons.add),
        label: Text(_abas.index == 0 ? 'Nova consulta' : 'Nova vacina'),
      ),
      body: Column(
        children: [
          _Cabecalho(pet: pet),
          TabBar(
            controller: _abas,
            tabs: const [
              Tab(icon: Icon(Icons.medical_services_outlined), text: 'Consultas'),
              Tab(icon: Icon(Icons.vaccines_outlined), text: 'Vacinas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _abas,
              children: const [ConsultaLista(), VacinaLista()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final Pet pet;
  const _Cabecalho({required this.pet});

  @override
  Widget build(BuildContext context) {
    final linhas = <String>[
      [pet.especie, if (pet.raca != null) pet.raca!].join(' · '),
      '${pet.sexo == 'F' ? 'Fêmea' : 'Macho'} · ${pet.idade}${pet.pesoKg != null ? ' · ${pet.pesoKg!.toStringAsFixed(1)} kg' : ''}',
      if (pet.dataNascimento != null) 'Nascimento: ${formatarData(pet.dataNascimento)}',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FotoView(fotoLocal: pet.fotoLocal, fotoUrl: pet.fotoUrl, tamanho: 88),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.nome, style: Theme.of(context).textTheme.titleLarge),
                for (final linha in linhas) Text(linha, style: const TextStyle(color: Colors.grey)),
                if (pet.observacoes != null) ...[
                  const SizedBox(height: 4),
                  Text(pet.observacoes!, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
