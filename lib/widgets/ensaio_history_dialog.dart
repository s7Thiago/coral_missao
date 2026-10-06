import 'package:flutter/material.dart';
import '../viewmodels/admin_panel_viewmodel.dart';

/// Diálogo/Modal desacoplado para visualizar, selecionar e resetar chamadas de ensaios anteriores.
class EnsaioHistoryDialog extends StatelessWidget {
  final AdminPanelViewModel viewModel;

  const EnsaioHistoryDialog({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, {required AdminPanelViewModel viewModel}) {
    return showDialog(
      context: context,
      builder: (_) => EnsaioHistoryDialog(viewModel: viewModel),
    );
  }

  Future<void> _confirmarReset(BuildContext context, String dataIso) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Resetar Chamada'),
          ],
        ),
        content: Text(
          'Deseja zerar todos os registros de presença e falta do ensaio do dia ${_formatData(dataIso)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Resetar Chamada'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await viewModel.resetarEnsaioAtual(dataIso);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chamada do dia ${_formatData(dataIso)} foi resetada com sucesso!')),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, String idEnsaio, String dataIso) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Ensaio'),
          ],
        ),
        content: Text(
          'Deseja excluir permanentemente o registro de ensaio sem presenças do dia ${_formatData(dataIso)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await viewModel.excluirEnsaio(idEnsaio);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ensaio do dia ${_formatData(dataIso)} foi excluído.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final ensaios = viewModel.todosEnsaios;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF16476B)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Histórico de Ensaios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF16476B)),
                tooltip: 'Novo Ensaio',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    await viewModel.selecionarDataEnsaio(picked);
                    navigator.pop();
                  }
                },
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione um ensaio para carregar ou resetar a gravação de presenças:',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (ensaios.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'Nenhum ensaio anterior registrado.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: ensaios.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ensaio = ensaios[index];
                        final isAtual = ensaio.dataEnsaio == viewModel.dataEnsaioFormatada;
                        final isSemRegistros = ensaio.membrosPresentes.isEmpty && ensaio.membrosFaltantes.isEmpty;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isAtual ? const Color(0xFF16476B).withValues(alpha: 0.08) : null,
                          leading: Icon(
                            isAtual ? Icons.event_available_rounded : Icons.event_note_rounded,
                            color: isAtual ? const Color(0xFF16476B) : Colors.grey,
                          ),
                          title: Text(
                            _formatData(ensaio.dataEnsaio),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isAtual ? FontWeight.bold : FontWeight.w600,
                              color: isAtual ? const Color(0xFF16476B) : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${ensaio.membrosPresentes.length} Presentes | ${ensaio.membrosFaltantes.length} Faltas',
                            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSemRegistros)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                  tooltip: 'Excluir ensaio sem registros',
                                  onPressed: () => _confirmarExclusao(context, ensaio.idEnsaio, ensaio.dataEnsaio),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.restart_alt_rounded, size: 20, color: Colors.orange),
                                  tooltip: 'Resetar Chamada deste dia',
                                  onPressed: () => _confirmarReset(context, ensaio.dataEnsaio),
                                ),
                              if (isAtual)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16476B),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Atual',
                                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                const Icon(Icons.chevron_right_rounded, size: 20),
                            ],
                          ),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            try {
                              final parts = ensaio.dataEnsaio.split('-');
                              if (parts.length == 3) {
                                final dt = DateTime(
                                  int.parse(parts[0]),
                                  int.parse(parts[1]),
                                  int.parse(parts[2]),
                                );
                                await viewModel.selecionarDataEnsaio(dt);
                              }
                            } catch (_) {}
                            navigator.pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  static const List<String> _diasDaSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  String _formatData(String isoStr) {
    try {
      final parts = isoStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final dt = DateTime(year, month, day);
        final diaSemana = _diasDaSemana[dt.weekday - 1];
        final diaFormatted = day.toString().padLeft(2, '0');
        final mesFormatted = month.toString().padLeft(2, '0');
        return '$diaFormatted/$mesFormatted/$year ($diaSemana)';
      }
    } catch (_) {}
    return isoStr;
  }
}
