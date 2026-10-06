import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/membro_coral_model.dart';
import '../viewmodels/admin_panel_viewmodel.dart';
import 'edit_membro_dialog.dart';

/// Componente de Tabela de Frequência para telas Desktop / Tablets em modo paisagem.
class FrequencyTableDesktop extends StatelessWidget {
  final List<MembroCoralModel> membros;
  final AdminPanelViewModel viewModel;

  const FrequencyTableDesktop({
    super.key,
    required this.membros,
    required this.viewModel,
  });

  Color _getAvatarBg(String? naipe) {
    final n = (naipe ?? '').toLowerCase();
    if (n.contains('soprano')) return const Color(0xFFE0F2FE);
    if (n.contains('contralto')) return const Color(0xFFFEE2E2);
    if (n.contains('tenor')) return const Color(0xFFFEF3C7);
    if (n.contains('baixo')) return const Color(0xFFDCFCE7);
    return const Color(0xFFF3F4F6);
  }

  Color _getAvatarTextColor(String? naipe) {
    final n = (naipe ?? '').toLowerCase();
    if (n.contains('soprano')) return const Color(0xFF0369A1);
    if (n.contains('contralto')) return const Color(0xFFB91C1C);
    if (n.contains('tenor')) return const Color(0xFFB45309);
    if (n.contains('baixo')) return const Color(0xFF15803D);
    return const Color(0xFF4B5563);
  }

  Future<void> _abrirContato(BuildContext context, MembroCoralModel membro) async {
    final foneRaw = (membro.telefone ?? membro.telefoneEmergencia ?? '').toString();
    final foneLimpo = foneRaw.replaceAll(RegExp(r'\D'), '');

    if (foneLimpo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum número de telefone cadastrado para ${membro.nome}.')),
      );
      return;
    }

    final url = 'https://wa.me/55$foneLimpo';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o WhatsApp para o número: $foneRaw')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (membros.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Nenhum corista encontrado com os filtros aplicados.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Cabeçalho da Tabela
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: const Row(
                children: [
                  SizedBox(width: 44, child: Text('PRES.', style: _headerStyle)),
                  Expanded(flex: 3, child: Text('CORISTA & NAIPE', style: _headerStyle)),
                  Expanded(flex: 2, child: Text('STATUS GERAL', style: _headerStyle)),
                  Expanded(flex: 2, child: Center(child: Text('ÚLTIMOS 4 ENSAIOS', style: _headerStyle))),
                  Expanded(flex: 2, child: Text('ASSIDUIDADE', style: _headerStyle)),
                  SizedBox(width: 130, child: Align(alignment: Alignment.centerRight, child: Text('AÇÕES', style: _headerStyle))),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEAECF0)),

            // Linhas de Coristas
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: membros.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final membro = membros[index];
                final membroId = membro.id ?? '';
                final isPresente = viewModel.isMembroPresente(membroId);
                final isFaltante = viewModel.isMembroFaltante(membroId);

                final status = membro.statusGeralCalculado;
                final assiduidade = membro.assiduidadeCalculada;
                final ultimos4 = membro.ultimos4EnsaiosCalculados;
                final isCritico = status == 'Faltoso Crítico';

                Color rowBg = Colors.white;
                if (isPresente) {
                  rowBg = const Color(0xFFF0FDF4); // Leve destaque verde
                } else if (isFaltante) {
                  rowBg = const Color(0xFFFEF2F2); // Leve destaque vermelho
                }

                return InkWell(
                  onTap: () {
                    // Togra presença ao clicar na linha
                    if (membroId.isNotEmpty) {
                      viewModel.marcarPresenca(membroId, !isPresente);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: rowBg,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Checkbox de Presença no Ensaio
                        SizedBox(
                          width: 44,
                          child: Checkbox(
                            value: isPresente,
                            activeColor: const Color(0xFF12B76A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              if (membroId.isNotEmpty && val != null) {
                                viewModel.marcarPresenca(membroId, val);
                              }
                            },
                          ),
                        ),

                        // Corista & Naipe
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: _getAvatarBg(membro.naipeVocal),
                                child: Text(
                                  membro.initials,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getAvatarTextColor(membro.naipeVocal),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      membro.nome ?? 'Sem Nome',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      membro.naipeVocal ?? 'Naipe Não Def.',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Geral Badge
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildStatusBadge(status),
                          ),
                        ),

                        // Últimos 4 Ensaios (4 Pontos)
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ultimos4.map((tipo) {
                              if (tipo == 'P') {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF12B76A),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              } else if (tipo == 'F') {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF04438),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              } else {
                                // "N" ou sem registro: anel opaco cinza com borda delicada
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                );
                              }
                            }).toList(),
                          ),
                        ),

                        // Assiduidade %
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(assiduidade * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: assiduidade >= 0.85
                                      ? const Color(0xFF0284C7)
                                      : (assiduidade >= 0.60 ? const Color(0xFF0F172A) : const Color(0xFFDC2626)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: assiduidade,
                                    minHeight: 4,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      assiduidade >= 0.85
                                          ? const Color(0xFF0284C7)
                                          : (assiduidade >= 0.60 ? const Color(0xFF0F172A) : const Color(0xFFDC2626)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Ações (Editar Cadastro & Registrar Contato)
                        SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF16476B)),
                                tooltip: 'Editar Cadastro',
                                onPressed: () => EditMembroDialog.show(
                                  context,
                                  membro: membro,
                                  viewModel: viewModel,
                                ),
                              ),
                              if (isCritico)
                                ElevatedButton.icon(
                                  onPressed: () => _abrirContato(context, membro),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB91C1C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.phone_rounded, size: 13),
                                  label: const Text(
                                    'Contato',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF64748B)),
                                  tooltip: 'Registrar Contato',
                                  onPressed: () => _abrirContato(context, membro),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    IconData? icon;

    if (status == 'Ativo Pleno') {
      bg = const Color(0xFFD1FADF);
      text = const Color(0xFF027A48);
    } else if (status == 'Ativo') {
      bg = const Color(0xFFECFDF3);
      text = const Color(0xFF12B76A);
    } else if (status == 'Regular') {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF475569);
    } else if (status == 'Faltoso Crítico') {
      bg = const Color(0xFFFEE4E2);
      text = const Color(0xFFB42318);
      icon = Icons.priority_high_rounded;
    } else {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: text, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.bold,
  color: Color(0xFF64748B),
  letterSpacing: 0.5,
);
