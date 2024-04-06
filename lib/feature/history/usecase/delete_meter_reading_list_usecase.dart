import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/application/usecase.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_store_provider.dart';
import 'package:meter_reading_app/feature/history/model/response/meter_reading_response.dart';
import 'package:meter_reading_app/feature/scan_meter/model/request/meter_reading_request.dart';

final deleteMeterReadingListUsecaseProvider =
    Provider<DeleteMeterReadingListUsecase>((ref) {
  final fireCloudStore = ref.watch(firebaseCloudStoreProvider);

  return DeleteMeterReadingListUsecase(
    ref,
    fireCloudStore,
  );
});

class DeleteMeterReadingListUsecase extends UseCase<MeterReadingRequest, bool> {
  final FirebaseCloudStore fireCloudStore;

  DeleteMeterReadingListUsecase(
    Ref ref,
    this.fireCloudStore,
  ) {
    this.ref = ref;
  }

  @override
  Future<bool> exec(
    MeterReadingRequest request,
  ) async {
    try {
      await fireCloudStore.collection('meterReading').doc(request.id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
