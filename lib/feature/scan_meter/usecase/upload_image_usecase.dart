import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/application/usecase.dart';
import 'package:meter_reading_app/feature/scan_meter/model/response/meter_reading_response.dart';
import 'package:meter_reading_app/feature/scan_meter/service/meter_reading_service.dart';

final uploadImageUseCaseProvider = Provider<UploadImageUseCase>((ref) {
  final apiService = ref.watch(meterReadingServiceProvider);

  return UploadImageUseCase(apiService, ref);
});

class UploadImageUseCase extends UseCase<File, MeterReadingResponse> {
  MeterReadingService apiService;

  UploadImageUseCase(
    this.apiService,
    Ref ref,
  ) {
    this.ref = ref;
  }

  @override
  Future<MeterReadingResponse> exec(File request) async {
    final uploads = await MultipartFile.fromFile(
      request.path,
      filename: request.path.split('/').last,
    );

    final formData = FormData.fromMap({'file': uploads});

    final res = await apiService.getImageProcessing(formData);

    return res;
  }
}
