import 'package:flutter/material.dart';
import '../models/repertorio_model.dart';
import '../services/repertorio_service.dart';

class RepertorioViewModel extends ChangeNotifier {
  final RepertorioService _service = RepertorioService();

  List<RepertorioItem> _repertorio = [];
  bool _isLoading = false;
  String? _error;

  List<RepertorioItem> get repertorio => _repertorio;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRepertorio() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _repertorio = await _service.fetchRepertorio();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
