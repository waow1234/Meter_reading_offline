import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/application/usecase.dart';
import 'package:meter_reading_app/core/firebase/database/cloud_store_provider.dart';
import 'package:meter_reading_app/feature/history/model/response/meter_reading_response.dart';

final getMeterReadingListUsecaseProvider =
    Provider<GetMeterReadingListUsecase>((ref) {
  final fireCloudStore = ref.watch(firebaseCloudStoreProvider);

  return GetMeterReadingListUsecase(
    ref,
    fireCloudStore,
  );
});

class GetMeterReadingListUsecase
    extends UseCase<void, List<MeterReadingResponse>> {
  final FirebaseCloudStore fireCloudStore;

  GetMeterReadingListUsecase(
    Ref ref,
    this.fireCloudStore,
  ) {
    this.ref = ref;
  }

  @override
  Future<List<MeterReadingResponse>> exec(
    void request,
  ) async {
    try {
      final collectMeterReading = await fireCloudStore
          .collection('meterReading')
          .orderBy('create_at')
          .get()
          .then((value) => value.docs);

      if (collectMeterReading.isEmpty) {
        return [];
      }

      List<MeterReadingResponse> meterReadingList = [];
      for (final item in collectMeterReading.reversed) {
        final _data = item.data() as Map<String, dynamic>;

        meterReadingList.add(
          MeterReadingResponse(
            id: _data['id'] ?? '',
            meterReading: _data['meterReading'] ?? '',
            meterId: _data['meterId'] ?? '',
            createAt: (_data['create_at'] as Timestamp).toDate(),
            updateAt: (_data['update_at'] as Timestamp).toDate(),
            imgPath: _data['urlMeterImg'] ?? '',
          ),
        );
      }

      return meterReadingList;
    } catch (e) {
      return [];
    }
  }
}
