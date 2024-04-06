import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meter_reading_app/core/loader/loader_controller.dart';
import 'package:meter_reading_app/feature/scan_meter/controller/state/image_processing_state.dart';
import 'package:meter_reading_app/feature/scan_meter/model/request/meter_reading_request.dart';
import 'package:meter_reading_app/feature/scan_meter/usecase/insert_meter_reading_usecase.dart';
import 'package:meter_reading_app/feature/scan_meter/usecase/test_api_usecase.dart';
import 'package:meter_reading_app/feature/scan_meter/usecase/upload_image_usecase.dart';
import 'package:meter_reading_app/utils/image_picker/image_cropper_provider.dart';

final imageProcessingControllerProvider =
    StateNotifierProvider<ImageProcessingController, ImageProcessingState>(
  (ref) {
    final imageCropperUtils = ref.watch(imageCropperUtilsProvider);
    final insertMeterReadingUsecase =
        ref.watch(insertMeterReadingUsecaseProvider);
    final uploadImageUseCase = ref.watch(uploadImageUseCaseProvider);
    final testApiUseCase = ref.watch(testApiUseCaseProvider);

    return ImageProcessingController(
      ref,
      const ImageProcessingState(),
      imageCropperUtils,
      insertMeterReadingUsecase,
      uploadImageUseCase,
      testApiUseCase,
    );
  },
);

class ImageProcessingController extends StateNotifier<ImageProcessingState> {
  final Ref _ref;
  final LoaderController _loader;
  final ImageCropperUtils _imageCropperUtils;
  final InsertMeterReadingUsecase _insertMeterReadingUsecase;
  final UploadImageUseCase _uploadImageUseCase;
  final TestApiUseCase _testApiUseCase;

  ImageProcessingController(
    this._ref,
    ImageProcessingState state,
    this._imageCropperUtils,
    this._insertMeterReadingUsecase,
    this._uploadImageUseCase,
    this._testApiUseCase,
  )   : _loader = _ref.read(loaderControllerProvider.notifier),
        super(state);

  Future<void> setFormData({
    required String key,
    required dynamic value,
  }) async {
    state = state.copyWith(
      formData: {
        ...state.formData,
        ...{key: value},
      },
    );
  }

  void setCameraImg(XFile file) {
    state = state.copyWith(cameraImg: file.path);
  }

  void setCropImgPath(String path) {
    state = state.copyWith(cropImgPath: path);
  }

  void setMeterId(String? meterId) {
    state = state.copyWith(meterId: meterId);
  }

  void setMeterReading(String? meterReading) {
    state = state.copyWith(meterReading: meterReading);
  }

  Future<CroppedFile?> onCroppedImage(XFile file) async {
    // Get index 0 because it is single image,
    final resultCrop = await _imageCropperUtils.cropImage(file);

    state = state.copyWith(
      cameraImg: resultCrop?.path,
    );

    return resultCrop;
  }

  void onClearState() {
    state = state.copyWith(
      cameraImg: null,
      cropImgPath: null,
      meterId: null,
      meterReading: null,
      errorMsg: null,
    );
  }

  Future<bool> onImageProcessing(File file) async {
    _loader.onLoad();
    bool isSuccess = false;

    final result = await _uploadImageUseCase.execute(file);

    result.when((success) {
      if (success.error.isEmpty) {
        isSuccess = true;
      }
      _loader.onDismissLoad();

      state = state.copyWith(
        meterId: success.meterId,
        meterReading: success.meterReading,
        errorMsg: success.error,
      );
    }, (error) {
      _loader.onDismissLoad();
    });

    return isSuccess;
  }

  void testApi() async {
    final result = await _testApiUseCase.execute(null);

    result.when((success) => print(success), (error) => print(error));
  }

  Future<bool> onInsertMeterReading(String meterReading) async {
    _loader.onLoad();
    bool isSuccess = false;
    final cropImgPath = state.cropImgPath;

    if (cropImgPath == null) {
      _loader.onDismissLoad();
      return isSuccess;
    }

    final result = await _insertMeterReadingUsecase.execute(MeterReadingRequest(
      meterId: state.meterId,
      meterReading: meterReading,
      img: File(cropImgPath),
    ));

    result.when(
      (success) {
        _loader.onDismissLoad();

        isSuccess = success;
      },
      (error) => _loader.onDismissLoad(),
    );

    return isSuccess;
  }
}
