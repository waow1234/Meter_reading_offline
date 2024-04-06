import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/firebase/firebase_options.dart';

final firebaseOptionsProvider = Provider<FirebaseOptions>((ref) {
  return DefaultFirebaseOptions.currentPlatform;
});
