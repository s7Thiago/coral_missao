import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'viewmodels/repertorio_viewmodel.dart';
import 'views/home_view.dart';

import 'package:coral_missao/utils/device_utils.dart';
import 'services/audio_service.dart';
import 'services/firestore_service.dart';
import 'services/feature_toggle_service.dart';
import 'widgets/device_id_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }

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
        Provider(create: (_) => FirestoreService()),
        Provider(
          create: (context) => FeatureToggleService(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
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
