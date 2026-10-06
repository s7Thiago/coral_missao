import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ensaio_model.dart';
import '../models/membro_coral_model.dart';
import '../models/naipe_stat_model.dart';
import '../services/ensaio_service.dart';
import '../services/membro_coral_service.dart';

/// ViewModel desacoplado responsável por gerenciar a lógica de negócios, paginação debounced e marcação de presença do Painel Administrativo.
class AdminPanelViewModel extends ChangeNotifier {
  final MembroCoralService _membroService;
  final EnsaioService _ensaioService;

  bool _isLoading = false;
  String? _errorMessage;

  List<MembroCoralModel> _membros = [];
  List<EnsaioModel> _todosEnsaios = [];
  EnsaioModel? _ensaioAtual;

  DateTime _dataEnsaioSelecionada = DateTime.now();
  String _searchQuery = '';
  String _selectedNaipe = 'Todos';
  String _selectedStatusFilter = 'Ativos'; // Padrão 'Ativos' conforme solicitado

  int _currentPage = 0;
  int _pageSize = 25; // Padrão 25 conforme solicitado
  Timer? _debounceTimer;

  AdminPanelViewModel({
    required MembroCoralService membroService,
    required EnsaioService ensaioService,
  })  : _membroService = membroService,
        _ensaioService = ensaioService {
    carregarDados();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MembroCoralModel> get todosMembros => _membros;
  List<EnsaioModel> get todosEnsaios => _todosEnsaios;
  EnsaioModel? get ensaioAtual => _ensaioAtual;
  DateTime get dataEnsaioSelecionada => _dataEnsaioSelecionada;

  String get dataEnsaioFormatada {
    final y = _dataEnsaioSelecionada.year.toString().padLeft(4, '0');
    final m = _dataEnsaioSelecionada.month.toString().padLeft(2, '0');
    final d = _dataEnsaioSelecionada.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get searchQuery => _searchQuery;
  String get selectedNaipe => _selectedNaipe;
  String get selectedStatusFilter => _selectedStatusFilter;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  // Estatísticas do topo
  int get countAtivos => _membros.where((m) => m.ativo != 'n').length;
  int get countTodos => _membros.length;
  int get countFrequentes => _membros.where((m) => m.assiduidadeCalculada >= 0.85).length;
  int get countFaltososCriticos =>
      _membros.where((m) => m.statusGeralCalculado == 'Faltoso Crítico').length;
  int get countLicencaInativo => _membros.where((m) => m.ativo == 'n').length;

  double get assiduidadeGeral {
    final ativos = _membros.where((m) => m.ativo != 'n').toList();
    if (ativos.isEmpty) return 0.0;
    final totalAssiduidade = ativos.fold<double>(0.0, (acc, m) => acc + m.assiduidadeCalculada);
    return totalAssiduidade / ativos.length;
  }

  /// Retorna as estatísticas consolidadas de equilíbrio vocal por naipe.
  List<NaipeStatModel> get statsNaipes {
    final ativos = _membros.where((m) => m.ativo != 'n').toList();

    final Map<String, List<MembroCoralModel>> grupos = {
      'Sopranos (1º e 2º)': [],
      'Contraltos': [],
      'Tenores': [],
      'Baixos & Barítonos': [],
    };

    for (final m in ativos) {
      final naipe = (m.naipeVocal ?? '').toLowerCase().trim();
      if (naipe.contains('soprano')) {
        grupos['Sopranos (1º e 2º)']!.add(m);
      } else if (naipe.contains('contralto') || naipe.contains('alto')) {
        grupos['Contraltos']!.add(m);
      } else if (naipe.contains('tenor')) {
        grupos['Tenores']!.add(m);
      } else if (naipe.contains('baixo') || naipe.contains('barítono') || naipe.contains('baritono')) {
        grupos['Baixos & Barítonos']!.add(m);
      } else {
        grupos['Sopranos (1º e 2º)']!.add(m);
      }
    }

    return grupos.entries.map((entry) {
      final membros = entry.value;
      final vozes = membros.length;
      final assiduidadeMedia = vozes == 0
          ? 0.0
          : membros.fold<double>(0.0, (acc, m) => acc + m.assiduidadeCalculada) / vozes;

      return NaipeStatModel(
        nomeNaipe: entry.key,
        countVozes: vozes,
        assiduidadeMedia: assiduidadeMedia,
      );
    }).toList();
  }

  /// Retorna a lista de coristas filtrada por Busca, Naipe e Status, ordenada em ordem alfabética.
  List<MembroCoralModel> get membrosFiltrados {
    final list = _membros.where((membro) {
      // Filtro de Busca Por Nome ou Naipe
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final nome = (membro.nome ?? '').toLowerCase();
        final naipe = (membro.naipeVocal ?? '').toLowerCase();
        if (!nome.contains(query) && !naipe.contains(query)) return false;
      }

      // Filtro por Naipe
      if (_selectedNaipe != 'Todos') {
        final naipe = (membro.naipeVocal ?? '').toLowerCase();
        if (!naipe.contains(_selectedNaipe.toLowerCase())) return false;
      }

      // Filtro por Status (Ativos por padrão)
      if (_selectedStatusFilter == 'Ativos') {
        if (membro.ativo == 'n') return false;
      } else if (_selectedStatusFilter == 'Frequentes (>85%)') {
        if (membro.assiduidadeCalculada < 0.85) return false;
      } else if (_selectedStatusFilter == 'Faltosos Críticos') {
        if (membro.statusGeralCalculado != 'Faltoso Crítico') return false;
      } else if (_selectedStatusFilter == 'Licença / Inativo') {
        if (membro.ativo != 'n') return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      final nomeA = (a.nome ?? '').toLowerCase();
      final nomeB = (b.nome ?? '').toLowerCase();
      return nomeA.compareTo(nomeB);
    });

    return list;
  }

  /// Retorna a sublista paginada para exibição na tabela/cards.
  List<MembroCoralModel> get membrosPaginados {
    final filtrados = membrosFiltrados;
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= filtrados.length) return [];
    final endIndex = (startIndex + _pageSize < filtrados.length)
        ? startIndex + _pageSize
        : filtrados.length;
    return filtrados.sublist(startIndex, endIndex);
  }

  int get totalPages {
    final total = membrosFiltrados.length;
    if (total == 0) return 1;
    return (total / _pageSize).ceil();
  }

  /// Inicializa e recarrega os membros e ensaios do Firestore.
  Future<void> carregarDados() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _membros = await _membroService.getMembrosCoral();
      _ordenarMembros();
      _todosEnsaios = await _ensaioService.getTodosEnsaios();
      await _carregarOuCriarEnsaioParaData(dataEnsaioFormatada);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _ordenarMembros() {
    _membros.sort((a, b) {
      final nomeA = (a.nome ?? '').toLowerCase();
      final nomeB = (b.nome ?? '').toLowerCase();
      return nomeA.compareTo(nomeB);
    });
  }

  /// Altera a data do ensaio selecionado e carrega seu registro.
  Future<void> selecionarDataEnsaio(DateTime data) async {
    _dataEnsaioSelecionada = data;
    _isLoading = true;
    notifyListeners();

    try {
      await _carregarOuCriarEnsaioParaData(dataEnsaioFormatada);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _carregarOuCriarEnsaioParaData(String dataIso) async {
    var ensaio = await _ensaioService.getEnsaioPorData(dataIso);
    if (ensaio == null) {
      final docId = 'ensaio_$dataIso';
      ensaio = EnsaioModel(
        idEnsaio: docId,
        dataEnsaio: dataIso,
        membrosPresentes: [],
        membrosFaltantes: [],
      );
    }
    _ensaioAtual = ensaio;
  }

  /// Atualiza a busca com Debounce de 300ms.
  void setSearchQuery(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _currentPage = 0; // reseta paginação ao buscar
      notifyListeners();
    });
  }

  void setSelectedNaipe(String naipe) {
    _selectedNaipe = naipe;
    _currentPage = 0;
    notifyListeners();
  }

  void setSelectedStatusFilter(String statusFilter) {
    _selectedStatusFilter = statusFilter;
    _currentPage = 0;
    notifyListeners();
  }

  void setPageSize(int size) {
    if (_pageSize != size) {
      _pageSize = size;
      _currentPage = 0;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void setPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Marca a presença ou falta de um corista para o ensaio da data selecionada.
  Future<void> marcarPresenca(String membroId, bool estaPresente) async {
    if (_ensaioAtual == null) return;

    final presentes = List<String>.from(_ensaioAtual!.membrosPresentes);
    final faltantes = List<String>.from(_ensaioAtual!.membrosFaltantes);

    if (estaPresente) {
      if (!presentes.contains(membroId)) presentes.add(membroId);
      faltantes.remove(membroId);
    } else {
      if (!faltantes.contains(membroId)) faltantes.add(membroId);
      presentes.remove(membroId);
    }

    _ensaioAtual = _ensaioAtual!.copyWith(
      membrosPresentes: presentes,
      membrosFaltantes: faltantes,
    );

    // Notifica a UI instantaneamente (otimista)
    notifyListeners();

    try {
      await _ensaioService.salvarEnsaio(_ensaioAtual!);
      _todosEnsaios = await _ensaioService.getTodosEnsaios();

      // Recalcula estatísticas dos membros no Firestore
      await _ensaioService.recalcularEstatisticaMembros(
        membros: _membros,
        todosEnsaios: _todosEnsaios,
      );

      // Recarrega a lista de membros com os novos dados calculados
      _membros = await _membroService.getMembrosCoral();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao salvar presença: $e';
      notifyListeners();
    }
  }

  /// Salva as edições ou novo cadastro de um corista no Firestore e atualiza o estado local.
  Future<void> salvarMembroCoral(MembroCoralModel membroEditado) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (membroEditado.id != null && membroEditado.id!.isNotEmpty) {
        await _membroService.updateMembroCoral(membroEditado);
      } else {
        await _membroService.addMembroCoral(membroEditado);
      }

      // Recalcula as estatísticas caso o status de ativo tenha mudado
      _todosEnsaios = await _ensaioService.getTodosEnsaios();
      _membros = await _membroService.getMembrosCoral();
      await _ensaioService.recalcularEstatisticaMembros(
        membros: _membros,
        todosEnsaios: _todosEnsaios,
      );
      _membros = await _membroService.getMembrosCoral();
      _ordenarMembros();
    } catch (e) {
      _errorMessage = 'Erro ao salvar dados do corista: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exclui um corista da coleção 'membro_coral' no Firestore.
  Future<void> excluirMembroCoral(String docId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _membroService.deleteMembroCoral(docId);
      _membros.removeWhere((m) => m.id == docId);

      // Recalcula estatísticas
      _todosEnsaios = await _ensaioService.getTodosEnsaios();
      await _ensaioService.recalcularEstatisticaMembros(
        membros: _membros,
        todosEnsaios: _todosEnsaios,
      );
    } catch (e) {
      _errorMessage = 'Erro ao excluir corista: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Zera (reset) a chamada de presenças e faltas do ensaio selecionado.
  Future<void> resetarEnsaioAtual([String? dataIso]) async {
    final targetData = dataIso ?? dataEnsaioFormatada;
    final ensaioTarget = await _ensaioService.getEnsaioPorData(targetData);

    if (ensaioTarget == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _ensaioService.resetarEnsaio(ensaioTarget.idEnsaio);
      _todosEnsaios = await _ensaioService.getTodosEnsaios();

      await _ensaioService.recalcularEstatisticaMembros(
        membros: _membros,
        todosEnsaios: _todosEnsaios,
      );

      _membros = await _membroService.getMembrosCoral();
      await _carregarOuCriarEnsaioParaData(dataEnsaioFormatada);
    } catch (e) {
      _errorMessage = 'Erro ao resetar ensaio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica se o membro está marcado como presente no ensaio atual.
  bool isMembroPresente(String membroId) {
    if (_ensaioAtual == null) return false;
    return _ensaioAtual!.membrosPresentes.contains(membroId);
  }

  /// Verifica se o membro está marcado como faltante no ensaio atual.
  bool isMembroFaltante(String membroId) {
    if (_ensaioAtual == null) return false;
    return _ensaioAtual!.membrosFaltantes.contains(membroId);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
