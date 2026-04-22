import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class MyAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  MyAudioSource(this.bytes);

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

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final String _boxName = 'audioCache';

  // Função para tocar (Gerencia o download automático)
  Future<void> tocarAudio(String url) async {
    try {
      print("Verificando cache ou baixando: $url");
      var audioBox = Hive.box(_boxName);
      
      // 1. Tenta recuperar do cache (Hive)
      Uint8List? audioBytes = audioBox.get(url);

      if (audioBytes == null) {
        // 2. Se não estiver no cache, baixa via HTTP
        print("Baixando áudio...");
        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          audioBytes = response.bodyBytes;
          // Salva no Hive para uso futuro
          await audioBox.put(url, audioBytes);
        } else {
          throw Exception("Falha no download (Status: ${response.statusCode})");
        }
      } else {
        print("Áudio encontrado no cache!");
      }

      // 3. Toca usando a fonte de áudio customizada baseada em bytes
      await _player.setAudioSource(MyAudioSource(audioBytes));
      _player.play();
    } catch (e) {
      print("Erro ao usar cache ou baixar (provável CORS ou erro de rede): $e");
      print("Tentando reprodução direta via streaming...");

      try {
        // Fallback: Tenta tocar direto da URL (streaming)
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
