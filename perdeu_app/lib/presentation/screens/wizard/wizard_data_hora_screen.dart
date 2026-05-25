import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/requerimento_draft.dart';
import 'widgets/wizard_progress.dart';

class WizardDataHoraScreen extends StatefulWidget {
  const WizardDataHoraScreen({super.key});

  @override
  State<WizardDataHoraScreen> createState() => _WizardDataHoraScreenState();
}

class _WizardDataHoraScreenState extends State<WizardDataHoraScreen> {
  static const Color _orange = Color(0xFFFF6600);

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;
  String? _erro;

  RequerimentoDraft _draftFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is RequerimentoDraft) {
      return args;
    }

    return RequerimentoDraft();
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? agora,
      firstDate: DateTime(2020),
      lastDate: agora,
      helpText: 'Selecione a data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
        _erro = null;
      });
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (hora != null) {
      setState(() {
        _horaSelecionada = hora;
        _erro = null;
      });
    }
  }

  void _continuar() {
    if (_dataSelecionada == null || _horaSelecionada == null) {
      setState(() {
        _erro = 'Selecione a data e o horário do acontecimento.';
      });
      return;
    }

    final dataHora = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horaSelecionada!.hour,
      _horaSelecionada!.minute,
    );

    if (dataHora.isAfter(DateTime.now())) {
      setState(() {
        _erro = 'A data e hora não podem estar no futuro.';
      });
      return;
    }

    final draft = _draftFromArgs(context).copyWith(
      dataHoraOcorrencia: dataHora,
    );

    Navigator.pushNamed(
      context,
      AppRoutes.wizardDetalhes,
      arguments: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = _dataSelecionada == null
        ? 'Nenhuma data selecionada'
        : DateFormat('dd/MM/yyyy').format(_dataSelecionada!);

    final horaFormatada = _horaSelecionada == null
        ? 'Nenhum horário selecionado'
        : _horaSelecionada!.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        title: const Text('Novo Requerimento'),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _continuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const WizardProgress(
              currentStep: 4,
              totalSteps: 6,
            ),
            const SizedBox(height: 24),
            const Text(
              'Quando aconteceu?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informe a data e o horário aproximado da ocorrência.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            _DateTimeCard(
              title: 'Selecionar Data',
              value: dataFormatada,
              icon: Icons.calendar_today_rounded,
              onTap: _selecionarData,
            ),
            const SizedBox(height: 14),
            _DateTimeCard(
              title: 'Selecionar Horário',
              value: horaFormatada,
              icon: Icons.access_time_rounded,
              onTap: _selecionarHora,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 14),
              Text(
                _erro!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  const _DateTimeCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _orange = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE6E0DB),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: _orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}