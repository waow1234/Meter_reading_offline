import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/env/env.dart';

final envReaderProvider = Provider<EnvReader>((ref) {
  return EnvReader();
});

class EnvReader {
  EnvReader();

  String baseUrl() {
    return Env.baseUrl;
  }
}
