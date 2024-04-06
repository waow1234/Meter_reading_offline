import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meter_reading_app/base_widget/restart_widget.dart';
import 'package:meter_reading_app/core/app_color.dart';
import 'package:meter_reading_app/core/camera/base_camera.dart';
import 'package:meter_reading_app/core/firebase/analytics/analytics.dart';
import 'package:meter_reading_app/core/firebase/crashlytics/crashlytics.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_storage_provider.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_store_provider.dart';
import 'package:meter_reading_app/core/firebase/firebase_options_provider.dart';
import 'package:meter_reading_app/core/local/base_shared_preference.dart';
import 'package:meter_reading_app/core/logging/logging.dart';
import 'package:meter_reading_app/core/router/app_naviagor.dart';
import 'package:meter_reading_app/core/router/app_router.dart';
import 'package:meter_reading_app/core/widget/base_consumer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final sharedPrefs = await SharedPreferences.getInstance();
      final cameras = await availableCameras();

      final container = ProviderContainer(
        overrides: [
          sharedPreferences.overrideWithValue(sharedPrefs),
          cameraProvider.overrideWithValue(cameras),
        ],
      );

      // Initialize Firebase base on current environment
      final firebaseOptions = container.read(firebaseOptionsProvider);
      await Firebase.initializeApp(
        options: firebaseOptions,
      );

      // You can automatically catch all errors that are thrown within the
      // Flutter framework by overriding
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // Firebase analytics setup
      final firebaseAnalytics = container.read(firebaseAnalyticsProvider);
      await firebaseAnalytics.logAppOpen();

      // Setup firebase crashlytics
      container.read(firebaseCrashlyticsProvider);

      //Setup Firebase Cloud Store
      container.read(firebaseCloudStoreProvider);

      //Setup Firebase Cloud Storage
      container.read(firebaseCloudStorageProvider);

      await container.read(loggingProvider).init();

      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );

      container.read(sharedPreferences);
      container.read(cameraProvider);

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const RestartWidget(
            child: RootRestorationScope(
              restorationId: 'root',
              child: MyApp(),
            ),
          ),
        ),
      );
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends BaseConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final appNavigator = ref.watch(appNavigatorProvider);

    return ScreenUtilInit(
      builder: (_, child) {
        return MaterialApp(
          navigatorKey: appNavigator.navigatorKey,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRouter.initialRouterName,
          onGenerateRoute: AppRouter.router,
          title: 'Meter Reading',
          builder: (context, child) {
            return SizedBox(
              child: child,
            );
          },
        );
      },
    );
  }
}
