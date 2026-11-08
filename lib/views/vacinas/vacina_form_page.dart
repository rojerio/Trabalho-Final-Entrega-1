import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/formulario_cubit.dart';
import '../../cubits/clinica_cubit.dart';
import '../../cubits/vacina_cubit.dart';
import '../../models/vacina.dart';
import '../widgets/campo_data.dart';
import '../widgets/estados.dart';
import '../widgets/foto.dart';

/// Precisa de um VacinaCubit acima (BlocProvider.value).
class VacinaFormPage extends StatelessWidget {
  final Vacina? vacina;
  const VacinaFormPage({super.key, this.vacina});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => FormularioCubit(), child: _VacinaForm(vacina: vacina));
  }
}

class _VacinaForm extends StatefulWidget {
  final Vacina? vacina;
  const _VacinaForm({this.vacina});

  @override
  State<_VacinaForm> createState() => _VacinaFormState();
}

class _VacinaFormState extends State<_VacinaForm> {
  static const List<String> _sugestoes = ['V8', 'V10', 'Antirrábica', 'Gripe canina', 'Giárdia', 'V4 felina', 'V5 felina'];

  late final TextEditingController _nome;
  late final TextEditingController _lote;
  late DateTime _dataAplicacao;
  DateTime? _proximaDose;
  String? _clinicaId;
  String? _novaFoto;

  @override
  void initState() {
    super.initState();
    final v = widget.vacina;
    _nome = TextEditingController(text: v?.nome);
    _lote = TextEditingController(text: v?.lote);
    _dataAplicacao = v?.dataAplicacao ?? DateTime.now();
    _proximaDose = v?.proximaDose;
    _clinicaId = v?.clinicaId;
  }

  @override
  void dispose() {
    _nome.dispose();
    _lote.dispose();
    super.dispose();
  }

  void _salvar() {
    final cubit = context.read<VacinaCubit>();
    context.read<FormularioCubit>().salvar(
          () => cubit.salvar(
            original: widget.vacina,
            nome: _nome.text,
            lote: _lote.text,
            clinicaId: _clinicaId,
            dataAplicacao: _dataAplicacao,
            proximaDose: _proximaDose,
            novaFotoLocal: _novaFoto,
          ),
          mensagem: widget.vacina == null ? 'Vacina registrada!' : 'Vacina atualizada!',
        );
  }

  /// Atalho: próxima dose em 1 ano (reforço anual).
  void _reforcoAnual() {
    setState(() => _proximaDose = DateTime(_dataAplicacao.year + 1, _dataAplicacao.month, _dataAplicacao.day));
  }

  @override
  Widget build(BuildContext context) {
    final clinicas = context.watch<ClinicaCubit>().clinicas;
    final clinicaValida = clinicas.any((c) => c.id == _clinicaId) ? _clinicaId : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.vacina == null ? 'Nova vacina' : 'Editar vacina')),
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
                  decoration: const InputDecoration(labelText: 'Vacina *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _sugestoes
                      .map((s) => ActionChip(
                            label: Text(s),
                            onPressed: () => setState(() => _nome.text = s),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lote,
                  decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  key: ValueKey('clinica-${clinicas.length}'),
                  initialValue: clinicaValida,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Clínica (opcional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Sem clínica (campanha, em casa...)')),
                    ...clinicas.map((c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.nome, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (valor) => setState(() => _clinicaId = valor),
                ),
                const SizedBox(height: 16),
                CampoData(
                  rotulo: 'Data de aplicação *',
                  valor: _dataAplicacao,
                  ultimaData: DateTime.now(),
                  aoAlterar: (data) => setState(() => _dataAplicacao = data ?? _dataAplicacao),
                ),
                const SizedBox(height: 16),
                CampoData(
                  rotulo: 'Próxima dose',
                  valor: _proximaDose,
                  permitirLimpar: true,
                  primeiraData: _dataAplicacao,
                  ultimaData: DateTime(DateTime.now().year + 5),
                  aoAlterar: (data) => setState(() => _proximaDose = data),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _reforcoAnual,
                    icon: const Icon(Icons.event_repeat),
                    label: const Text('Reforço em 1 ano'),
                  ),
                ),
                const SizedBox(height: 12),
                FotoSelector(
                  rotulo: 'Foto da carteirinha',
                  iconeVazio: Icons.badge_outlined,
                  fotoLocal: _novaFoto ?? widget.vacina?.fotoLocal,
                  fotoUrl: _novaFoto == null ? widget.vacina?.fotoUrl : null,
                  aoSelecionar: (caminho) => setState(() => _novaFoto = caminho),
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
