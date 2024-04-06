import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/application/usecase.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_storage_provider.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_store_provider.dart';
import 'package:meter_reading_app/feature/scan_meter/model/request/meter_reading_request.dart';

final insertMeterReadingUsecaseProvider =
    Provider<InsertMeterReadingUsecase>((ref) {
  final fireCloudStore = ref.watch(firebaseCloudStoreProvider);
  final firebaseCloudStorage = ref.watch(firebaseCloudStorageProvider);

  return InsertMeterReadingUsecase(
    ref,
    fireCloudStore,
    firebaseCloudStorage,
  );
});

class InsertMeterReadingUsecase extends UseCase<MeterReadingRequest, bool> {
  final FirebaseCloudStore fireCloudStore;
  final FirebaseStorageProvider firebaseCloudStorage;

  InsertMeterReadingUsecase(
    Ref ref,
    this.fireCloudStore,
    this.firebaseCloudStorage,
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
      final img = request.img;

      final collectMeterReading = fireCloudStore.collection('meterReading');
      final docId = collectMeterReading.doc().id;

      String urlMeterImg =
          await firebaseCloudStorage.uploadStorage(img!, 'meterImg/$docId');

      final Map<String, dynamic> myData = {
        "id": docId,
        "meterReading": meterReading,
        "meterId": meterId,
        "urlMeterImg": urlMeterImg,
        "create_at": DateTime.now(),
        "update_at": DateTime.now(),
      };

      await collectMeterReading.doc(docId).set(myData);

      return true;
    } catch (e) {
      return false;
    }
  }
}
