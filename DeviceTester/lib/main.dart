import 'package:devicetester/models/app_constants.dart';
import 'package:devicetester/models/auth/auth_helper.dart';
import 'package:devicetester/models/test/test_model.dart';
import 'package:devicetester/views/login/login_view.dart';
import 'package:devicetester/views/test/test_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => TestModel.instance,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Device Tester',
        theme:
            ThemeData(primarySwatch: MaterialColor(0xff30b500, primarySwatch)),
        home:
            FirebaseAuthHelper.instance.user != null ? TestView() : LoginView(),
      ),
    );
  }
}
