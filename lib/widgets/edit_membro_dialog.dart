import 'package:flutter/material.dart';
import '../models/membro_coral_model.dart';
import '../viewmodels/admin_panel_viewmodel.dart';

/// Modal/Diálogo desacoplado e responsivo para exibição, edição completa e exclusão do cadastro de um corista.
class EditMembroDialog extends StatefulWidget {
  final MembroCoralModel membro;
  final AdminPanelViewModel viewModel;

  const EditMembroDialog({
    super.key,
    required this.membro,
    required this.viewModel,
  });

  static Future<void> show(
    BuildContext context, {
    MembroCoralModel? membro,
    required AdminPanelViewModel viewModel,
  }) {
    final alvo = membro ?? const MembroCoralModel(ativo: 's', naipeVocal: 'Soprano');
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditMembroDialog(membro: alvo, viewModel: viewModel),
    );
  }

  @override
  State<EditMembroDialog> createState() => _EditMembroDialogState();
}

class _EditMembroDialogState extends State<EditMembroDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _nomeResponsavelController;
  late TextEditingController _cpfController;
  late TextEditingController _rgController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _telefoneController;
  late TextEditingController _telefoneEmergenciaController;
  late TextEditingController _emailController;
  late TextEditingController _tipoSanguineoController;
  late TextEditingController _igrejaController;
  late TextEditingController _enderecoController;

  late String _naipeVocal;
  late bool _isAtivo;

  bool get isNovo => widget.membro.id == null || widget.membro.id!.isEmpty;

  @override
  void initState() {
    super.initState();
    final m = widget.membro;

    _nomeController = TextEditingController(text: m.nome ?? '');
    _nomeResponsavelController = TextEditingController(text: m.nomeResponsavel ?? '');
    _cpfController = TextEditingController(text: (m.cpf ?? '').toString());
    _rgController = TextEditingController(text: (m.rg ?? '').toString());
    _dataNascimentoController = TextEditingController(text: (m.dataNascimento ?? '').toString());
    _telefoneController = TextEditingController(text: (m.telefone ?? '').toString());
    _telefoneEmergenciaController = TextEditingController(text: (m.telefoneEmergencia ?? '').toString());
    _emailController = TextEditingController(text: m.email ?? '');
    _tipoSanguineoController = TextEditingController(text: m.tipoSanguineo ?? '');
    _igrejaController = TextEditingController(text: m.igreja ?? '');
    _enderecoController = TextEditingController(text: (m.endereco ?? '').toString());

    _naipeVocal = _normalizarNaipe(m.naipeVocal);
    _isAtivo = m.ativo != 'n';
  }

  String _normalizarNaipe(String? raw) {
    final n = (raw ?? '').toLowerCase();
    if (n.contains('soprano')) return 'Soprano';
    if (n.contains('contralto')) return 'Contralto';
    if (n.contains('tenor')) return 'Tenor';
    if (n.contains('baixo')) return 'Baixo';
    return 'Soprano';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeResponsavelController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _telefoneEmergenciaController.dispose();
    _emailController.dispose();
    _tipoSanguineoController.dispose();
    _igrejaController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final membroEditado = widget.membro.copyWith(
      nome: _nomeController.text.trim(),
      naipeVocal: _naipeVocal,
      ativo: _isAtivo ? 's' : 'n',
      nomeResponsavel: _nomeResponsavelController.text.trim(),
      cpf: _cpfController.text.trim(),
      rg: _rgController.text.trim(),
      dataNascimento: _dataNascimentoController.text.trim(),
      telefone: _telefoneController.text.trim(),
      telefoneEmergencia: _telefoneEmergenciaController.text.trim(),
      email: _emailController.text.trim(),
      tipoSanguineo: _tipoSanguineoController.text.trim(),
      igreja: _igrejaController.text.trim(),
      endereco: _enderecoController.text.trim(),
    );

    await widget.viewModel.salvarMembroCoral(membroEditado);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNovo
                ? 'Novo corista "${membroEditado.nome}" cadastrado com sucesso!'
                : 'Cadastro de "${membroEditado.nome}" atualizado com sucesso!',
          ),
        ),
      );
    }
  }

  Future<void> _confirmarExclusao() async {
    final membroId = widget.membro.id;
    if (membroId == null || membroId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Corista'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir permanentemente o cadastro de "${widget.membro.nome}" do sistema?',
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

    if (confirm == true && mounted) {
      await widget.viewModel.excluirMembroCoral(membroId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Corista "${widget.membro.nome}" excluído do sistema.')),
        );
      }
    }
  }

  Widget _buildResponsiveRow(bool isMobile, Widget field1, Widget field2) {
    if (isMobile) {
      return Column(
        children: [
          field1,
          const SizedBox(height: 12),
          field2,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: field1),
        const SizedBox(width: 12),
        Expanded(child: field2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 550;
    final maxHeight = mediaQuery.size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: isMobile ? double.infinity : 520,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho Fixo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(
                    isNovo ? Icons.person_add_rounded : Icons.badge_rounded,
                    color: const Color(0xFF16476B),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isNovo ? 'Cadastrar Novo Corista' : 'Editar Cadastro do Corista',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Conteúdo Formulário Rolável
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados Principais',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16476B)),
                      ),
                      const SizedBox(height: 10),

                      // Nome Completo
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome completo' : null,
                      ),
                      const SizedBox(height: 12),

                      // Naipe Vocal e Status Ativo
                      _buildResponsiveRow(
                        isMobile,
                        DropdownButtonFormField<String>(
                          initialValue: _naipeVocal,
                          decoration: const InputDecoration(
                            labelText: 'Naipe Vocal *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Soprano', child: Text('Soprano')),
                            DropdownMenuItem(value: 'Contralto', child: Text('Contralto')),
                            DropdownMenuItem(value: 'Tenor', child: Text('Tenor')),
                            DropdownMenuItem(value: 'Baixo', child: Text('Baixo')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _naipeVocal = val);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isAtivo ? 'Status: Ativo' : 'Status: Licença',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isAtivo ? const Color(0xFF12B76A) : Colors.red,
                                ),
                              ),
                              Switch(
                                value: _isAtivo,
                                activeThumbColor: const Color(0xFF12B76A),
                                onChanged: (val) => setState(() => _isAtivo = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Documentos & Contatos',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16476B)),
                      ),
                      const SizedBox(height: 10),

                      // CPF e RG
                      _buildResponsiveRow(
                        isMobile,
                        TextFormField(
                          controller: _cpfController,
                          decoration: const InputDecoration(
                            labelText: 'CPF',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _rgController,
                          decoration: const InputDecoration(
                            labelText: 'RG',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Telefone e Telefone de Emergência
                      _buildResponsiveRow(
                        isMobile,
                        TextFormField(
                          controller: _telefoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefone (WhatsApp)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _telefoneEmergenciaController,
                          decoration: const InputDecoration(
                            labelText: 'Telefone de Emergência',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email e Tipo Sanguíneo
                      _buildResponsiveRow(
                        isMobile,
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _tipoSanguineoController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo Sanguíneo',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Outras Informações Cadastrais',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16476B)),
                      ),
                      const SizedBox(height: 10),

                      // Igreja e Data de Nascimento
                      _buildResponsiveRow(
                        isMobile,
                        TextFormField(
                          controller: _igrejaController,
                          decoration: const InputDecoration(
                            labelText: 'Igreja Local',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _dataNascimentoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de Nascimento',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Responsável
                      TextFormField(
                        controller: _nomeResponsavelController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Responsável',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Endereço
                      TextFormField(
                        controller: _enderecoController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Endereço Residencial',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Rodapé Fixo de Ações
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: isMobile
                  ? Row(
                      children: [
                        if (!isNovo)
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                            tooltip: 'Excluir Corista',
                            onPressed: _confirmarExclusao,
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16476B),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _salvar,
                          icon: Icon(isNovo ? Icons.person_add_rounded : Icons.save_rounded, size: 18),
                          label: Text(isNovo ? 'Cadastrar' : 'Salvar'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (!isNovo)
                          TextButton.icon(
                            onPressed: _confirmarExclusao,
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                            label: const Text(
                              'Excluir Corista',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16476B),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _salvar,
                          icon: Icon(isNovo ? Icons.person_add_rounded : Icons.save_rounded, size: 18),
                          label: Text(isNovo ? 'Cadastrar Corista' : 'Salvar Alterações'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
