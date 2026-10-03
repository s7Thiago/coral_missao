import 'firestore_service.dart';
import '../models/feature_toggle_model.dart';

/// Serviço desacoplado responsável por gerenciar a configuração e persistência do Feature Toggle no Firestore.
class FeatureToggleService {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'config';
  static const String _documentId = 'feature_toggle';

  FeatureToggleService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Recupera a configuração atual do Feature Toggle do Firestore.
  Future<FeatureToggleModel> getFeatureToggleConfig() async {
    try {
      final config = await _firestoreService.getDocumentAs<FeatureToggleModel>(
        collectionPath: _collectionPath,
        docId: _documentId,
        builder: (data, id) => FeatureToggleModel.fromJson(data, id),
      );
      return config ?? const FeatureToggleModel();
    } catch (e) {
      throw Exception('Erro ao buscar configuração de Feature Toggle: $e');
    }
  }

  /// Salva ou substitui a configuração de Feature Toggle no Firestore.
  Future<void> saveFeatureToggleConfig(FeatureToggleModel config) async {
    try {
      await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        docId: _documentId,
        data: config.toJson(),
      );
    } catch (e) {
      throw Exception('Erro ao salvar configuração de Feature Toggle: $e');
    }
  }

  /// Insere ou atualiza o acesso de um dispositivo para determinado usuário em uma feature específica (ex: 'adm_panel').
  Future<FeatureToggleModel> addOrUpdateDeviceAccess({
    String featureName = 'adm_panel',
    required String username,
    required String deviceId,
    String deviceName = 'Celular Teste',
    String accessLevel = 'FULL',
  }) async {
    final currentConfig = await getFeatureToggleConfig();
    final updatedFeatures = Map<String, List<UserFeatureAccess>>.from(currentConfig.features);
    final userList = List<UserFeatureAccess>.from(updatedFeatures[featureName] ?? []);

    final userIndex = userList.indexWhere(
      (u) => u.username.toLowerCase() == username.toLowerCase(),
    );

    final newDevice = DeviceAccess(
      id: deviceId,
      name: deviceName,
      accessLevel: accessLevel,
    );

    if (userIndex >= 0) {
      final existingUser = userList[userIndex];
      final updatedDevices = List<DeviceAccess>.from(existingUser.deviceIds);
      final deviceIndex = updatedDevices.indexWhere((d) => d.id == deviceId);

      if (deviceIndex >= 0) {
        updatedDevices[deviceIndex] = newDevice;
      } else {
        updatedDevices.add(newDevice);
      }

      userList[userIndex] = existingUser.copyWith(deviceIds: updatedDevices);
    } else {
      userList.add(
        UserFeatureAccess(
          username: username,
          deviceIds: [newDevice],
        ),
      );
    }

    updatedFeatures[featureName] = userList;
    final newConfig = currentConfig.copyWith(features: updatedFeatures);
    await saveFeatureToggleConfig(newConfig);
    return newConfig;
  }

  /// Ouve alterações em tempo real da configuração de Feature Toggle.
  Stream<FeatureToggleModel?> streamFeatureToggleConfig() {
    return _firestoreService.streamDocument<FeatureToggleModel>(
      collectionPath: _collectionPath,
      docId: _documentId,
      builder: (data, id) => FeatureToggleModel.fromJson(data, id),
    );
  }

  /// Transmite em tempo real um booleano indicando se o [deviceId] tem permissão para acessar a [featureName].
  Stream<bool> streamDeviceAccess({
    required String featureName,
    required String deviceId,
  }) {
    return streamFeatureToggleConfig().map((config) {
      if (config == null) return false;
      return config.hasAccess(featureName: featureName, deviceId: deviceId);
    });
  }

  /// Verifica pontualmente se o [deviceId] tem permissão para acessar a [featureName].
  Future<bool> hasDeviceAccess({
    required String featureName,
    required String deviceId,
  }) async {
    final config = await getFeatureToggleConfig();
    return config.hasAccess(featureName: featureName, deviceId: deviceId);
  }

  /// Verifica o nível de acesso (ex: "FULL", "READ_ONLY" ou null) de um determinado [deviceId] para a [featureName].
  Future<String?> getDeviceAccessLevel({
    String featureName = 'adm_panel',
    required String deviceId,
  }) async {
    final config = await getFeatureToggleConfig();
    return config.getAccessLevel(featureName: featureName, deviceId: deviceId);
  }
}
