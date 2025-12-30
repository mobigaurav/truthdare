import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Flutter framework errors -> Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Dart errors (async) -> Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ✅ Mark this device as a test device (use the ID from your log)
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ['69ab5b47fd2a3d00ae679c9734e46542']),
  );

  // Initialize Google Mobile Ads (safe even before configuring IDs)
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: TruthDareApp()));
}
