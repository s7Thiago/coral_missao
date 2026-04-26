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

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final String _boxName = 'kitsCoral';

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  Voz? currentVoz;

  bool isDownloading = false;
  double downloadProgress = 0.0;
  String downloadUrl = '';

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

  void pause() {
    _player.pause();
  }

  void play() {
    _player.play();
  }

  void stop() {
    _player.stop();
  }

  void setVolume(double value) {
    _player.setVolume(value);
  }

  void setSpeed(double speed) {
    playbackSpeed = speed;
    _player.setSpeed(speed);
    notifyListeners();
  }

  void seek(Duration pos) {
    _player.seek(pos);
  }

  void playVoz(Voz voz, {bool keepPosition = false}) {
    if (currentVoz == voz) return;
    Duration? startPos = (keepPosition && position > Duration.zero) ? position : null;
    currentVoz = voz;
    notifyListeners();
    tocarAudio(voz.link, startPosition: startPos);
  }

  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void changeSpeed() {
    if (playbackSpeed == 1.0) {
      setSpeed(1.25);
    } else if (playbackSpeed == 1.25) {
      setSpeed(1.5);
    } else if (playbackSpeed == 1.5) {
      setSpeed(2.0);
    } else if (playbackSpeed == 2.0) {
      setSpeed(0.5);
    } else {
      setSpeed(1.0);
    }
  }

  // Função para tocar (Gerencia o download automático)
  Future<void> tocarAudio(String url, {Duration? startPosition}) async {
    try {
      print("Verificando cache ou baixando: $url");
      var audioBox = Hive.box(_boxName);

      // 1. Tenta recuperar do cache (Hive)
      Uint8List? audioBytes = audioBox.get(url);

      if (audioBytes != null) {
        print("Áudio encontrado no cache!");
        await _player.stop();
        await _player.setAudioSource(MyAudioSource(audioBytes, url), initialPosition: startPosition);
        _player.play();
      } else {
        // Notifica UI que download vai começar (evita travamento percebido e exibe indicador instantaneamente)
        isDownloading = true;
        downloadProgress = 0.0;
        downloadUrl = url;
        notifyListeners();

        // 2. Toca instantaneamente via streaming sem travar o início do download visual
        Future.microtask(() async {
          try {
            await _player.stop();
            await _player.setAudioSource(AudioSource.uri(Uri.parse(url)), initialPosition: startPosition);
            _player.play();
          } catch (e) {
            print("Falha ao iniciar streaming instantâneo: $e");
          }
        });

        // 3. Inicia o download em background com progresso para salvar offline

        try {
          var request = http.Request('GET', Uri.parse(url));
          var response = await http.Client().send(request);

          if (response.statusCode == 200) {
            int totalBytes = response.contentLength ?? 0;
            List<int> bytes = [];

            await for (var chunk in response.stream) {
              bytes.addAll(chunk);
              if (totalBytes > 0) {
                downloadProgress = bytes.length / totalBytes;
                notifyListeners();
              }
            }

            audioBytes = Uint8List.fromList(bytes);
            await audioBox.put(url, audioBytes);
            print("Áudio salvo no cache com sucesso!");
            
            // Se o streaming falhou antes, toca agora que baixou
            if (_player.playing == false && currentVoz?.link == url) {
              await _player.stop();
              await _player.setAudioSource(MyAudioSource(audioBytes, url), initialPosition: startPosition);
              _player.play();
            }
          } else {
            throw Exception("Status: ${response.statusCode}");
          }
        } catch (e) {
          print("Erro ao baixar em background: $e");
        } finally {
          isDownloading = false;
          downloadProgress = 0.0;
          notifyListeners();
        }
      }
    } catch (e) {
      print("Erro ao usar cache ou baixar (provável CORS ou erro de rede): $e");
      print("Tentando reprodução direta via streaming...");

      try {
        // Fallback: Tenta tocar direto da URL (streaming)
        await _player.stop();
        await _player.setUrl(url);
        _player.play();
      } catch (e2) {
        print("Erro fatal ao reproduzir áudio: $e2");
        rethrow;
      }
    }
  }

  // Função para apenas baixar (Botão de Download)
  Future<void> baixarParaOffline(String url) async {
    try {
      var audioBox = Hive.box(_boxName);

      if (audioBox.containsKey(url)) {
        print("Áudio já salvo offline!");
        return;
      }

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await audioBox.put(url, response.bodyBytes);
        print("Áudio salvo para uso offline!");
      } else {
        throw Exception("Falha no download (Status: ${response.statusCode})");
      }
    } catch (e) {
      print("Erro ao baixar para offline: $e");
      print("AVISO: Não foi possível salvar offline.");
    }
  }

  // Verifica se já está baixado (para mudar ícone da UI)
  Future<bool> estaBaixado(String url) async {
    var audioBox = Hive.box(_boxName);
    return audioBox.containsKey(url);
  }
}
