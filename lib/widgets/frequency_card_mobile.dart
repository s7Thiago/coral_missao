import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/membro_coral_model.dart';
import '../viewmodels/admin_panel_viewmodel.dart';
import 'attendance_summary_widget.dart';
import 'edit_membro_dialog.dart';

/// Card de corista desacoplado para a versão Mobile do Painel de Frequência.
/// Suporta o gesto de Swipe (Arrastar para direita = Presença; Arrastar para esquerda = Falta).
class FrequencyCardMobile extends StatelessWidget {
  final MembroCoralModel membro;
  final AdminPanelViewModel viewModel;

  const FrequencyCardMobile({
    super.key,
    required this.membro,
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
        SnackBar(content: Text('Nenhum telefone cadastrado para ${membro.nome}.')),
      );
      return;
    }

    final url = 'https://wa.me/55$foneLimpo';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membroId = membro.id ?? '';
    final isPresente = viewModel.isMembroPresente(membroId);
    final isFaltante = viewModel.isMembroFaltante(membroId);
    final isCritico = membro.statusGeralCalculado == 'Faltoso Crítico';

    Color cardBorderColor = const Color(0xFFE2E8F0);
    Color cardBgColor = Colors.white;

    if (isPresente) {
      cardBorderColor = const Color(0xFF12B76A);
      cardBgColor = const Color(0xFFF0FDF4);
    } else if (isFaltante) {
      cardBorderColor = const Color(0xFFF04438);
      cardBgColor = const Color(0xFFFEF2F2);
    }

    return Dismissible(
      key: ValueKey('membro_${membroId}_${viewModel.dataEnsaioFormatada}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (membroId.isEmpty) return false;
        if (direction == DismissDirection.startToEnd) {
          // Swipe para a Direita = Presença
          viewModel.marcarPresenca(membroId, true);
        } else if (direction == DismissDirection.endToStart) {
          // Swipe para a Esquerda = Falta
          viewModel.marcarPresenca(membroId, false);
        }
        return false; // Não remove o item da árvore de widgets
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF12B76A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'PRESENÇA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF04438),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'FALTA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Icons.cancel_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorderColor, width: isPresente || isFaltante ? 1.5 : 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getAvatarBg(membro.naipeVocal),
                    child: Text(
                      membro.initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getAvatarTextColor(membro.naipeVocal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          membro.naipeVocal ?? 'Naipe Não Def.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Widget Resumido (Status + Ensaios + Assiduidade)
                  AttendanceSummaryWidget(membro: membro, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              // Barra de Status de Presença e Gestos Mobile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge do estado marcado para o ensaio de hoje
                  Row(
                    children: [
                      if (isPresente)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FADF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF027A48)),
                              SizedBox(width: 4),
                              Text(
                                'Presente',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF027A48),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isFaltante)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE4E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cancel_rounded, size: 12, color: Color(0xFFB42318)),
                              SizedBox(width: 4),
                              Text(
                                'Falta',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          '👈 Falta | Presença 👉',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF16476B)),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 8),
                        tooltip: 'Editar Cadastro',
                        onPressed: () => EditMembroDialog.show(
                          context,
                          membro: membro,
                          viewModel: viewModel,
                        ),
                      ),
                      if (isCritico)
                        InkWell(
                          onTap: () => _abrirContato(context, membro),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Contato',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF64748B)),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          tooltip: 'Contato',
                          onPressed: () => _abrirContato(context, membro),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
