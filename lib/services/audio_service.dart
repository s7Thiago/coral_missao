import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Função para tocar (Gerencia o download automático)
  Future<void> tocarAudio(String url) async {
    try {
      print("Verificando cache ou baixando: $url");

      // Tenta baixar/buscar do cache
      final file = await DefaultCacheManager().getSingleFile(url);

      // Se sucesso, toca do arquivo local (blob URL no web)
      await _player.setFilePath(file.path);
      _player.play();
    } catch (e) {
      print("Erro ao usar cache (provável CORS ou erro de rede): $e");
      print("Tentando reprodução direta (streaming)...");

      try {
        // Fallback: Tenta tocar direto da URL (streaming)
        // Isso geralmente funciona no Web mesmo sem CORS (opaque response),
        // mas não permite cache offline se o servidor não suportar.
        await _player.setUrl(url);
        _player.play();
      } catch (e2) {
        print("Erro fatal ao reproduzir áudio: $e2");
        rethrow; // Propaga erro para a UI tratar
      }
    }
  }

  // Função para apenas baixar (Botão de Download)
  Future<void> baixarParaOffline(String url) async {
    try {
      // Apenas chamamos o getSingleFile sem dar play.
      // Isso força o download e o armazenamento no cache.
      await DefaultCacheManager().getSingleFile(url);
      print("Áudio salvo para uso offline!");
    } catch (e) {
      print("Erro ao baixar para offline: $e");
      // Opcional: Relançar ou notificar UI
      throw Exception(
        "Não foi possível baixar para offline. Verifique a conexão ou restrições do servidor.",
      );
    }
  }

  // Verifica se já está baixado (para mudar ícone da UI)
  Future<bool> estaBaixado(String url) async {
    final fileInfo = await DefaultCacheManager().getFileFromCache(url);
    return fileInfo != null;
  }
}
