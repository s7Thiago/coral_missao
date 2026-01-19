import 'dart:convert';

import 'package:dio/dio.dart';
import '../models/repertorio_model.dart';

class RepertorioService {
  final Dio _dio = Dio();
  final String _url =
      'https://raw.githubusercontent.com/s7Thiago/coral_missao/main/assets/repertorio.json';

  Future<List<RepertorioItem>> fetchRepertorio() async {
    try {
      final response = await _dio.get(_url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.data);
        return data.map((json) => RepertorioItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load repertorio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching repertorio: $e');
    }
  }
}
