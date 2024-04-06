import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/application/usecase.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_storage_provider.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_store_provider.dart';
import 'package:meter_reading_app/feature/scan_meter/model/request/meter_reading_request.dart';

final editMeterReadingUsecaseProvider =
    Provider<EditMeterReadingUsecase>((ref) {
  final fireCloudStore = ref.watch(firebaseCloudStoreProvider);

  return EditMeterReadingUsecase(
    ref,
    fireCloudStore,
  );
});

class EditMeterReadingUsecase extends UseCase<MeterReadingRequest, bool> {
  final FirebaseCloudStore fireCloudStore;

  EditMeterReadingUsecase(
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
      final meterReading = request.meterReading;
      final meterId = request.meterId;

      final collectMeterReading = fireCloudStore.collection('meterReading');
      final docId = request.id;

      final Map<String, dynamic> myData = {
        "meterReading": meterReading,
        "meterId": meterId,
        "update_at": DateTime.now(),
      };

      await collectMeterReading.doc(docId).update(myData);

      return true;
    } catch (e) {
      return false;
    }
  }
}
