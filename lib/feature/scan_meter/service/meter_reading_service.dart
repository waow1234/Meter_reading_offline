import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/remote/network_service.dart';
import 'package:meter_reading_app/feature/scan_meter/model/response/meter_reading_response.dart';
import 'package:meter_reading_app/feature/scan_meter/model/response/test_api_response.dart';
import 'package:retrofit/retrofit.dart';
part 'meter_reading_service.g.dart';

final meterReadingServiceProvider = Provider<MeterReadingService>((ref) {
  final dio = ref.watch(networkServiceProvider);
  return MeterReadingService(dio);
});

@RestApi()
abstract class MeterReadingService {
  factory MeterReadingService(Dio dio) => _MeterReadingService(dio);

  @GET('/')
  Future<TestAPIResponse> testAPi();

  @POST('/image-processing')
  @MultiPart()
  Future<MeterReadingResponse> getImageProcessing(
    @Body() FormData upload,
  );
}
