import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:devicetester/models/device.dart';
import 'package:devicetester/models/test_type.dart';
import 'package:disk_space/disk_space.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:sim_info/sim_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

enum TestModelStatus {
  None,
  Started,
  Loading,
  Error,
  Ended,
}

class TestModel extends ChangeNotifier {
  static TestModel? _instance;
  static TestModel get instance {
    _instance ??= TestModel._init();
    return _instance!;
  }

  TestModel._init() {
    getDeviceDetails();
    currentTestStep ??= 0;
  }

  TestModelStatus status = TestModelStatus.None;
  BatteryState? batteryStatus;
  Battery? battery;
  int? batteryLevel, currentTestStep;
  StreamSubscription? batterySubscription;
  Device? deviceDetails;
  LocalAuthentication? auth;
  CameraController? cameraController;
  Connectivity? connectivity;
  var scHeight, scWidth;

  Future stopTest({fromButton}) async {
    status = TestModelStatus.None;
    if (fromButton != null) {
      battery = null;
      batterySubscription = null;
      cameraController = null;
      connectivity = null;
      currentTestStep = 0;
      testTypes.forEach((testType) {
        testType.status = null;
        testType.content = null;
        testType.message = 'Başlamadı';
      });
    }
    notifyListeners();
  }

  List<TestType> testTypes = [
    TestType(
      id: 0,
      name: 'Face ID - Parmak İzi Kontrolü',
      status: null,
      message: 'Başlamadı.',
    ),
    TestType(
        id: 1, name: 'Ön Kamera Kontrolü', status: null, message: 'Başlamadı.'),
    TestType(
        id: 2,
        name: 'Arka Kamera Kontrolü',
        status: null,
        message: 'Başlamadı.'),
    TestType(
        id: 3, name: 'Flash Kontrolü', status: null, message: 'Başlamadı.'),
    TestType(id: 4, name: 'İvme Kontrolü', status: null, message: 'Başlamadı.'),
    TestType(
        id: 5,
        name: 'Titreşim Motoru Kontrolü',
        status: null,
        message: 'Başlamadı.'),
    TestType(
        id: 6,
        name: 'Dokunmatik Ekran Kontrolü',
        status: null,
        message: 'Başlamadı.'),
    TestType(
        id: 7, name: 'Sim Kart Kontrolü', status: null, message: 'Başlamadı.'),
    TestType(
        id: 8, name: 'Wi-Fi Kontrolü', status: null, message: 'Başlamadı.'),
    TestType(
        id: 9,
        name: 'Şarj Soketi Kontrolü',
        status: null,
        message: 'Başlamadı.'),
  ];

  Future changeTestStatus(id, status,
      {extramessage = '', changeAfter, lastStep}) async {
    switch (status) {
      case null:
        testTypes[id].status = null;
        testTypes[id].message = 'Başlamadı.' + extramessage;
        break;
      case true:
        testTypes[id].status = true;
        testTypes[id].message = 'Başarılı.' + extramessage;
        break;
      case false:
        testTypes[id].status = false;
        testTypes[id].message = 'Başarısız.' + extramessage;
        break;
      default:
    }
    if (changeAfter == null && lastStep == null) await changeTestStep(id + 1);
    return;
  }

  Future changeTestStep(int step) async {
    currentTestStep = step;
    notifyListeners();
    return;
  }

  Future startTest() async {
    status = TestModelStatus.Started;
    currentTestStep = 0;
    testTypes.forEach((element) {
      element.status = null;
      element.message = 'Başlamadı.';
    });
    await checkDeviceAuth().then((value) async {
      await checkDeviceCamera(true);
    });
    notifyListeners();
  }

