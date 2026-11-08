import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/base/formulario_cubit.dart';
import '../../cubits/clinica_cubit.dart';
import '../../cubits/consulta_cubit.dart';
import '../../models/consulta.dart';
import '../clinicas/clinica_form_page.dart';
import '../widgets/campo_data.dart';
import '../widgets/estados.dart';
import '../widgets/foto.dart';

/// Precisa de um ConsultaCubit acima (BlocProvider.value).
class ConsultaFormPage extends StatelessWidget {
  final Consulta? consulta;
  const ConsultaFormPage({super.key, this.consulta});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => FormularioCubit(), child: _ConsultaForm(consulta: consulta));
  }
}

class _ConsultaForm extends StatefulWidget {
  final Consulta? consulta;
  const _ConsultaForm({this.consulta});

  @override
  State<_ConsultaForm> createState() => _ConsultaFormState();
}

class _ConsultaFormState extends State<_ConsultaForm> {
  late final TextEditingController _motivo;
  late final TextEditingController _veterinario;
  late final TextEditingController _diagnostico;
  late final TextEditingController _prescricao;
  late final TextEditingController _valor;
  late DateTime _dataHora;
  String? _clinicaId;
  String? _novaFoto;

  @override
  void initState() {
    super.initState();
    final c = widget.consulta;
    _motivo = TextEditingController(text: c?.motivo);
    _veterinario = TextEditingController(text: c?.veterinario);
    _diagnostico = TextEditingController(text: c?.diagnostico);
    _prescricao = TextEditingController(text: c?.prescricao);
    _valor = TextEditingController(text: c?.valor?.toStringAsFixed(2).replaceAll('.', ','));
    _dataHora = c?.dataHora ?? DateTime.now();
    _clinicaId = c?.clinicaId;
  }

  @override
  void dispose() {
    _motivo.dispose();
    _veterinario.dispose();
    _diagnostico.dispose();
    _prescricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    final cubit = context.read<ConsultaCubit>();
    context.read<FormularioCubit>().salvar(
          () => cubit.salvar(
            original: widget.consulta,
            clinicaId: _clinicaId,
            dataHora: _dataHora,
            motivo: _motivo.text,
            veterinario: _veterinario.text,
            diagnostico: _diagnostico.text,
            prescricao: _prescricao.text,
            valorTexto: _valor.text,
            novaFotoLocal: _novaFoto,
          ),
          mensagem: widget.consulta == null ? 'Consulta registrada!' : 'Consulta atualizada!',
        );
  }

  @override
  Widget build(BuildContext context) {
    // Recarrega a lista de clínicas quando uma nova é cadastrada por aqui.
    final clinicas = context.watch<ClinicaCubit>().clinicas;
    final clinicaValida = clinicas.any((c) => c.id == _clinicaId) ? _clinicaId : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.consulta == null ? 'Nova consulta' : 'Editar consulta')),
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('clinica-${clinicas.length}'),
                        initialValue: clinicaValida,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Clínica *', border: OutlineInputBorder()),
                        hint: Text(clinicas.isEmpty ? 'Cadastre uma clínica' : 'Selecione'),
                        items: clinicas
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (valor) => setState(() => _clinicaId = valor),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Nova clínica',
                      icon: const Icon(Icons.add_business_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClinicaFormPage()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CampoData(
                  rotulo: 'Data e hora *',
                  valor: _dataHora,
                  comHora: true,
                  aoAlterar: (data) => setState(() => _dataHora = data ?? _dataHora),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _motivo,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Motivo *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _veterinario,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Veterinário(a)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _diagnostico,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Diagnóstico', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _prescricao,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Prescrição', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _valor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FotoSelector(
                  rotulo: 'Foto da receita ou do exame',
                  iconeVazio: Icons.receipt_long,
                  fotoLocal: _novaFoto ?? widget.consulta?.fotoLocal,
                  fotoUrl: _novaFoto == null ? widget.consulta?.fotoUrl : null,
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
