import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/formulario_cubit.dart';
import '../../cubits/pet_cubit.dart';
import '../../models/pet.dart';
import '../widgets/campo_data.dart';
import '../widgets/estados.dart';
import '../widgets/foto.dart';

class PetFormPage extends StatelessWidget {
  final Pet? pet;
  const PetFormPage({super.key, this.pet});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FormularioCubit(),
      child: _PetForm(pet: pet),
    );
  }
}

class _PetForm extends StatefulWidget {
  final Pet? pet;
  const _PetForm({this.pet});

  @override
  State<_PetForm> createState() => _PetFormState();
}

class _PetFormState extends State<_PetForm> {
  static const List<String> _especies = ['Cachorro', 'Gato', 'Pássaro', 'Roedor', 'Réptil', 'Outro'];

  late final TextEditingController _nome;
  late final TextEditingController _raca;
  late final TextEditingController _peso;
  late final TextEditingController _observacoes;
  late String _especie;
  late String _sexo;
  DateTime? _dataNascimento;
  String? _novaFoto;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _nome = TextEditingController(text: pet?.nome);
    _raca = TextEditingController(text: pet?.raca);
    _peso = TextEditingController(text: pet?.pesoKg?.toString().replaceAll('.', ','));
    _observacoes = TextEditingController(text: pet?.observacoes);
    _especie = pet?.especie ?? _especies.first;
    if (!_especies.contains(_especie)) _especie = 'Outro';
    _sexo = pet?.sexo ?? 'M';
    _dataNascimento = pet?.dataNascimento;
  }

  @override
  void dispose() {
    _nome.dispose();
    _raca.dispose();
    _peso.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _salvar() {
    final petCubit = context.read<PetCubit>();
    context.read<FormularioCubit>().salvar(
          () => petCubit.salvar(
            original: widget.pet,
            nome: _nome.text,
            especie: _especie,
            raca: _raca.text,
            sexo: _sexo,
            dataNascimento: _dataNascimento,
            pesoTexto: _peso.text,
            observacoes: _observacoes.text,
            novaFotoLocal: _novaFoto,
          ),
          mensagem: widget.pet == null ? 'Pet cadastrado!' : 'Pet atualizado!',
        );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.pet != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar pet' : 'Novo pet')),
      body: BlocConsumer<FormularioCubit, FormularioState>(
        listener: (context, state) {
          if (state is FormularioSaved) {
            mostrarMensagem(context, state.mensagem);
            Navigator.of(context).pop();
          } else if (state is FormularioError) {
            mostrarMensagem(context, state.mensagem, erro: true);
          }
        },
        builder: (context, state) {
          final salvando = state is FormularioSaving;
          return AbsorbPointer(
            absorbing: salvando,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FotoSelector(
                  rotulo: 'Foto do pet',
                  iconeVazio: Icons.pets,
                  fotoLocal: _novaFoto ?? widget.pet?.fotoLocal,
                  fotoUrl: _novaFoto == null ? widget.pet?.fotoUrl : null,
                  aoSelecionar: (caminho) => setState(() => _novaFoto = caminho),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _especie,
                  decoration: const InputDecoration(labelText: 'Espécie *', border: OutlineInputBorder()),
                  items: _especies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (valor) => setState(() => _especie = valor ?? _especie),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _raca,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Raça', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'M', label: Text('Macho'), icon: Icon(Icons.male)),
                    ButtonSegment(value: 'F', label: Text('Fêmea'), icon: Icon(Icons.female)),
                  ],
                  selected: {_sexo},
                  onSelectionChanged: (valores) => setState(() => _sexo = valores.first),
                ),
                const SizedBox(height: 16),
                CampoData(
                  rotulo: 'Data de nascimento',
                  valor: _dataNascimento,
                  permitirLimpar: true,
                  ultimaData: DateTime.now(),
                  aoAlterar: (data) => setState(() => _dataNascimento = data),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _peso,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso',
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _observacoes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações (alergias, temperamento...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: salvando ? null : _salvar,
                  icon: salvando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(salvando ? 'Salvando...' : 'Salvar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
