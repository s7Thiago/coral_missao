import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/repertorio_model.dart';
import '../services/repertorio_service.dart';
import 'dart:convert';

class RepertorioViewModel extends ChangeNotifier {
  final RepertorioService _service = RepertorioService();

  List<RepertorioItem> _repertorio = [];
  bool _isLoading = false;
  String? _error;
  bool _isUsingLocalFallback = false;

  List<RepertorioItem> get repertorio => _repertorio;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingLocalFallback => _isUsingLocalFallback;

  Future<void> loadRepertorio() async {
    _isLoading = true;
    _error = null;
    _isUsingLocalFallback = false;
    notifyListeners();

    try {
      _repertorio = await _service.fetchRepertorio();
    } catch (e) {
      // Fallback: carrega o repertório embutido nos assets
      try {
        final jsonString = await rootBundle.loadString(
          'assets/repertorio.json',
        );
        final List<dynamic> data = jsonDecode(jsonString);
        _repertorio = data
            .map((json) => RepertorioItem.fromJson(json))
            .toList();
        _isUsingLocalFallback = true;
        _error = null;
      } catch (assetError) {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
