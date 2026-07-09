import 'package:demo_app/myApp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

import 'core/services/cache_service.dart';
import 'core/services/mock_database_service.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} onChange: $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('${bloc.runtimeType} onError: $error');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Authentication
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Initialize Dependency Injection container (GetIt + Injectable)
  await configureDependencies();

  // 2. Initialize Cache Service (Hive + AES secure storage keys)
  await getIt<CacheService>().init();

  // 3. Initialize Database Service and sync/seed with Firestore
  await getIt<MockDatabaseService>().init();

  // 4. Register Global Bloc Observer
  Bloc.observer = SimpleBlocObserver();

  runApp(const MyApp());
}
