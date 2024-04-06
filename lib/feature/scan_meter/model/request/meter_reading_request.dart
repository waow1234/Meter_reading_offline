import 'dart:io';

class MeterReadingRequest {
  final String? id;
  final String? meterReading;
  final String? meterId;
  final String? imgPath;
  final File? img;

  MeterReadingRequest({
    this.id,
    this.meterReading,
    this.meterId,
    this.imgPath,
    this.img,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meterReading': meterReading,
      'meterId': meterId,
      'imgPath': imgPath,
      'img': img,
    };
  }
}
