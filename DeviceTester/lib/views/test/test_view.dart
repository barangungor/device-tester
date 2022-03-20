import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:devicetester/models/test/test_model.dart';

class TestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final testModel = Provider.of<TestModel>(context);
    testModel.scHeight = MediaQuery.of(context).size.height;
    testModel.scWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Test'),
        actions: [
          if (testModel.status == TestModelStatus.Started)
            Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: CircularProgressIndicator(color: Colors.white)),
          IconButton(
              onPressed: () {
                if (testModel.status == TestModelStatus.Started) {
                  testModel.stopTest();
                } else {
                  testModel.startTest();
                }
              },
              icon: Icon(testModel.status == TestModelStatus.Started
                  ? Icons.stop
                  : Icons.play_arrow))
        ],
      ),
      body: Column(
        children: [
          buildDeviceInfoCard(testModel),
          Expanded(
            child: buildTestSteps(testModel),
          )
        ],
      ),
    );
  }

  Stepper buildTestSteps(TestModel testModel) {
    return Stepper(
        controlsBuilder: (context, details) {
          return Row(children: []);
        },
        onStepTapped: (value) => testModel.changeTestStep(value),
        onStepCancel: () => testModel.changeTestStep(
            testModel.currentTestStep! > 0
                ? (testModel.currentTestStep! - 1)
                : 0),
        onStepContinue: () => testModel.changeTestStep(
            testModel.currentTestStep! + 1 > testModel.testTypes.length - 1
                ? testModel.testTypes.length - 1
                : testModel.currentTestStep! + 1),
        currentStep: testModel.currentTestStep!,
        steps: testModel.testTypes
            .map((e) => Step(
                  title: Text(e.name!),
                  content: Row(
                    children: [
                      e.content ?? Flexible(child: Text(e.message.toString())),
                    ],
                  ),
                  isActive: testModel.currentTestStep == e.id,
                  state: e.status == null
                      ? StepState.editing
                      : (e.status == false
                          ? StepState.error
                          : StepState.complete),
                ))
            .toList());
  }

  Card buildDeviceInfoCard(TestModel testModel) {
    return Card(
        child: ListTile(
            title: Text('Cihaz Bilgileri'),
            subtitle: Column(
              children: [
                Row(
                  children: [
                    Text('Marka: '),
                    Text(testModel.deviceDetails != null
                        ? testModel.deviceDetails!.brand ?? 'Yükleniyor...'
                        : 'Yükleniyor...'),
                  ],
                ),
                Row(
                  children: [
                    Text('Model: '),
                    Text(testModel.deviceDetails != null
                        ? testModel.deviceDetails!.model ?? 'Yükleniyor...'
                        : 'Yükleniyor...')
                  ],
                ),
                Row(
                  children: [
                    Text('Hafıza: '),
                    Text(testModel.deviceDetails != null
                        ? testModel.deviceDetails!.storage ?? 'Yükleniyor...'
                        : 'Yükleniyor...')
                  ],
                ),
              ],
            )));
  }
}