  Future continueTestAfterCams() async {
    if (status == TestModelStatus.Started)
      await checkFlashLight().then((value) async {
        Future.delayed(Duration(seconds: 1), () async {
          await checkAccelerometerSensor().then((value) async {
            Future.delayed(Duration(seconds: 1), () async {
              await checkVibrationSensor().then((value) async {
                Future.delayed(Duration(seconds: 1), () async {
                  await checkTouchScreen().then((value) async {
                    Future.delayed(Duration(seconds: 1), () async {
                      await checkSimCard().then((value) async {
                        Future.delayed(Duration(seconds: 1), () async {
                          await checkWifi().then((value) async {
                            Future.delayed(Duration(seconds: 1), () async {
                              checkSocket().then((value) async {
                                Future.delayed(Duration(seconds: 1), () async {
                                  await stopTest();
                                });
                              });
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
  }

  Future checkDeviceAuth() async {
    auth ??= LocalAuthentication();
    await changeTestStatus(currentTestStep!, await auth!.canCheckBiometrics);
    return;
  }

  Future<bool?> checkDeviceCamera(forFrontCam) async {
    var camPermission = await Permission.camera;
    if (await camPermission.status == PermissionStatus.granted) {
      final cameras = await availableCameras();
      cameraController = CameraController(
          cameras
              .where((element) =>
                  element.lensDirection ==
                  (forFrontCam == true
                      ? CameraLensDirection.front
                      : CameraLensDirection.back))
              .first,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.yuv420);
      await cameraController?.initialize();
      testTypes[currentTestStep!].content = Column(
        children: [
          cameraController?.value.isInitialized == false
              ? Text('Kamera başlatılamadı.')
              : SizedBox(
                  height: scWidth * 0.3,
                  width: scWidth * 0.3,
                  child: AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!))),
          if (cameraController?.value.isInitialized == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                    onPressed: () async {
                      testTypes[currentTestStep!].content = null;
                      await changeTestStatus(currentTestStep!, true,
                          extramessage: 'Kamera başarıyla başlatıldı.');
                      cameraController!.dispose();
                      cameraController = null;
                      if (forFrontCam) {
                        checkDeviceCamera(false);
                      } else {
                        continueTestAfterCams();
                      }
                    },
                    child: Text('Kamera Açıldı')),
                TextButton(
                    onPressed: () async {
                      testTypes[currentTestStep!].content = null;
                      await changeTestStatus(currentTestStep!, false,
                          extramessage: 'Kamera açılmadı.');
                      cameraController!.dispose();
                      cameraController = null;
                      if (forFrontCam) {
                        checkDeviceCamera(false);
                      } else {
                        continueTestAfterCams();
                      }
                    },
                    child: Text('Kamera Açılmadı')),
              ],
            )
        ],
      );
    } else {
      await camPermission.request().then((value) {
        if (value == PermissionStatus.granted) {
          checkDeviceCamera(forFrontCam);
        } else {
          changeTestStatus(currentTestStep!, false,
              extramessage: 'Kamera izni verilmedi.');
        }
      });
    }

    notifyListeners();
  }

  Future checkFlashLight() async {
    bool isAvailable = await TorchLight.isTorchAvailable();
    if (isAvailable) {
      try {
        await TorchLight.enableTorch();
        await changeTestStatus(currentTestStep, true,
            extramessage: 'Flash açıldı.', changeAfter: true);
      } on EnableTorchExistentUserException catch (e) {
        await changeTestStatus(currentTestStep, false,
            extramessage: 'Kamera kullanımda olduğundan Flash açılamadı.');
      } on EnableTorchNotAvailableException catch (e) {
        await changeTestStatus(currentTestStep, false,
            extramessage: 'Flash motoru bulunamadığından Flash açılamadı.');
      } on EnableTorchException catch (e) {
        await changeTestStatus(currentTestStep, false,
            extramessage: 'Flash açılamadı.');
      }
      if (testTypes[currentTestStep!].status == true)
        try {
          await Future.delayed(Duration(milliseconds: 1200), () async {
            await TorchLight.disableTorch();
            await changeTestStatus(currentTestStep, true,
                extramessage: 'Flash açıldı ve kapatıldı.');
          });
        } on DisableTorchExistentUserException catch (e) {
          await changeTestStatus(currentTestStep, false,
              extramessage: 'Kamera kullanımda olduğundan Flash kapatılamadı.');
        } on DisableTorchNotAvailableException catch (e) {
          await changeTestStatus(currentTestStep, false,
              extramessage:
                  'Flash motoru bulunamadığından Flash kapatılamadı.');
        } on DisableTorchException catch (e) {
          await changeTestStatus(currentTestStep, false,
              extramessage: 'Flash kapatılamadı.');
        }
    } else {
      await changeTestStatus(currentTestStep, false,
          extramessage: 'Flash motoru bulunamadı.');
    }
    return;
  }

  Future checkAccelerometerSensor() async {
    StreamSubscription? subscription;
    subscription = accelerometerEvents.listen((event) {});
    subscription.onData((event) async {
      await changeTestStatus(currentTestStep!, true,
          extramessage: 'İvme algılandı.');
      subscription!.cancel();
      return;
    });
  }

  Future checkVibrationSensor() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate();
      await changeTestStatus(currentTestStep!, true,
          extramessage: 'Titreşim yapıldı.');
    } else {
      await changeTestStatus(currentTestStep!, false,
          extramessage: 'Titreşim motoru bulunamadı.');
    }
    return;
  }

  Future checkTouchScreen() async {
    await changeTestStatus(currentTestStep!, await auth!.canCheckBiometrics);
    return;
  }

  Future checkSimCard() async {
    var result = await SimInfo.getSIMState;
    if (Platform.isAndroid) {
      await changeTestStatus(currentTestStep!, result,
          extramessage: result == true
              ? 'Sim kartı kontrol edildi.'
              : 'Sim kartı bulunamadı.');
    } else {
      await changeTestStatus(currentTestStep!, result != "nil" ? true : false);
    }
    return;
  }

  Future checkWifi() async {
    await WiFiForIoTPlugin.isEnabled().then((isEnabled) async {
      await WiFiForIoTPlugin.isConnected().then((isConnected) async {
        if (isEnabled) {
          if (isConnected) {
            await changeTestStatus(currentTestStep!, true,
                extramessage: 'Wifi açık ve bağlı.');
          } else {
            await changeTestStatus(currentTestStep!, true,
                extramessage: 'Wifi açık ancak bağlı değil.');
          }
        } else {
          await changeTestStatus(currentTestStep!, false,
              extramessage: 'Wifi açık ve bağlı değil.');
        }
      });
    });
    return;
  }

  Future checkSocket() async {
    if (batterySubscription != null) await stopListenTheBatteryStatus();
    battery ??= Battery();
    batteryStatus = await battery!.batteryState;
    batteryLevel = await battery!.batteryLevel;
    testTypes[currentTestStep!].message = 'Cihazınızı şarja takınız';
    batterySubscription = battery!.onBatteryStateChanged.listen((status) async {
      batteryStatus = status;
      if (batteryStatus == BatteryState.charging ||
          batteryStatus == BatteryState.full) {
        await changeTestStatus(currentTestStep!, true,
            extramessage: 'Şarj soketi kontrol edildi.', lastStep: true);
        await stopListenTheBatteryStatus();
        return;
      }
      batteryLevel = await battery!.batteryLevel;
    });
  }

  getDeviceDetails() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      await DiskSpace.getTotalDiskSpace.then((value) => deviceDetails = Device(
            brand: androidInfo.brand ?? 'Bilinmiyor',
            model: androidInfo.model ?? 'Bilinmiyor',
            storage:
                value != null ? value.toStringAsFixed(2) + ' mb' : 'Bilinmiyor',
          ));
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      await DiskSpace.getTotalDiskSpace.then((value) => deviceDetails = Device(
            brand: 'Apple',
            model: iosInfo.model ?? 'Bilinmiyor',
            storage:
                value != null ? value.toStringAsFixed(2) + ' mb' : 'Bilinmiyor',
          ));
    }
    notifyListeners();
  }

  Future stopListenTheBatteryStatus() async {
    await batterySubscription?.cancel();
    batterySubscription = null;
    return;
  }
}
