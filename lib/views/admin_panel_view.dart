import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_panel_viewmodel.dart';
import '../widgets/dashboard_kpi_cards.dart';
import '../widgets/edit_membro_dialog.dart';
import '../widgets/ensaio_history_dialog.dart';
import '../widgets/frequency_card_mobile.dart';
import '../widgets/frequency_table_desktop.dart';
import '../widgets/vocal_balance_card.dart';
import '../widgets/vocal_balance_dialog.dart';

/// Tela principal do Painel Administrativo (Quadro de Frequência & Controle de Assiduidade).
/// Possui alternância dinâmica responsiva para Versão Desktop e Versão Mobile.
class AdminPanelView extends StatelessWidget {
  const AdminPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 8,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_rounded, color: Color(0xFF16476B), size: 20),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Painel da Direção',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AdminPanelViewModel>(
            builder: (context, vm, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.record_voice_over_rounded, color: Color(0xFFB45309), size: 19),
                    tooltip: 'Equilíbrio Vocal dos Naipes',
                    onPressed: () => VocalBalanceDialog.show(context, viewModel: vm),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.restart_alt_rounded, color: Colors.orange, size: 19),
                    tooltip: 'Resetar Chamada deste dia',
                    onPressed: () => _confirmarResetDia(context, vm),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => EnsaioHistoryDialog.show(context, viewModel: vm),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 17, color: Color(0xFF16476B)),
                          const SizedBox(width: 3),
                          Text(
                            _formatDataDisplay(vm.dataEnsaioFormatada),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16476B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminPanelViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.todosMembros.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF16476B)),
            );
          }

          if (vm.errorMessage != null && vm.todosMembros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    vm.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => vm.carregarDados(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24.0 : 12.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho Principal do Dashboard
                    _buildHeader(context, vm, isDesktop),
                    const SizedBox(height: 16),

                    // Barra de Filtros e Busca com Debounce
                    _buildFilterToolbar(context, vm, isDesktop),
                    const SizedBox(height: 16),

                    // Tabela Desktop ou Lista Mobile
                    if (isDesktop)
                      FrequencyTableDesktop(
                        membros: vm.membrosPaginados,
                        viewModel: vm,
                      )
                    else
                      _buildMobileList(vm),

                    const SizedBox(height: 16),

                    // Rodapé com Paginação
                    _buildPaginationFooter(context, vm),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<AdminPanelViewModel>(
        builder: (context, vm, _) {
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF16476B),
            foregroundColor: Colors.white,
            elevation: 3,
            onPressed: () => EditMembroDialog.show(
              context,
              viewModel: vm,
            ),
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text(
              'Novo Corista',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminPanelViewModel vm, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quadro de Frequência & Assiduidade',
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Acompanhamento individual nos ensaios oficiais e estatísticas dos coristas.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Componente Dashboard KPI Cards
        DashboardKpiCards(viewModel: vm, isDesktop: isDesktop),
        const SizedBox(height: 16),

        // Exibe o Card de Equilíbrio Vocal diretamente no topo quando Desktop
        if (isDesktop) ...[
          VocalBalanceCard(viewModel: vm),
          const SizedBox(height: 16),
        ],

        // Abas / Filtros Rápidos Superior (Estilo Referência)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatChip(
                label: 'Ativos (${vm.countAtivos})',
                isSelected: vm.selectedStatusFilter == 'Ativos',
                onTap: () => vm.setSelectedStatusFilter('Ativos'),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Todos (${vm.countTodos})',
                isSelected: vm.selectedStatusFilter == 'Todos',
                onTap: () => vm.setSelectedStatusFilter('Todos'),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Frequentes (>85%)',
                isSelected: vm.selectedStatusFilter == 'Frequentes (>85%)',
                onTap: () => vm.setSelectedStatusFilter('Frequentes (>85%)'),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Faltosos Críticos (${vm.countFaltososCriticos})',
                isSelected: vm.selectedStatusFilter == 'Faltosos Críticos',
                activeColor: const Color(0xFFB91C1C),
                onTap: () => vm.setSelectedStatusFilter('Faltosos Críticos'),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Licença / Inativo (${vm.countLicencaInativo})',
                isSelected: vm.selectedStatusFilter == 'Licença / Inativo',
                onTap: () => vm.setSelectedStatusFilter('Licença / Inativo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required bool isSelected,
    Color activeColor = const Color(0xFF16476B),
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, AdminPanelViewModel vm, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Campo de Busca com Debounce
          Expanded(
            child: TextField(
              onChanged: (val) => vm.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Buscar corista por nome ou naipe...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Dropdown Filtro Naipe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: vm.selectedNaipe,
                icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                onChanged: (val) {
                  if (val != null) vm.setSelectedNaipe(val);
                },
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos Naipes')),
                  DropdownMenuItem(value: 'Soprano', child: Text('Sopranos')),
                  DropdownMenuItem(value: 'Contralto', child: Text('Contraltos')),
                  DropdownMenuItem(value: 'Tenor', child: Text('Tenores')),
                  DropdownMenuItem(value: 'Baixo', child: Text('Baixos')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botão Modal Equilíbrio Vocal
          if(isDesktop)
          InkWell(
            onTap: () => VocalBalanceDialog.show(context, viewModel: vm),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.record_voice_over_rounded, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 4),
                  Text(
                    'Equilíbrio Vocal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(AdminPanelViewModel vm) {
    final membros = vm.membrosPaginados;
    if (membros.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Nenhum corista encontrado.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: membros.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return FrequencyCardMobile(
          membro: membros[index],
          viewModel: vm,
        );
      },
    );
  }

  Widget _buildPaginationFooter(BuildContext context, AdminPanelViewModel vm) {
    final filtrados = vm.membrosFiltrados;
    final total = filtrados.length;
    final start = total == 0 ? 0 : vm.currentPage * vm.pageSize + 1;
    final end = (vm.currentPage + 1) * vm.pageSize > total ? total : (vm.currentPage + 1) * vm.pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Mostrando $start a $end de $total coristas',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exibir: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: vm.pageSize,
                  isDense: true,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16476B)),
                  onChanged: (val) {
                    if (val != null) vm.setPageSize(val);
                  },
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                  ],
                ),
              ),
              const Text(
                'por página',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: vm.currentPage > 0 ? () => vm.previousPage() : null,
              ),
              Text(
                '${vm.currentPage + 1} / ${vm.totalPages}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: vm.currentPage < vm.totalPages - 1 ? () => vm.nextPage() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmarResetDia(BuildContext context, AdminPanelViewModel vm) async {
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
          'Deseja zerar todos os registros de presença e falta do ensaio do dia ${_formatDataDisplay(vm.dataEnsaioFormatada)}?',
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
      await vm.resetarEnsaioAtual();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chamada do dia ${_formatDataDisplay(vm.dataEnsaioFormatada)} foi resetada.')),
        );
      }
    }
  }

  static const List<String> _diasDaSemana = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SAB',
    'DOM',
  ];

  static String _formatDataDisplay(String isoDate) {
    try {
      final parts = isoDate.split('-');
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
    return isoDate;
  }
}
