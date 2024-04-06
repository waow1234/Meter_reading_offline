import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/application/usecase.dart';
import 'package:meter_reading_app/feature/scan_meter/model/response/test_api_response.dart';
import 'package:meter_reading_app/feature/scan_meter/service/meter_reading_service.dart';

final testApiUseCaseProvider = Provider<TestApiUseCase>((ref) {
  final apiService = ref.watch(meterReadingServiceProvider);

  return TestApiUseCase(apiService, ref);
});

class TestApiUseCase extends UseCase<void, TestAPIResponse> {
  MeterReadingService apiService;

  TestApiUseCase(
    this.apiService,
    Ref ref,
  ) {
    this.ref = ref;
  }

  @override
  Future<TestAPIResponse> exec(void request) async {
    final res = await apiService.testAPi();

    return res;
  }
}
