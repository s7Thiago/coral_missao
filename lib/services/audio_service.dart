import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../models/repertorio_model.dart';

class MyAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  final String id;
  MyAudioSource(this.bytes, this.id) : super(tag: id);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

/// Lê bytes do Hive em um isolate separado para não bloquear a UI.
Future<Uint8List?> _readCacheIsolate(String url) async {
  final box = Hive.box('kitsCoral');
  return box.get(url) as Uint8List?;
}

/// Salva bytes no Hive em um isolate separado.
Future<void> _writeCacheIsolate(Map<String, dynamic> args) async {
  final box = Hive.box('kitsCoral');
  await box.put(args['url'] as String, args['bytes'] as Uint8List);
}

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Voz? currentVoz;
  RepertorioItem? currentItem;
  bool shouldExpandPlayer = false;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double playbackSpeed = 1.0;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String downloadUrl = '';

  /// Guard para evitar requisições concorrentes de áudio.
  /// Incrementa a cada chamada; chamadas antigas descartam seu resultado.
  int _playGeneration = 0;

  final String _boxName = 'kitsCoral';

  AudioService() {
    _player.positionStream.listen((pos) {
      position = pos ?? Duration.zero;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
  }

  AudioPlayer get player => _player;

  void pause() => _player.pause();
  void play() => _player.play();

  Future<void> stop() async {
    await _player.stop();
    notifyListeners();
  }

  Future<void> stopAndClear() async {
    await _player.stop();
    currentVoz = null;
    notifyListeners();
  }

  void setVolume(double value) => _player.setVolume(value);

  void setSpeed(double speed) {
    playbackSpeed = speed;
    _player.setSpeed(speed);
    notifyListeners();
  }

  void seek(Duration pos) => _player.seek(pos);

  void togglePlayPause() => isPlaying ? pause() : play();

  void changeSpeed() {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.5];
    final idx = speeds.indexOf(playbackSpeed);
    setSpeed(speeds[(idx + 1) % speeds.length]);
  }

  void playVoz(
    Voz voz,
    RepertorioItem item, {
    bool keepPosition = false,
    bool expandPlayer = false,
  }) {
    if (currentVoz?.link == voz.link) {
      if (expandPlayer) {
        shouldExpandPlayer = true;
        notifyListeners();
      }
      return;
    }

    Duration? startPosition;
    if (keepPosition && _player.playing) {
      startPosition = _player.position;
    }

    currentVoz = voz;
    currentItem = item;
    if (expandPlayer) shouldExpandPlayer = true;

    // Notifica a UI imediatamente (feedback visual instantâneo)
    notifyListeners();

    // Dispara a carga de áudio em background sem bloquear
    unawaited(_loadAndPlay(voz.link, startPosition: startPosition));
  }

  /// Carrega e reproduz o áudio completamente em background.
  /// Usa [_playGeneration] como guard: se uma nova chamada chegar
  /// antes de esta terminar, o resultado é descartado silenciosamente.
  Future<void> _loadAndPlay(String url, {Duration? startPosition}) async {
    final generation = ++_playGeneration;

    try {
      // --- Passo 1: leitura de cache off-thread (não bloqueia UI) ---
      final Uint8List? cached = await compute(_readCacheIsolate, url);

      // Descarta se já foi iniciada outra música
      if (generation != _playGeneration) return;

      if (cached != null) {
        // Cache hit → carrega bytes em memória e toca instantaneamente
        await _player.stop();
        if (generation != _playGeneration) return;
        await _player.setAudioSource(
          MyAudioSource(cached, url),
          initialPosition: startPosition,
        );
        if (generation != _playGeneration) return;
        _player.play();
      } else {
        // Cache miss → streaming imediato + download em background
        _setDownloading(true, url);

        // Inicia streaming para não ter delay de reprodução
        try {
          await _player.stop();
          if (generation != _playGeneration) return;
          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(url)),
            initialPosition: startPosition,
          );
          if (generation != _playGeneration) return;
          _player.play();
        } catch (e) {
          debugPrint('Streaming falhou, aguardando download: $e');
        }

        // Download em background para salvar offline
        await _downloadToCache(url, generation, startPosition);
      }
    } catch (e) {
      if (generation != _playGeneration) return;
      debugPrint('Erro ao carregar áudio: $e');
      // Fallback final via URL direta
      try {
        await _player.stop();
        await _player.setUrl(url);
        _player.play();
      } catch (e2) {
        debugPrint('Erro fatal: $e2');
      }
    } finally {
      if (generation == _playGeneration) {
        _setDownloading(false, '');
      }
    }
  }

  void _setDownloading(bool value, String url) {
    isDownloading = value;
    downloadUrl = url;
    downloadProgress = 0.0;
    notifyListeners();
  }

  Future<void> _downloadToCache(
    String url,
    int generation,
    Duration? startPosition,
  ) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Status: ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        if (generation != _playGeneration) return; // abandonar se trocou música
        bytes.addAll(chunk);
        if (total > 0) {
          downloadProgress = bytes.length / total;
          notifyListeners();
        }
      }

      if (generation != _playGeneration) return;

      final audioBytes = Uint8List.fromList(bytes);

      // Salva cache off-thread
      await compute(
        _writeCacheIsolate,
        {'url': url, 'bytes': audioBytes},
      );

      debugPrint('Áudio salvo no cache.');

      // Se o streaming não estiver rolando, toca do cache agora
      if (!_player.playing && currentVoz?.link == url) {
        await _player.stop();
        await _player.setAudioSource(
          MyAudioSource(audioBytes, url),
          initialPosition: startPosition,
        );
        _player.play();
      }
    } catch (e) {
      debugPrint('Erro ao baixar para cache: $e');
    }
  }

  // Função para apenas baixar (Botão de Download)
  Future<void> baixarParaOffline(String url) async {
    try {
      final audioBox = Hive.box(_boxName);
      if (audioBox.containsKey(url)) {
        debugPrint('Áudio já salvo offline!');
        return;
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await audioBox.put(url, response.bodyBytes);
        debugPrint('Áudio salvo para uso offline!');
      } else {
        throw Exception('Falha no download (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Erro ao baixar para offline: $e');
    }
  }

  Future<bool> estaBaixado(String url) async {
    final audioBox = Hive.box(_boxName);
    return audioBox.containsKey(url);
  }
}
