import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as image_process;
import 'package:meter_reading_app/base_widget/base_app_bar.dart';
import 'package:meter_reading_app/base_widget/base_image_view.dart';
import 'package:meter_reading_app/base_widget/base_scaffold.dart';
import 'package:meter_reading_app/core/app_color.dart';
import 'package:meter_reading_app/core/camera/base_camera.dart';
import 'package:meter_reading_app/core/loader/loader_controller.dart';
import 'package:meter_reading_app/core/widget/base_consumer_state.dart';
import 'package:meter_reading_app/feature/main/page/main_page.dart';
import 'package:meter_reading_app/feature/scan_meter/controller/image_processing_controller.dart';
import 'package:meter_reading_app/feature/scan_meter/page/preview_image_page.dart';
import 'package:meter_reading_app/generated/assets.gen.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraScanPage extends ConsumerStatefulWidget {
  static const routeName = "CameraScanPage";

  const CameraScanPage({super.key});

  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends BaseConsumerState<CameraScanPage> {
  late CameraController controller;
  final keyBounding = GlobalKey();
  Directory? tempDir;
  final dateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loaderControllerProvider.notifier).onLoad();
      ref.read(imageProcessingControllerProvider.notifier).onClearState();
      getTemporaryDirectory().then((dir) => tempDir = dir);

      final cameras = ref.watch(cameraProvider);
      controller = CameraController(cameras[0], ResolutionPreset.medium);
      initializeCameraController();
    });
  }

  void initializeCameraController() async {
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (mounted) {
        setState(() {});
      }
      ref.read(loaderControllerProvider.notifier).onDismissLoad();
    } on CameraException catch (e) {
      ref.read(loaderControllerProvider.notifier).onDismissLoad();
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _onListen();

    return BaseScaffold(
      appBar: BaseAppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              MainPage.routeName,
              (route) => false,
            );
          },
          icon: const Icon(
            Icons.home,
            color: Colors.black,
            size: 36.0,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Assets.imgs.imgBtnBack.image(),
            ),
          )
        ],
        bgColor: AppColor.themePrimarySecondColor,
      ),
      bgColor: AppColor.themePrimarySecondColor,
      bodyBuilder: (context, constrained) {
        if (!controller.value.isInitialized) {
          return const SizedBox.shrink();
        }
        final size = MediaQuery.of(context).size.width;

        final cropImgPath = ref.read(imageProcessingControllerProvider
            .select((value) => value.cropImgPath));

        print(cropImgPath);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16).w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24.h,
                ),
                SizedBox(
                  width: size,
                  height: MediaQuery.of(context).size.height /
                      controller.value.aspectRatio,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: SizedBox(
                          width: size,
                          height: MediaQuery.of(context).size.height /
                              controller.value.aspectRatio,
                          child: CameraPreview(
                            controller,
                            child: cameraOverlay(
                              padding: 50,
                              aspectRatio: 1,
                              color: const Color(
                                0x56000000,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 16.h,
                ),
                GestureDetector(
                  onTap: () async {
                    ref
                        .read(imageProcessingControllerProvider.notifier)
                        .onClearState();

                    final result = await onTakePictureButtonPressed();

                    final cropImgPath = ref.watch(
                        imageProcessingControllerProvider
                            .select((value) => value.cropImgPath));

                    if (!context.mounted) return;

                    if (result && cropImgPath != null) {
                      final res = await ref
                          .read(imageProcessingControllerProvider.notifier)
                          .onImageProcessing(File(cropImgPath));

                      if (res) {
                        final errorMsg = ref.watch(
                            imageProcessingControllerProvider
                                .select((value) => value.errorMsg));

                        if (errorMsg != null && errorMsg.isNotEmpty) {
                          Fluttertoast.showToast(
                            msg: errorMsg,
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } else {
                          Navigator.of(context)
                              .pushNamed(PreviewImagePage.routeName);
                        }
                      } else {
                        Fluttertoast.showToast(
                          msg: "ภาพไม่ถูกต้อง",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    } else {
                      Fluttertoast.showToast(
                        msg: "ภาพไม่ถูกต้อง",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24).r,
                    decoration: BoxDecoration(
                      color: AppColor.themeWhiteColor,
                      borderRadius: BorderRadius.circular(150 / 2),
                    ),
                    child: Assets.icons.icCamera.svg(),
                  ),
                ),
                SizedBox(
                  height: 16.h,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget cameraOverlay({
    required double padding,
    required double aspectRatio,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double parentAspectRatio = constraints.maxWidth / constraints.maxHeight;
        double horizontalPadding;
        double verticalPadding;

        if (parentAspectRatio < aspectRatio) {
          horizontalPadding = padding;
          verticalPadding = (constraints.maxHeight -
                  ((constraints.maxWidth - 2 * padding) / aspectRatio)) /
              2;
        } else {
          verticalPadding = padding;
          horizontalPadding = (constraints.maxWidth -
                  ((constraints.maxHeight - 2 * padding) * aspectRatio)) /
              2;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: horizontalPadding + 16,
                color: color,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: horizontalPadding + 16,
                color: color,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(
                    left: horizontalPadding + 16,
                    right: horizontalPadding + 16),
                height: verticalPadding,
                color: color,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(
                  left: horizontalPadding + 16,
                  right: horizontalPadding + 16,
                ),
                height: verticalPadding,
                color: color,
              ),
            ),
            // find widget and height this continer
            Positioned(
              top: verticalPadding,
              left: horizontalPadding + 16,
              right: horizontalPadding + 16,
              bottom: verticalPadding,
              child: Container(
                key: keyBounding,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyan,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<XFile?> takePicture() async {
    ref.read(loaderControllerProvider.notifier).onLoad();

    final CameraController cameraController = controller;
    if (!cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      return null;
    }

    try {
      final file = await cameraController.takePicture();
      ref.read(loaderControllerProvider.notifier).onDismissLoad();
      return file;
    } on CameraException catch (e) {
      ref.read(loaderControllerProvider.notifier).onDismissLoad();
      _showCameraException(e);
      return null;
    }
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  Future<bool> onTakePictureButtonPressed() async {
    final result = await takePicture().then((XFile? file) async {
      if (mounted) {
        if (file != null) {
          final cameraImg = File(file.path);
          final image = image_process.decodeImage(cameraImg.readAsBytesSync());

          if (image == null) {
            // Handle decoding error
            return false;
          }

          // Get overlay dimensions
          final overlaySize = keyBounding.currentContext?.size;

          if (overlaySize == null) {
            // Handle null overlay size
            return false;
          }

          // Get the position of the overlay container within the camera preview
          final RenderBox overlayBox =
              keyBounding.currentContext!.findRenderObject() as RenderBox;
          final overlayPosition = overlayBox.localToGlobal(Offset.zero);

          // Calculate cropping rectangle
          const aspectRatio = 1;
          double croppingWidth, croppingHeight, croppingX, croppingY;

          if (image.width / image.height > aspectRatio) {
            croppingWidth = overlaySize.width;
            croppingHeight = overlaySize.width / aspectRatio;
            croppingX = 0;
            croppingY = (overlaySize.height - croppingHeight);
          } else {
            croppingWidth = overlaySize.height * aspectRatio;
            croppingHeight = overlaySize.height;
            croppingX = (overlaySize.width - croppingWidth);
            croppingY = 0;
          }

          // Adjust cropping position based on overlay container position
          croppingX += overlayPosition.dx;
          croppingY += overlayPosition.dy;

          // Crop image
          final imageCrop = image_process.copyCrop(
            image,
            x: croppingX.toInt() + 32,
            y: croppingY.toInt() - 100,
            width: croppingWidth.toInt(),
            height: croppingHeight.toInt() + 100,
          );

          // Save cropped image
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String appPath = appDir.path;
          final baseName = cameraImg.path.split('/').last;
          final croppedImageFile = File('$appPath/cropped_$baseName');

          croppedImageFile.writeAsBytesSync(image_process.encodeJpg(imageCrop));

          // Set cropped image path
          ref
              .read(imageProcessingControllerProvider.notifier)
              .setCropImgPath(croppedImageFile.path);

          return true;
        }

        return false;
      }
      return false;
    });

    return result;
  }

  void _onListen() {
    ref.listen(imageProcessingControllerProvider.select((value) => value),
        (previous, next) {
      if (next.errorMsg != null && next.errorMsg!.isNotEmpty) {
        Fluttertoast.showToast(
          msg: "${next.errorMsg}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    });
  }
}
