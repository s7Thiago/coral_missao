/// Modelo para representação e controle de acesso via Feature Toggle por dispositivo.
class DeviceAccess {
  final String id;
  final String name;
  final String accessLevel; // "FULL" | "READ_ONLY"

  const DeviceAccess({
    required this.id,
    required this.name,
    required this.accessLevel,
  });

  factory DeviceAccess.fromJson(Map<String, dynamic> json) {
    return DeviceAccess(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      accessLevel: (json['acessLevel'] ?? json['accessLevel']) as String? ?? 'READ_ONLY',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'acessLevel': accessLevel,
    };
  }

  DeviceAccess copyWith({
    String? id,
    String? name,
    String? accessLevel,
  }) {
    return DeviceAccess(
      id: id ?? this.id,
      name: name ?? this.name,
      accessLevel: accessLevel ?? this.accessLevel,
    );
  }
}

class UserFeatureAccess {
  final String username;
  final List<DeviceAccess> deviceIds;

  const UserFeatureAccess({
    required this.username,
    required this.deviceIds,
  });

  factory UserFeatureAccess.fromJson(Map<String, dynamic> json) {
    final devicesRaw = json['deviceIds'] as List<dynamic>? ?? [];
    return UserFeatureAccess(
      username: json['username'] as String? ?? '',
      deviceIds: devicesRaw
          .map((d) => DeviceAccess.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'deviceIds': deviceIds.map((d) => d.toJson()).toList(),
    };
  }

  UserFeatureAccess copyWith({
    String? username,
    List<DeviceAccess>? deviceIds,
  }) {
    return UserFeatureAccess(
      username: username ?? this.username,
      deviceIds: deviceIds ?? this.deviceIds,
    );
  }
}

/// Modelo raiz que mapeia dinamicamente cada Feature (ex: 'adm_panel') para seus respectivos acessos.
class FeatureToggleModel {
  /// Mapeia o nome da feature (ex: 'adm_panel') para a lista de acessos por usuário [UserFeatureAccess].
  final Map<String, List<UserFeatureAccess>> features;

  const FeatureToggleModel({
    this.features = const {},
  });

  /// Atalho de conveniência para obter a lista da feature 'adm_panel'.
  List<UserFeatureAccess> get admPanel => features['adm_panel'] ?? const [];

  /// Verifica se um determinado [deviceId] possui acesso liberado a uma [featureName].
  bool hasAccess({
    required String featureName,
    required String deviceId,
  }) {
    final userList = features[featureName];
    if (userList == null || userList.isEmpty) return false;

    for (final user in userList) {
      for (final device in user.deviceIds) {
        if (device.id == deviceId) {
          return true;
        }
      }
    }
    return false;
  }

  /// Retorna o nível de acesso ("FULL", "READ_ONLY") de um [deviceId] para uma [featureName], ou null se negado.
  String? getAccessLevel({
    required String featureName,
    required String deviceId,
  }) {
    final userList = features[featureName];
    if (userList == null || userList.isEmpty) return null;

    for (final user in userList) {
      for (final device in user.deviceIds) {
        if (device.id == deviceId) {
          return device.accessLevel;
        }
      }
    }
    return null;
  }

  factory FeatureToggleModel.fromJson(Map<String, dynamic> json, [String? id]) {
    final Map<String, List<UserFeatureAccess>> featuresMap = {};

    List<dynamic> featureToggleList = [];

    if (json.containsKey('feature_toggle') && json['feature_toggle'] is List) {
      featureToggleList = json['feature_toggle'] as List<dynamic>;
    } else {
      // Suporte para chaves diretas no formato mapa { "adm_panel": [...] }
      json.forEach((key, value) {
        if (value is List) {
          final users = value
              .whereType<Map>()
              .map((u) => UserFeatureAccess.fromJson(Map<String, dynamic>.from(u)))
              .toList();
          featuresMap[key] = users;
        }
      });
      return FeatureToggleModel(features: featuresMap);
    }

    for (final item in featureToggleList) {
      if (item is Map) {
        item.forEach((featureKey, userListRaw) {
          if (userListRaw is List) {
            final users = userListRaw
                .whereType<Map>()
                .map((u) => UserFeatureAccess.fromJson(Map<String, dynamic>.from(u)))
                .toList();
            featuresMap[featureKey.toString()] = users;
          }
        });
      }
    }

    return FeatureToggleModel(features: featuresMap);
  }

  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> featureList = [];

    features.forEach((featureKey, userList) {
      featureList.add({
        featureKey: userList.map((u) => u.toJson()).toList(),
      });
    });

    return {
      'feature_toggle': featureList,
    };
  }

  FeatureToggleModel copyWith({
    Map<String, List<UserFeatureAccess>>? features,
  }) {
    return FeatureToggleModel(
      features: features ?? this.features,
    );
  }
}
