import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Função para tocar (Gerencia o download automático)
  Future<void> tocarAudio(String url) async {
    try {
      print("Verificando cache ou baixando: $url");

      // O getSingleFile busca no cache. Se não tiver, baixa e salva.
      // No Flutter Web, isso usa o Cache API do navegador.
      final file = await DefaultCacheManager().getSingleFile(url);

      // Toca o arquivo local
      await _player.setFilePath(file.path);
      // Nota: No Web, o file.path é uma URL blob especial (blob:http://...)

      _player.play();
    } catch (e) {
      print("Erro ao carregar áudio: $e");
    }
  }

  // Função para apenas baixar (Botão de Download)
  Future<void> baixarParaOffline(String url) async {
    // Apenas chamamos o getSingleFile sem dar play.
    // Isso força o download e o armazenamento no cache.
    await DefaultCacheManager().getSingleFile(url);
    print("Áudio salvo para uso offline!");
  }

  // Verifica se já está baixado (para mudar ícone da UI)
  Future<bool> estaBaixado(String url) async {
    final fileInfo = await DefaultCacheManager().getFileFromCache(url);
    return fileInfo != null;
  }
}
