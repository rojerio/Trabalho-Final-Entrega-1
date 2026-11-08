import 'package:flutter/material.dart';
import '../../models/sync_status.dart';

/// Campo que abre o calendário (e, se [comHora], o relógio).
class CampoData extends StatelessWidget {
  final String rotulo;
  final DateTime? valor;
  final bool comHora;
  final bool permitirLimpar;
  final DateTime? primeiraData;
  final DateTime? ultimaData;
  final ValueChanged<DateTime?> aoAlterar;

  const CampoData({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.aoAlterar,
    this.comHora = false,
    this.permitirLimpar = false,
    this.primeiraData,
    this.ultimaData,
  });

  Future<void> _escolher(BuildContext context) async {
    final agora = DateTime.now();
    final primeira = primeiraData ?? DateTime(1990);
    final ultima = ultimaData ?? DateTime(agora.year + 5);
    var inicial = valor ?? agora;
    if (inicial.isBefore(primeira)) inicial = primeira;
    if (inicial.isAfter(ultima)) inicial = ultima;

    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeira,
      lastDate: ultima,
    );
    if (data == null) return;

    if (!comHora) {
      aoAlterar(data);
      return;
    }
    if (!context.mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(valor ?? agora),
    );
    final h = hora ?? const TimeOfDay(hour: 9, minute: 0);
    aoAlterar(DateTime(data.year, data.month, data.day, h.hour, h.minute));
  }

  @override
  Widget build(BuildContext context) {
    final texto = valor == null ? 'Não informada' : (comHora ? formatarDataHora(valor) : formatarData(valor));
    return InkWell(
      onTap: () => _escolher(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(comHora ? Icons.event_outlined : Icons.calendar_today_outlined),
          suffixIcon: (permitirLimpar && valor != null)
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => aoAlterar(null))
              : null,
        ),
        child: Text(texto),
      ),
    );
  }
}
