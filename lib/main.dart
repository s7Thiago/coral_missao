import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'viewmodels/repertorio_viewmodel.dart';
import 'views/home_view.dart';

import 'package:coral_missao/utils/device_utils.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }
  await Hive.openBox('kitsCoral');

  // Pré-inicializa o ID do dispositivo e a versão do app
  await Future.wait([
    DeviceUtils.getDeviceId(),
    DeviceUtils.getAppVersion(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RepertorioViewModel()),
        ChangeNotifierProvider(create: (_) => AudioService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coral Missão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const Positioned(
              bottom: 6,
              right: 8,
              child: DeviceIdOverlay(),
            ),
          ],
        );
      },
      home: const HomeView(),
    );
  }
}

class DeviceIdOverlay extends StatelessWidget {
  const DeviceIdOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FutureBuilder<List<String>>(
        future: Future.wait([
          DeviceUtils.getAppVersion(),
          DeviceUtils.getDeviceId(),
        ]),
        initialData: [
          DeviceUtils.cachedAppVersion ?? 'v1.0.1+1',
          DeviceUtils.cachedDeviceId ?? '',
        ],
        builder: (context, snapshot) {
          final data = snapshot.data;
          final version = (data != null && data.isNotEmpty) ? data[0] : 'v1.0.1+1';
          final id = (data != null && data.length > 1) ? data[1] : '';

          if (id.isEmpty) {
            return const SizedBox.shrink();
          }

          return Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$version | ID: $id',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


