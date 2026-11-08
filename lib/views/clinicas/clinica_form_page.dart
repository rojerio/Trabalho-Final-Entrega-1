import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../cubits/base/formulario_cubit.dart';
import '../../cubits/clinica_cubit.dart';
import '../../models/clinica.dart';
import '../../services/localizacao_service.dart';
import '../widgets/estados.dart';
import 'seletor_local_page.dart';

class ClinicaFormPage extends StatelessWidget {
  final Clinica? clinica;
  const ClinicaFormPage({super.key, this.clinica});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => FormularioCubit(), child: _ClinicaForm(clinica: clinica));
  }
}

class _ClinicaForm extends StatefulWidget {
  final Clinica? clinica;
  const _ClinicaForm({this.clinica});

  @override
  State<_ClinicaForm> createState() => _ClinicaFormState();
}

class _ClinicaFormState extends State<_ClinicaForm> {
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _endereco;
  LatLng? _posicao;
  bool _buscandoGps = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clinica;
    _nome = TextEditingController(text: c?.nome);
    _telefone = TextEditingController(text: c?.telefone);
    _endereco = TextEditingController(text: c?.endereco);
    if (c != null && c.temLocalizacao) _posicao = LatLng(c.latitude!, c.longitude!);
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _endereco.dispose();
    super.dispose();
  }

  /// Recurso nativo: usa o GPS para marcar a clínica onde o usuário está.
  Future<void> _usarGps() async {
    setState(() => _buscandoGps = true);
    try {
      final posicao = await context.read<LocalizacaoService>().posicaoAtual();
      if (mounted) setState(() => _posicao = posicao);
    } catch (e) {
      if (mounted) mostrarMensagem(context, e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  Future<void> _escolherNoMapa() async {
    final escolhida = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => SeletorLocalPage(posicaoInicial: _posicao)),
    );
    if (escolhida != null) setState(() => _posicao = escolhida);
  }

  void _salvar() {
    final cubit = context.read<ClinicaCubit>();
    context.read<FormularioCubit>().salvar(
          () => cubit.salvar(
            original: widget.clinica,
            nome: _nome.text,
            telefone: _telefone.text,
            endereco: _endereco.text,
            posicao: _posicao,
          ),
          mensagem: widget.clinica == null ? 'Clínica cadastrada!' : 'Clínica atualizada!',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clinica == null ? 'Nova clínica' : 'Editar clínica')),
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
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _endereco,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Localização', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          _posicao == null
                              ? 'Nenhuma localização marcada.'
                              : 'Lat ${_posicao!.latitude.toStringAsFixed(5)}, '
                                  'Lng ${_posicao!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _buscandoGps ? null : _usarGps,
                              icon: _buscandoGps
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location),
                              label: const Text('Estou na clínica'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _escolherNoMapa,
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Escolher no mapa'),
                            ),
                            if (_posicao != null)
                              TextButton(
                                onPressed: () => setState(() => _posicao = null),
                                child: const Text('Limpar'),
                              ),
                          ],
                        ),
                      ],
                    ),
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
